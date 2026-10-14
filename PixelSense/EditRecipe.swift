import Foundation

struct EditRecipe: Codable, Equatable {
    static let formatIdentifier = "edu.sjsu.pixelsense.recipe"
    static let formatVersion = "1"

    static let exposureRange: ClosedRange<Double> = -2...2
    static let contrastRange: ClosedRange<Double> = -0.5...0.5
    static let saturationRange: ClosedRange<Double> = -1...1
    static let warmthRange: ClosedRange<Double> = -1...1

    var exposureEV: Double = 0
    var contrast: Double = 0
    var saturation: Double = 0
    var warmth: Double = 0

    private enum CodingKeys: String, CodingKey {
        case exposureEV, contrast, saturation, warmth
    }

    init(exposureEV: Double = 0, contrast: Double = 0, saturation: Double = 0, warmth: Double = 0) {
        self.exposureEV = exposureEV
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        exposureEV = Self.clamp(try values.decodeIfPresent(Double.self, forKey: .exposureEV) ?? 0, to: Self.exposureRange)
        contrast = Self.clamp(try values.decodeIfPresent(Double.self, forKey: .contrast) ?? 0, to: Self.contrastRange)
        saturation = Self.clamp(try values.decodeIfPresent(Double.self, forKey: .saturation) ?? 0, to: Self.saturationRange)
        warmth = Self.clamp(try values.decodeIfPresent(Double.self, forKey: .warmth) ?? 0, to: Self.warmthRange)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exposureEV, forKey: .exposureEV)
        try container.encode(contrast, forKey: .contrast)
        try container.encode(saturation, forKey: .saturation)
        try container.encode(warmth, forKey: .warmth)
    }

    /// Finite values outside a control's range are pulled back to that range.
    /// Non-finite values become neutral so a bad number cannot reach the renderer.
    func clamped() -> EditRecipe {
        EditRecipe(
            exposureEV: Self.clamp(exposureEV, to: Self.exposureRange),
            contrast: Self.clamp(contrast, to: Self.contrastRange),
            saturation: Self.clamp(saturation, to: Self.saturationRange),
            warmth: Self.clamp(warmth, to: Self.warmthRange)
        )
    }

    var isWithinLimits: Bool {
        Self.isWithin(exposureEV, Self.exposureRange)
            && Self.isWithin(contrast, Self.contrastRange)
            && Self.isWithin(saturation, Self.saturationRange)
            && Self.isWithin(warmth, Self.warmthRange)
    }

    static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    private static func isWithin(_ value: Double, _ range: ClosedRange<Double>) -> Bool {
        value.isFinite && range.contains(value)
    }
}
