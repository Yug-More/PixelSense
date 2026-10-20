import Foundation

enum AdjustmentControl: String, Equatable {
    case exposure
    case contrast
    case saturation
    case warmth

    var limit: Double {
        switch self {
        case .exposure: return EditRecipe.exposureRange.upperBound
        case .contrast: return EditRecipe.contrastRange.upperBound
        case .saturation: return EditRecipe.saturationRange.upperBound
        case .warmth: return EditRecipe.warmthRange.upperBound
        }
    }

    var displayName: String { rawValue }
}

enum PromptFailure: Equatable, Error {
    case empty
    case conflict(AdjustmentControl)
    case conflictingModifiers
    case unsupported

    var message: String {
        switch self {
        case .empty:
            return "Enter an instruction, such as “Make this photo warmer.”"
        case .conflict(let control):
            return "Those instructions conflict for \(control.displayName). Nothing was changed."
        case .conflictingModifiers:
            return "Use one strength at a time, such as slightly or a lot. Nothing was changed."
        case .unsupported:
            return "PixelSense only changes exposure, contrast, saturation, and warmth."
        }
    }
}

/// Turns a supported sentence into recipe values.
///
/// A mentioned control is replaced with an absolute value measured from neutral.
/// Controls the sentence does not mention stay at their current values.
/// A conflict or unsupported phrase returns an error and does not produce a recipe.
enum PromptInterpreter {
    static func interpret(_ text: String, current: EditRecipe = EditRecipe()) -> Result<EditRecipe, PromptFailure> {
        let normalized = normalize(text)
        if normalized.isEmpty {
            return .failure(.empty)
        }
        if containsBlockedWord(normalized) {
            return .failure(.unsupported)
        }

        let matches = instructionMatches(in: normalized)
        if matches.isEmpty {
            return .failure(.unsupported)
        }

        let clauses = clauseRanges(in: normalized)
        var operations: [Operation] = []
        for match in matches {
            guard let intensity = intensity(in: clause(containing: match.range, clauses: clauses), of: normalized) else {
                return .failure(.conflictingModifiers)
            }
            for (control, direction) in match.operations {
                operations.append(Operation(control: control, direction: direction, intensity: intensity, range: match.range))
            }
        }

        let inherited = inheritedOperations(in: normalized, matches: matches, clauses: clauses)
        switch inherited {
        case .failure(let failure):
            return .failure(failure)
        case .success(let extra):
            operations.append(contentsOf: extra)
        }

        if let failure = leftoverWords(in: normalized, matches: matches, inherited: operations) {
            return .failure(failure)
        }

        guard let assignments = assign(operations) else {
            return .failure(.conflict(conflictingControl(in: operations) ?? .exposure))
        }

        var updated = current
        for (control, value) in assignments {
            updated.set(control, to: value)
        }
        updated = updated.clamped()
        guard updated.isWithinLimits else {
            return .failure(.unsupported)
        }
        return .success(updated)
    }

    /// Lowercases text and turns punctuation into single spaces.
    static func normalize(_ text: String) -> String {
        let letters = text.lowercased().unicodeScalars.map { scalar -> Character in
            if CharacterSet.lowercaseLetters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                return Character(scalar)
            }
            return " "
        }
        return String(letters).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private struct Operation {
        var control: AdjustmentControl
        var direction: AdjustmentDirection
        var intensity: PromptIntensity
        var range: Range<String.Index>
    }

    private struct InstructionMatch {
        var range: Range<String.Index>
        var operations: [(AdjustmentControl, AdjustmentDirection)]
    }

    private static func assign(_ operations: [Operation]) -> [AdjustmentControl: Double]? {
        var chosen: [AdjustmentControl: Operation] = [:]
        for operation in operations {
            if let existing = chosen[operation.control] {
                if existing.direction != operation.direction {
                    return nil
                }
                if operation.intensity > existing.intensity {
                    chosen[operation.control] = operation
                }
            } else {
                chosen[operation.control] = operation
            }
        }
        return chosen.mapValues { $0.direction.sign * $0.control.limit * $0.intensity.fraction }
    }

    private static func conflictingControl(in operations: [Operation]) -> AdjustmentControl? {
        var seen: [AdjustmentControl: AdjustmentDirection] = [:]
        for operation in operations {
            if let direction = seen[operation.control], direction != operation.direction {
                return operation.control
            }
            seen[operation.control] = operation.direction
        }
        return nil
    }

    private static func containsBlockedWord(_ text: String) -> Bool {
        let blocked = [
            "remove", "delete", "erase", "replace", "swap", "blur", "generate", "generated",
            "cinematic", "movie", "movies", "crop", "rotate", "person", "people", "sky",
            "background", "subject", "foreground", "bokeh", "vignette", "object", "objects"
        ]
        return blocked.contains { text.range(of: "\\b\($0)\\b", options: .regularExpression) != nil }
    }

    private static func instructionMatches(in text: String) -> [InstructionMatch] {
        var candidates: [InstructionMatch] = []
        for rule in rules {
            for match in rule.expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range, in: text) else { continue }
                let operations = rule.resolve(match, text)
                if operations.isEmpty { continue }
                candidates.append(InstructionMatch(range: range, operations: operations))
            }
        }
        candidates.sort { lhs, rhs in
            let left = text.distance(from: lhs.range.lowerBound, to: lhs.range.upperBound)
            let right = text.distance(from: rhs.range.lowerBound, to: rhs.range.upperBound)
            if left != right { return left > right }
            return lhs.range.lowerBound < rhs.range.lowerBound
        }
        var chosen: [InstructionMatch] = []
        for candidate in candidates {
            if chosen.contains(where: { $0.range.overlaps(candidate.range) }) { continue }
            chosen.append(candidate)
        }
        return chosen.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private static func inheritedOperations(
        in text: String,
        matches: [InstructionMatch],
        clauses: [Range<String.Index>]
    ) -> Result<[Operation], PromptFailure> {
        guard let expression = try? NSRegularExpression(
            pattern: #"\b(exposure|brightness|contrast|saturation|vibrance|warmth)\b"#
        ) else {
            return .success([])
        }
        var extra: [Operation] = []
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text),
                  !matches.contains(where: { $0.range.overlaps(range) }),
                  let word = substring(match, group: 1, in: text),
                  let control = AdjustmentControl(noun: word),
                  let previous = matches.last(where: { $0.range.upperBound <= range.lowerBound }),
                  let direction = singleDirection(in: previous.operations) else {
                continue
            }
            guard let intensity = intensity(in: clause(containing: previous.range, clauses: clauses), of: text) else {
                return .failure(.conflictingModifiers)
            }
            extra.append(Operation(control: control, direction: direction, intensity: intensity, range: range))
        }
        return .success(extra)
    }

    private static func singleDirection(in operations: [(AdjustmentControl, AdjustmentDirection)]) -> AdjustmentDirection? {
        let directions = Set(operations.map(\.1))
        guard directions.count == 1, let direction = directions.first else { return nil }
        return direction
    }

    private static func leftoverWords(
        in text: String,
        matches: [InstructionMatch],
        inherited: [Operation]
    ) -> PromptFailure? {
        var characters = Array(text)
        for range in matches.map(\.range) + inherited.map(\.range) + modifierRanges(in: text) {
            let start = text.distance(from: text.startIndex, to: range.lowerBound)
            let end = text.distance(from: text.startIndex, to: range.upperBound)
            guard start >= 0, end <= characters.count else { continue }
            for index in start..<end {
                characters[index] = " "
            }
        }
        let leftovers = String(characters)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !fillerWords.contains($0) }
        return leftovers.isEmpty ? nil : .unsupported
    }

    private static func intensity(in clause: Range<String.Index>, of text: String) -> PromptIntensity? {
        let fragment = String(text[clause])
        var level: PromptIntensity?
        for (range, intensity) in modifierHits(in: fragment) {
            _ = range
            if let level, level != intensity {
                return nil
            }
            level = intensity
        }
        return level ?? .standard
    }

    private static func modifierRanges(in text: String) -> [Range<String.Index>] {
        modifierHits(in: text).map(\.0)
    }

    private static func modifierHits(in text: String) -> [(Range<String.Index>, PromptIntensity)] {
        var hits: [(Range<String.Index>, PromptIntensity)] = []
        for (phrase, intensity) in modifierPhrases.sorted(by: { $0.phrase.count > $1.phrase.count }) {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\b"
            guard let expression = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range, in: text) else { continue }
                if hits.contains(where: { $0.0.overlaps(range) }) { continue }
                hits.append((range, intensity))
            }
        }
        return hits
    }

    private static func clauseRanges(in text: String) -> [Range<String.Index>] {
        let separator = " and "
        var ranges: [Range<String.Index>] = []
        var start = text.startIndex
        while let found = text.range(of: separator, range: start..<text.endIndex) {
            ranges.append(start..<found.lowerBound)
            start = found.upperBound
        }
        ranges.append(start..<text.endIndex)
        return ranges
    }

    private static func clause(containing range: Range<String.Index>, clauses: [Range<String.Index>]) -> Range<String.Index> {
        clauses.first { $0.contains(range.lowerBound) } ?? (range.lowerBound..<range.upperBound)
    }

    private static func substring(_ match: NSTextCheckingResult, group: Int, in text: String) -> String? {
        let range = match.range(at: group)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return nil }
        return String(text[swiftRange])
    }

    private static let fillerWords: Set<String> = [
        "a", "an", "the", "this", "that", "these", "photo", "photos", "image", "images",
        "picture", "pictures", "it", "its", "make", "makes", "made", "please", "to", "of",
        "my", "look", "looks", "just", "and", "then", "also", "with", "some", "be", "is",
        "for", "me", "in", "on"
    ]

    private static let modifierPhrases: [(phrase: String, intensity: PromptIntensity)] = [
        ("a little bit", .slight),
        ("a little", .slight),
        ("a bit", .slight),
        ("slightly", .slight),
        ("a lot", .strong),
        ("significantly", .strong),
        ("strongly", .strong),
        ("much", .strong)
    ]

    private struct Rule {
        var expression: NSRegularExpression
        var resolve: (NSTextCheckingResult, String) -> [(AdjustmentControl, AdjustmentDirection)]
    }

    private static let rules: [Rule] = {
        var built: [Rule] = simplePatterns.map { pattern, control, direction in
            Rule(expression: regex(pattern)) { _, _ in [(control, direction)] }
        }
        built.append(Rule(expression: regex(
            #"\b(increase|decrease|reduce|lower|add|raise|boost)\s+and\s+(increase|decrease|reduce|lower|add|raise|boost)\s+(?:the\s+)?(exposure|brightness|contrast|saturation|vibrance|warmth)\b"#
        )) { match, text in
            guard let first = substring(match, group: 1, in: text),
                  let second = substring(match, group: 2, in: text),
                  let noun = substring(match, group: 3, in: text),
                  let control = AdjustmentControl(noun: noun) else {
                return []
            }
            return [
                (control, AdjustmentDirection(verb: first)),
                (control, AdjustmentDirection(verb: second))
            ]
        })
        return built
    }()

    private static let simplePatterns: [(String, AdjustmentControl, AdjustmentDirection)] = [
        (#"\badd\s+more\s+(exposure|brightness)\b"#, .exposure, .increase),
        (#"\b(increase|raise|add|boost)\s+(?:the\s+)?(exposure|brightness)\b"#, .exposure, .increase),
        (#"\bmore\s+(exposure|brightness)\b"#, .exposure, .increase),
        (#"\b(brighten|brighter|lighten)\b"#, .exposure, .increase),
        (#"\b(decrease|reduce|lower)\s+(?:the\s+)?(exposure|brightness)\b"#, .exposure, .decrease),
        (#"\bless\s+(exposure|brightness)\b"#, .exposure, .decrease),
        (#"\b(darken|darker)\b"#, .exposure, .decrease),

        (#"\badd\s+more\s+warmth\b"#, .warmth, .increase),
        (#"\b(increase|raise|add|boost)\s+(?:the\s+)?warmth\b"#, .warmth, .increase),
        (#"\bmore\s+warmth\b"#, .warmth, .increase),
        (#"\bwarm\s+up\b"#, .warmth, .increase),
        (#"\bwarmer\b"#, .warmth, .increase),
        (#"\bwarm\b"#, .warmth, .increase),
        (#"\b(decrease|reduce|lower)\s+(?:the\s+)?warmth\b"#, .warmth, .decrease),
        (#"\bless\s+warmth\b"#, .warmth, .decrease),
        (#"\bcool\s+down\b"#, .warmth, .decrease),
        (#"\bcooler\b"#, .warmth, .decrease),
        (#"\bcool\b"#, .warmth, .decrease),

        (#"\badd\s+more\s+contrast\b"#, .contrast, .increase),
        (#"\b(increase|raise|add|boost)\s+(?:the\s+)?contrast\b"#, .contrast, .increase),
        (#"\bmore\s+contrast(?:y)?\b"#, .contrast, .increase),
        (#"\b(decrease|reduce|lower)\s+(?:the\s+)?contrast\b"#, .contrast, .decrease),
        (#"\bless\s+contrast(?:y)?\b"#, .contrast, .decrease),

        (#"\badd\s+more\s+(saturation|vibrance)\b"#, .saturation, .increase),
        (#"\b(increase|raise|add|boost)\s+(?:the\s+)?(saturation|vibrance)\b"#, .saturation, .increase),
        (#"\bmore\s+(saturation|vibrance)\b"#, .saturation, .increase),
        (#"\bmore\s+(?:colorful|vibrant)\b"#, .saturation, .increase),
        (#"\b(?:make\s+)?(?:the\s+)?colors\s+(?:more\s+)?(?:stronger|vibrant|colorful)\b"#, .saturation, .increase),
        (#"\b(?:stronger|vibrant|colorful)\s+colors\b"#, .saturation, .increase),
        (#"\bvibrant\b"#, .saturation, .increase),
        (#"\b(decrease|reduce|lower)\s+(?:the\s+)?(saturation|vibrance)\b"#, .saturation, .decrease),
        (#"\bless\s+(saturation|vibrance)\b"#, .saturation, .decrease),
        (#"\bless\s+(?:colorful|vibrant)\b"#, .saturation, .decrease),
        (#"\bdesaturate\b"#, .saturation, .decrease)
    ]

    private static func regex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid prompt pattern \(pattern): \(error)")
        }
    }
}

private enum AdjustmentDirection: Equatable {
    case increase
    case decrease

    init(verb: String) {
        switch verb {
        case "decrease", "reduce", "lower":
            self = .decrease
        default:
            self = .increase
        }
    }

    var sign: Double {
        switch self {
        case .increase: return 1
        case .decrease: return -1
        }
    }
}

private enum PromptIntensity: Int, Comparable {
    case slight = 0
    case standard = 1
    case strong = 2

    static func < (lhs: PromptIntensity, rhs: PromptIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var fraction: Double {
        switch self {
        case .slight: return 0.25
        case .standard: return 0.5
        case .strong: return 1
        }
    }
}

private extension AdjustmentControl {
    init?(noun: String) {
        switch noun {
        case "exposure", "brightness": self = .exposure
        case "contrast": self = .contrast
        case "saturation", "vibrance": self = .saturation
        case "warmth": self = .warmth
        default: return nil
        }
    }
}

private extension EditRecipe {
    mutating func set(_ control: AdjustmentControl, to value: Double) {
        switch control {
        case .exposure: exposureEV = value
        case .contrast: contrast = value
        case .saturation: saturation = value
        case .warmth: warmth = value
        }
    }
}

/// Applies a prompt to recipe values without saving a photo.
struct PromptApplication: Equatable {
    var recipe: EditRecipe
    var errorMessage: String?

    init(recipe: EditRecipe, errorMessage: String? = nil) {
        self.recipe = recipe
        self.errorMessage = errorMessage
    }

    mutating func apply(_ text: String) {
        switch PromptInterpreter.interpret(text, current: recipe) {
        case .success(let updated):
            recipe = updated
            errorMessage = nil
        case .failure(let failure):
            errorMessage = failure.message
        }
    }

    mutating func reset() {
        recipe = EditRecipe()
        errorMessage = nil
    }
}
