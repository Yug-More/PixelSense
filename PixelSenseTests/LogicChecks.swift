import Foundation
#if !LOGIC_TEST_RUNNER
@testable import PixelSense
#endif

struct LogicCheck {
    var name: String
    var run: () -> String?
}

enum PromptLogicChecks {
    static let all: [LogicCheck] = [
        LogicCheck(name: "brightness increase", run: brightnessIncrease),
        LogicCheck(name: "brightness decrease", run: brightnessDecrease),
        LogicCheck(name: "warmth increase", run: warmthIncrease),
        LogicCheck(name: "warmth decrease", run: warmthDecrease),
        LogicCheck(name: "contrast increase", run: contrastIncrease),
        LogicCheck(name: "contrast decrease", run: contrastDecrease),
        LogicCheck(name: "saturation increase", run: saturationIncrease),
        LogicCheck(name: "saturation decrease", run: saturationDecrease),
        LogicCheck(name: "slight intensity", run: slightIntensity),
        LogicCheck(name: "default intensity", run: defaultIntensity),
        LogicCheck(name: "strong intensity", run: strongIntensity),
        LogicCheck(name: "multiple controls", run: multipleControls),
        LogicCheck(name: "contradictory instructions", run: contradictoryInstructions),
        LogicCheck(name: "repeated instructions", run: repeatedInstructions),
        LogicCheck(name: "empty prompt", run: emptyPrompt),
        LogicCheck(name: "unsupported instruction", run: unsupportedInstruction),
        LogicCheck(name: "mixed supported and unsupported", run: mixedSupportedAndUnsupported),
        LogicCheck(name: "case insensitive", run: caseInsensitive),
        LogicCheck(name: "whitespace and punctuation", run: whitespaceAndPunctuation),
        LogicCheck(name: "unmentioned controls stay", run: unmentionedControlsStay),
        LogicCheck(name: "failure leaves recipe unchanged", run: failureLeavesRecipeUnchanged),
        LogicCheck(name: "apply does not save", run: applyDoesNotSave),
        LogicCheck(name: "default recipe", run: defaultRecipe),
        LogicCheck(name: "neutral reset", run: neutralReset),
        LogicCheck(name: "limits", run: limits),
        LogicCheck(name: "out of range clamps", run: outOfRangeClamps),
        LogicCheck(name: "non finite clamps to neutral", run: nonFiniteClampsToNeutral),
        LogicCheck(name: "json round trip", run: jsonRoundTrip),
        LogicCheck(name: "json missing keys", run: jsonMissingKeys),
        LogicCheck(name: "json rejects wrong type", run: jsonRejectsWrongType),
        LogicCheck(name: "version constants", run: versionConstants),
        LogicCheck(name: "spec demo prompts", run: specDemoPrompts),
        LogicCheck(name: "vibrance synonyms", run: vibranceSynonyms),
        LogicCheck(name: "warm up and cool down", run: warmUpAndCoolDown),
        LogicCheck(name: "sprint example prompts", run: sprintExamplePrompts),
        LogicCheck(name: "boost synonyms", run: boostSynonyms)
    ]

    static func brightnessIncrease() -> String? {
        expect(.success(exposure: 1), from: "Make the image brighter")
            ?? expect(.success(exposure: 1), from: "Increase exposure")
            ?? expect(.success(exposure: 1), from: "Brighten the photo")
    }

    static func brightnessDecrease() -> String? {
        expect(.success(exposure: -1), from: "Make it darker")
            ?? expect(.success(exposure: -1), from: "Reduce exposure")
    }

    static func warmthIncrease() -> String? {
        expect(.success(warmth: 0.5), from: "Make it warmer")
            ?? expect(.success(warmth: 0.5), from: "Add warmth")
            ?? expect(.success(warmth: 0.5), from: "Increase warmth")
    }

    static func warmthDecrease() -> String? {
        expect(.success(warmth: -0.5), from: "Make it cooler")
            ?? expect(.success(warmth: -0.5), from: "Reduce warmth")
    }

    static func contrastIncrease() -> String? {
        expect(.success(contrast: 0.25), from: "Increase contrast")
            ?? expect(.success(contrast: 0.25), from: "Add more contrast")
    }

    static func contrastDecrease() -> String? {
        expect(.success(contrast: -0.25), from: "Reduce contrast")
            ?? expect(.success(contrast: -0.25), from: "Make it less contrasty")
    }

    static func saturationIncrease() -> String? {
        expect(.success(saturation: 0.5), from: "Increase saturation")
            ?? expect(.success(saturation: 0.5), from: "Make it more colorful")
            ?? expect(.success(saturation: 0.5), from: "Make colors stronger")
    }

    static func saturationDecrease() -> String? {
        expect(.success(saturation: -0.5), from: "Reduce saturation")
            ?? expect(.success(saturation: -0.5), from: "Make it less colorful")
            ?? expect(.success(saturation: -0.5), from: "Desaturate the photo")
    }

    static func slightIntensity() -> String? {
        expect(.success(exposure: 0.5), from: "Increase brightness slightly.")
            ?? expect(.success(warmth: 0.25), from: "Make this photo a little warmer")
            ?? expect(.success(saturation: -0.25), from: "Reduce saturation a bit")
    }

    static func defaultIntensity() -> String? {
        expect(.success(warmth: 0.5), from: "Make this photo warmer.")
    }

    static func strongIntensity() -> String? {
        expect(.success(warmth: 1), from: "Make it much warmer")
            ?? expect(.success(contrast: 0.5), from: "Strongly increase contrast")
            ?? expect(.success(saturation: -1), from: "Reduce saturation a lot")
            ?? expect(.success(exposure: 2), from: "Significantly increase brightness")
    }

    static func multipleControls() -> String? {
        expect(.success(contrast: 0.25, warmth: -0.5), from: "Make the photo cooler and increase contrast.")
            ?? expect(.success(contrast: 0.25, warmth: 0.25), from: "Make the photo slightly warmer and increase contrast.")
            ?? expect(.success(contrast: 0.25, saturation: 0.5), from: "Increase contrast and saturation")
            ?? expect(.success(contrast: -0.125, saturation: -0.25), from: "Slightly reduce saturation and contrast")
    }

    static func contradictoryInstructions() -> String? {
        expect(.conflict(.warmth), from: "Make it warmer and cooler.")
            ?? expect(.conflict(.saturation), from: "Increase and decrease saturation.")
            ?? expect(.conflict(.exposure), from: "Make the image brighter and darker.")
    }

    static func repeatedInstructions() -> String? {
        expect(.success(warmth: 1), from: "Make it slightly warmer and much warmer")
            ?? expect(.success(contrast: 0.25), from: "Increase contrast and add more contrast")
    }

    static func emptyPrompt() -> String? {
        expect(.empty, from: "   ")
            ?? expect(.empty, from: "...")
            ?? expect(.empty, from: "")
    }

    static func unsupportedInstruction() -> String? {
        expect(.unsupported, from: "Remove the person.")
            ?? expect(.unsupported, from: "Replace the sky.")
            ?? expect(.unsupported, from: "Blur the background.")
            ?? expect(.unsupported, from: "Make this look like a cinematic movie.")
            ?? expect(.unsupported, from: "Generate a new image.")
    }

    static func mixedSupportedAndUnsupported() -> String? {
        let current = EditRecipe(exposureEV: 0.4, warmth: 0.2)
        guard case .failure(.unsupported) = PromptInterpreter.interpret("Make it warmer and remove the person.", current: current) else {
            return "mixed prompt should be unsupported"
        }
        return nil
    }

    static func caseInsensitive() -> String? {
        expect(.success(warmth: 0.5), from: "MAKE THIS PHOTO WARMER")
    }

    static func whitespaceAndPunctuation() -> String? {
        expect(.success(exposure: 0.5), from: "  Increase   brightness, slightly!!! ")
    }

    static func unmentionedControlsStay() -> String? {
        let current = EditRecipe(exposureEV: -1, contrast: 0.2, saturation: 0.4, warmth: 0)
        guard case .success(let recipe) = PromptInterpreter.interpret("Reduce saturation.", current: current) else {
            return "expected saturation change"
        }
        guard recipe.exposureEV == -1, recipe.contrast == 0.2, recipe.saturation == -0.5, recipe.warmth == 0 else {
            return "unmentioned controls changed: \(recipe)"
        }
        return nil
    }

    static func failureLeavesRecipeUnchanged() -> String? {
        var session = PromptApplication(recipe: EditRecipe(exposureEV: 0.4, contrast: 0.1, saturation: -0.2, warmth: 0.3))
        let original = session.recipe
        session.apply("Make it warmer and cooler.")
        guard session.recipe == original, session.errorMessage != nil else {
            return "failed prompt changed the recipe"
        }
        return nil
    }

    static func applyDoesNotSave() -> String? {
        var session = PromptApplication(recipe: EditRecipe(warmth: 0.25))
        session.apply("Make this photo warmer.")
        guard session.errorMessage == nil, session.recipe.warmth == 0.5 else {
            return "prompt did not update warmth"
        }
        session.apply("Remove the person.")
        guard session.recipe.warmth == 0.5, session.errorMessage != nil else {
            return "failed prompt replaced a successful recipe"
        }
        return nil
    }

    static func defaultRecipe() -> String? {
        let recipe = EditRecipe()
        guard recipe == EditRecipe(exposureEV: 0, contrast: 0, saturation: 0, warmth: 0), recipe.isWithinLimits else {
            return "default recipe is not neutral"
        }
        return nil
    }

    static func neutralReset() -> String? {
        var session = PromptApplication(recipe: EditRecipe(exposureEV: 1, contrast: 0.25, saturation: -0.5, warmth: 0.5))
        session.errorMessage = "previous"
        session.reset()
        guard session.recipe == EditRecipe(), session.errorMessage == nil else {
            return "reset did not return to neutral"
        }
        return nil
    }

    static func limits() -> String? {
        guard EditRecipe.exposureRange == -2...2,
              EditRecipe.contrastRange == -0.5...0.5,
              EditRecipe.saturationRange == -1...1,
              EditRecipe.warmthRange == -1...1 else {
            return "ranges drifted from the approved limits"
        }
        let edges = EditRecipe(exposureEV: -2, contrast: 0.5, saturation: -1, warmth: 1)
        guard edges.isWithinLimits, edges.clamped() == edges else {
            return "boundary values should be valid"
        }
        return nil
    }

    static func outOfRangeClamps() -> String? {
        let recipe = EditRecipe(exposureEV: 9, contrast: -3, saturation: 4, warmth: -2).clamped()
        guard recipe == EditRecipe(exposureEV: 2, contrast: -0.5, saturation: 1, warmth: -1) else {
            return "finite out-of-range values did not clamp: \(recipe)"
        }
        let json = #"{"exposureEV":9,"contrast":-3,"saturation":4,"warmth":-2}"#.data(using: .utf8)!
        guard let decoded = try? JSONDecoder().decode(EditRecipe.self, from: json), decoded == recipe else {
            return "decoded out-of-range recipe did not clamp"
        }
        return nil
    }

    static func nonFiniteClampsToNeutral() -> String? {
        let recipe = EditRecipe(exposureEV: .nan, contrast: .infinity, saturation: -.infinity, warmth: .signalingNaN).clamped()
        guard recipe == EditRecipe() else {
            return "non-finite values should become neutral"
        }
        guard !EditRecipe(exposureEV: .nan).isWithinLimits else {
            return "NaN should fail the limits check before clamping"
        }
        return nil
    }

    static func jsonRoundTrip() -> String? {
        let recipe = EditRecipe(exposureEV: 0.5, contrast: 0.25, saturation: -0.5, warmth: 1)
        guard let data = try? JSONEncoder().encode(recipe),
              let decoded = try? JSONDecoder().decode(EditRecipe.self, from: data),
              decoded == recipe else {
            return "recipe did not round-trip through JSON"
        }
        return nil
    }

    static func jsonMissingKeys() -> String? {
        let json = #"{"exposureEV":1.25}"#.data(using: .utf8)!
        guard let decoded = try? JSONDecoder().decode(EditRecipe.self, from: json) else {
            return "exposure-only recipe should still decode"
        }
        guard decoded == EditRecipe(exposureEV: 1.25) else {
            return "missing controls should decode as zero: \(decoded)"
        }
        return nil
    }

    static func jsonRejectsWrongType() -> String? {
        let json = #"{"exposureEV":"high"}"#.data(using: .utf8)!
        if (try? JSONDecoder().decode(EditRecipe.self, from: json)) != nil {
            return "a string value should not decode as a recipe"
        }
        return nil
    }

    static func versionConstants() -> String? {
        guard EditRecipe.formatIdentifier == "edu.sjsu.pixelsense.recipe", EditRecipe.formatVersion == "1" else {
            return "recipe format identity changed"
        }
        return nil
    }

    static func specDemoPrompts() -> String? {
        expect(.success(warmth: 0.5), from: "Make this photo warmer.")
            ?? expect(.success(exposure: 0.5), from: "Increase brightness slightly.")
            ?? expect(.success(saturation: -0.5), from: "Reduce saturation.")
            ?? expect(.success(contrast: 0.25, warmth: -0.5), from: "Make the photo cooler and increase contrast.")
    }

    static func vibranceSynonyms() -> String? {
        expect(.success(saturation: 0.5), from: "Make the colors more vibrant.")
            ?? expect(.success(saturation: 0.5), from: "Increase vibrance")
            ?? expect(.success(saturation: 0.5), from: "Make it more vibrant")
            ?? expect(.success(saturation: -0.5), from: "Reduce vibrance")
            ?? expect(.success(saturation: -0.5), from: "Make it less vibrant")
    }

    static func warmUpAndCoolDown() -> String? {
        expect(.success(warmth: 0.5), from: "Warm up the image.")
            ?? expect(.success(warmth: 0.5), from: "Warm up this photo")
            ?? expect(.success(warmth: -0.5), from: "Cool down the photo")
            ?? expect(.success(warmth: 0.25), from: "Warm up the image a little")
    }

    static func sprintExamplePrompts() -> String? {
        expect(.success(exposure: 1), from: "Make this photo brighter.")
            ?? expect(.success(contrast: -0.125), from: "Reduce contrast slightly.")
            ?? expect(.success(exposure: 1, saturation: -0.5), from: "Increase brightness and reduce saturation.")
            ?? expect(.success(saturation: 0.5, warmth: 0.25), from: "Make the photo a little warmer and more colorful.")
    }

    static func boostSynonyms() -> String? {
        expect(.success(contrast: 0.25), from: "Boost contrast")
            ?? expect(.success(saturation: 0.5), from: "Boost vibrance")
            ?? expect(.success(warmth: 0.5), from: "Boost warmth")
    }
}

private enum Expected {
    case success(exposure: Double = 0, contrast: Double = 0, saturation: Double = 0, warmth: Double = 0)
    case empty
    case unsupported
    case conflict(AdjustmentControl)
}

private func expect(_ expected: Expected, from text: String) -> String? {
    let result = PromptInterpreter.interpret(text)
    switch (expected, result) {
    case (.success(let exposure, let contrast, let saturation, let warmth), .success(let recipe)):
        let wanted = EditRecipe(exposureEV: exposure, contrast: contrast, saturation: saturation, warmth: warmth)
        return recipe == wanted ? nil : "\(text) -> \(recipe), wanted \(wanted)"
    case (.empty, .failure(.empty)),
         (.unsupported, .failure(.unsupported)):
        return nil
    case (.conflict(let control), .failure(.conflict(let actual))) where control == actual:
        return nil
    default:
        return "\(text) -> \(String(describing: result))"
    }
}
