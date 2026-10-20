import Foundation

/// Compact image measurements used by automatic enhancement rules.
///
/// Values are normalized to approximately 0...1. They are estimates from a
/// downsampled sample, not a full-resolution histogram.
struct ImageStatistics: Equatable {
    /// Average relative luminance (Rec. 709 weights). Darker images are lower.
    var averageLuminance: Double
    /// Difference between the brightest and darkest sampled luminances.
    var contrastRange: Double
    /// Average per-pixel saturation, approximated as (maxRGB - minRGB) / maxRGB.
    var averageSaturation: Double

    var isValid: Bool {
        Self.isUnitValue(averageLuminance)
            && Self.isUnitValue(contrastRange)
            && Self.isUnitValue(averageSaturation)
    }

    private static func isUnitValue(_ value: Double) -> Bool {
        value.isFinite && value >= 0 && value <= 1
    }
}
