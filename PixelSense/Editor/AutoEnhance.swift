import Foundation

enum AutoEnhanceFailure: Equatable, Error {
    case invalidStatistics

    var message: String {
        switch self {
        case .invalidStatistics:
            return "PixelSense could not measure this photo for automatic enhancement."
        }
    }
}

/// Deterministic, conservative recipe recommendations from image statistics.
///
/// Thresholds are intentional and documented here so recommendations stay
/// explainable in class demos. This is not a trained model.
enum AutoEnhance {
    /// Average luminance below this receives a modest exposure boost.
    static let darkLuminanceThreshold = 0.35
    /// Average luminance above this receives a modest exposure reduction.
    static let brightLuminanceThreshold = 0.72
    /// Contrast range below this receives a modest contrast increase.
    static let lowContrastThreshold = 0.28
    /// Average saturation below this receives a modest saturation increase.
    static let lowSaturationThreshold = 0.20
    /// Average saturation above this receives a small saturation reduction.
    static let highSaturationThreshold = 0.68

    static let darkExposureBoost = 0.45
    static let brightExposureCut = -0.30
    static let lowContrastBoost = 0.15
    static let lowSaturationBoost = 0.22
    static let highSaturationCut = -0.12

    /// Builds a clamped recipe from statistics. Invalid stats fail without guessing.
    static func recommend(from stats: ImageStatistics) -> Result<EditRecipe, AutoEnhanceFailure> {
        guard stats.isValid else {
            return .failure(.invalidStatistics)
        }

        var exposure = 0.0
        if stats.averageLuminance < darkLuminanceThreshold {
            exposure = darkExposureBoost
        } else if stats.averageLuminance > brightLuminanceThreshold {
            exposure = brightExposureCut
        }

        var contrast = 0.0
        if stats.contrastRange < lowContrastThreshold {
            contrast = lowContrastBoost
        }

        var saturation = 0.0
        if stats.averageSaturation < lowSaturationThreshold {
            saturation = lowSaturationBoost
        } else if stats.averageSaturation > highSaturationThreshold {
            saturation = highSaturationCut
        }

        let recipe = EditRecipe(
            exposureEV: exposure,
            contrast: contrast,
            saturation: saturation,
            warmth: 0
        ).clamped()

        guard recipe.isWithinLimits else {
            return .failure(.invalidStatistics)
        }
        return .success(recipe)
    }
}
