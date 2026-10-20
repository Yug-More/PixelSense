import CoreImage
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
        LogicCheck(name: "boost synonyms", run: boostSynonyms),
        LogicCheck(name: "auto enhance dark image", run: autoEnhanceDarkImage),
        LogicCheck(name: "auto enhance bright image", run: autoEnhanceBrightImage),
        LogicCheck(name: "auto enhance low contrast", run: autoEnhanceLowContrast),
        LogicCheck(name: "auto enhance high saturation", run: autoEnhanceHighSaturation),
        LogicCheck(name: "auto enhance balanced image", run: autoEnhanceBalancedImage),
        LogicCheck(name: "auto enhance invalid statistics", run: autoEnhanceInvalidStatistics),
        LogicCheck(name: "auto enhance clamps recommendations", run: autoEnhanceClampsRecommendations),
        LogicCheck(name: "auto enhance repeatability", run: autoEnhanceRepeatability),
        LogicCheck(name: "auto enhance ignores prior recipe", run: autoEnhanceIgnoresPriorRecipe),
        LogicCheck(name: "preset catalog", run: presetCatalog),
        LogicCheck(name: "preset application replaces", run: presetApplicationReplaces),
        LogicCheck(name: "natural preset is neutral", run: naturalPresetIsNeutral),
        LogicCheck(name: "auto enhance low saturation", run: autoEnhanceLowSaturation),
        LogicCheck(name: "cinematic preset values", run: cinematicPresetValues),
        LogicCheck(name: "preset lookup by id", run: presetLookupById),
        LogicCheck(name: "prompt warm up with vibrance", run: promptWarmUpWithVibrance),
        LogicCheck(name: "renderer prepares by clamping", run: rendererPreparesByClamping),
        LogicCheck(name: "renderer parameter mapping", run: rendererParameterMapping),
        LogicCheck(name: "renderer warmth temperature mapping", run: rendererWarmthTemperatureMapping),
        LogicCheck(name: "renderer neutral is identity", run: rendererNeutralIsIdentity),
        LogicCheck(name: "renderer clamps before apply", run: rendererClampsBeforeApply),
        LogicCheck(name: "renderer rejects invalid extent", run: rendererRejectsInvalidExtent),
        LogicCheck(name: "preview scale factor", run: previewScaleFactor),
        LogicCheck(name: "preview scale leaves small images", run: previewScaleLeavesSmallImages),
        LogicCheck(name: "renderer filter order constant", run: rendererFilterOrderConstant)
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

    static func autoEnhanceDarkImage() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.20, contrastRange: 0.40, averageSaturation: 0.35)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "dark image should recommend a recipe"
        }
        guard recipe.exposureEV == AutoEnhance.darkExposureBoost, recipe.warmth == 0 else {
            return "dark image exposure mismatch: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceBrightImage() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.85, contrastRange: 0.40, averageSaturation: 0.35)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "bright image should recommend a recipe"
        }
        guard recipe.exposureEV == AutoEnhance.brightExposureCut else {
            return "bright image exposure mismatch: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceLowContrast() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.50, contrastRange: 0.15, averageSaturation: 0.35)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "low contrast should recommend a recipe"
        }
        guard recipe.contrast == AutoEnhance.lowContrastBoost, recipe.exposureEV == 0 else {
            return "low contrast mismatch: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceHighSaturation() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.50, contrastRange: 0.40, averageSaturation: 0.80)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "high saturation should recommend a recipe"
        }
        guard recipe.saturation == AutoEnhance.highSaturationCut else {
            return "high saturation mismatch: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceBalancedImage() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.50, contrastRange: 0.45, averageSaturation: 0.40)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "balanced image should succeed"
        }
        guard recipe == EditRecipe() else {
            return "balanced image should stay near neutral: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceInvalidStatistics() -> String? {
        let invalid = [
            ImageStatistics(averageLuminance: .nan, contrastRange: 0.4, averageSaturation: 0.3),
            ImageStatistics(averageLuminance: 0.4, contrastRange: 1.5, averageSaturation: 0.3),
            ImageStatistics(averageLuminance: -0.1, contrastRange: 0.4, averageSaturation: 0.3)
        ]
        for stats in invalid {
            guard case .failure(.invalidStatistics) = AutoEnhance.recommend(from: stats) else {
                return "invalid statistics should fail: \(stats)"
            }
        }
        return nil
    }

    static func autoEnhanceClampsRecommendations() -> String? {
        guard case .success(let recipe) = AutoEnhance.recommend(
            from: ImageStatistics(averageLuminance: 0.10, contrastRange: 0.10, averageSaturation: 0.05)
        ) else {
            return "combined dark/low-contrast/low-sat should succeed"
        }
        guard recipe.isWithinLimits, recipe == recipe.clamped() else {
            return "recommendation escaped limits: \(recipe)"
        }
        return nil
    }

    static func autoEnhanceRepeatability() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.22, contrastRange: 0.18, averageSaturation: 0.12)
        guard case .success(let first) = AutoEnhance.recommend(from: stats),
              case .success(let second) = AutoEnhance.recommend(from: stats),
              first == second else {
            return "same statistics must produce the same recipe"
        }
        return nil
    }

    static func autoEnhanceIgnoresPriorRecipe() -> String? {
        // Recommendations are derived only from statistics, so prior slider values
        // cannot compound into the suggestion itself.
        let stats = ImageStatistics(averageLuminance: 0.25, contrastRange: 0.40, averageSaturation: 0.35)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "expected a recommendation"
        }
        let prior = EditRecipe(exposureEV: 1.5, contrast: 0.4, saturation: 0.8, warmth: 0.9)
        guard recipe != prior, recipe.exposureEV == AutoEnhance.darkExposureBoost else {
            return "recommendation unexpectedly depended on a prior recipe"
        }
        return nil
    }

    static func presetCatalog() -> String? {
        let expectedIDs = ["natural", "portrait", "vibrant", "warm", "cinematic"]
        guard EditPresets.all.map(\.id) == expectedIDs else {
            return "preset catalog order or ids drifted"
        }
        for preset in EditPresets.all {
            guard preset.isWithinLimits else {
                return "preset \(preset.id) is outside recipe limits"
            }
            guard !preset.name.isEmpty, !preset.description.isEmpty else {
                return "preset \(preset.id) is missing display text"
            }
        }
        return nil
    }

    static func presetApplicationReplaces() -> String? {
        var session = PromptApplication(recipe: EditRecipe(exposureEV: 1, contrast: 0.25, saturation: -0.5, warmth: 0.5))
        session.recipe = EditPresets.vibrant.recipe
        session.errorMessage = nil
        guard session.recipe == EditPresets.vibrant.recipe else {
            return "applying a preset should replace the current recipe"
        }
        session.recipe = EditPresets.warm.recipe
        guard session.recipe == EditPresets.warm.recipe,
              session.recipe != EditPresets.vibrant.recipe else {
            return "switching presets should replace, not combine"
        }
        return nil
    }

    static func naturalPresetIsNeutral() -> String? {
        guard EditPresets.natural.recipe == EditRecipe() else {
            return "Natural preset must be a neutral recipe"
        }
        return nil
    }

    static func autoEnhanceLowSaturation() -> String? {
        let stats = ImageStatistics(averageLuminance: 0.50, contrastRange: 0.40, averageSaturation: 0.10)
        guard case .success(let recipe) = AutoEnhance.recommend(from: stats) else {
            return "low saturation should recommend a recipe"
        }
        guard recipe.saturation == AutoEnhance.lowSaturationBoost, recipe.exposureEV == 0 else {
            return "low saturation mismatch: \(recipe)"
        }
        return nil
    }

    static func cinematicPresetValues() -> String? {
        let recipe = EditPresets.cinematic.recipe
        guard recipe.exposureEV == -0.15,
              recipe.contrast == 0.25,
              recipe.saturation == -0.2,
              recipe.warmth == -0.1 else {
            return "cinematic preset drifted: \(recipe)"
        }
        return nil
    }

    static func presetLookupById() -> String? {
        guard EditPresets.preset(id: "warm") == EditPresets.warm,
              EditPresets.preset(id: "missing") == nil else {
            return "preset lookup by id failed"
        }
        return nil
    }

    static func promptWarmUpWithVibrance() -> String? {
        expect(.success(saturation: 0.5, warmth: 0.5), from: "Warm up the image and increase vibrance.")
    }

    static func rendererPreparesByClamping() -> String? {
        let prepared = AdjustmentRenderer.prepare(
            EditRecipe(exposureEV: 9, contrast: -3, saturation: .nan, warmth: 2)
        )
        guard prepared == EditRecipe(exposureEV: 2, contrast: -0.5, saturation: 0, warmth: 1) else {
            return "prepare did not clamp: \(prepared)"
        }
        return nil
    }

    static func rendererParameterMapping() -> String? {
        let recipe = EditRecipe(exposureEV: 1, contrast: 0.25, saturation: -0.5, warmth: 0)
        guard AdjustmentRenderer.exposureParameter(for: recipe) == 1,
              AdjustmentRenderer.contrastParameter(for: recipe) == 1.25,
              AdjustmentRenderer.saturationParameter(for: recipe) == 0.5 else {
            return "Core Image parameter mapping drifted"
        }
        return nil
    }

    static func rendererWarmthTemperatureMapping() -> String? {
        let warm = AdjustmentRenderer.targetTemperature(for: EditRecipe(warmth: 1))
        let cool = AdjustmentRenderer.targetTemperature(for: EditRecipe(warmth: -1))
        let neutral = AdjustmentRenderer.targetTemperature(for: EditRecipe())
        guard warm == 4000, cool == 9000, neutral == 6500 else {
            return "warmth Kelvin mapping drifted: warm=\(warm) cool=\(cool) neutral=\(neutral)"
        }
        return nil
    }

    static func rendererNeutralIsIdentity() -> String? {
        let image = solidTestImage(red: 0.4, green: 0.5, blue: 0.6)
        let result = AdjustmentRenderer.apply(EditRecipe(), to: image)
        guard result.extent == image.extent else {
            return "neutral recipe should keep the image extent"
        }
        guard AdjustmentRenderer.isNeutral(EditRecipe()) else {
            return "empty recipe should be neutral"
        }
        return nil
    }

    static func rendererClampsBeforeApply() -> String? {
        let image = solidTestImage(red: 0.2, green: 0.3, blue: 0.4)
        let wild = EditRecipe(exposureEV: 50, contrast: 10, saturation: 10, warmth: 10)
        let clamped = AdjustmentRenderer.prepare(wild)
        let fromWild = AdjustmentRenderer.apply(wild, to: image)
        let fromClamped = AdjustmentRenderer.apply(clamped, to: image)
        guard fromWild.extent == fromClamped.extent, clamped.isWithinLimits else {
            return "wild recipes should clamp before rendering"
        }
        return nil
    }

    static func rendererRejectsInvalidExtent() -> String? {
        // An uncropped color image has an infinite extent.
        let infinite = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5))
        guard infinite.extent.isInfinite else {
            return "expected an infinite extent test image"
        }
        guard case .failure(.invalidImageExtent) = AdjustmentRenderer.applyValidated(EditRecipe(exposureEV: 0.5), to: infinite) else {
            return "infinite extent should fail validation"
        }
        let recovered = AdjustmentRenderer.apply(EditRecipe(exposureEV: 0.5), to: infinite)
        guard recovered.extent.isInfinite else {
            return "apply should leave invalid extents unchanged"
        }
        return nil
    }

    static func previewScaleFactor() -> String? {
        let factor = PreviewScaling.scaleFactor(width: 4000, height: 3000)
        let expected = PreviewScaling.maxDimension / 4000
        guard abs(factor - expected) < 0.0001 else {
            return "large image scale factor mismatch: \(factor)"
        }
        return nil
    }

    static func previewScaleLeavesSmallImages() -> String? {
        guard PreviewScaling.scaleFactor(width: 800, height: 600) == 1 else {
            return "images already under the preview cap should not downscale"
        }
        let image = solidTestImage(red: 0.1, green: 0.2, blue: 0.3, size: 64)
        let scaled = PreviewScaling.scaled(image)
        guard scaled.extent == image.extent else {
            return "small images should keep their extent after preview scaling"
        }
        return nil
    }

    static func rendererFilterOrderConstant() -> String? {
        guard AdjustmentRenderer.filterOrderDescription.contains("exposure"),
              AdjustmentRenderer.filterOrderDescription.contains("warmth"),
              AdjustmentRenderer.filterOrderDescription.contains("colorControls") else {
            return "filter order documentation drifted"
        }
        return nil
    }
}

private func solidTestImage(red: CGFloat, green: CGFloat, blue: CGFloat, size: CGFloat = 32) -> CIImage {
    CIImage(color: CIColor(red: red, green: green, blue: blue))
        .cropped(to: CGRect(x: 0, y: 0, width: size, height: size))
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
