import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum AdjustmentRenderFailure: Equatable, Error {
    case invalidImageExtent

    var message: String {
        switch self {
        case .invalidImageExtent:
            return "PixelSense could not render this image because its dimensions are invalid."
        }
    }
}

/// Scales images for interactive previews without changing the full-resolution save path.
enum PreviewScaling {
    /// Longest side for interactive previews. Full-resolution rendering is reserved for save.
    static let maxDimension: CGFloat = 1200

    static func scaleFactor(width: CGFloat, height: CGFloat) -> CGFloat {
        let longest = max(width, height)
        guard longest.isFinite, longest > 0 else { return 1 }
        return min(1, maxDimension / longest)
    }

    static func scaleFactor(for image: CIImage) -> CGFloat {
        scaleFactor(width: image.extent.width, height: image.extent.height)
    }

    static func scaled(_ image: CIImage) -> CIImage {
        let factor = scaleFactor(for: image)
        guard factor < 1 else { return image }
        return image.transformed(by: CGAffineTransform(scaleX: factor, y: factor))
    }
}

enum AdjustmentRenderer {
    /// Stable filter order used by both preview and save.
    static let filterOrderDescription = "exposure → warmth → colorControls(contrast, saturation)"

    /// Neutral temperature for `CITemperatureAndTint` (Kelvin).
    static let neutralTemperature: CGFloat = 6500
    /// Degrees Kelvin shifted at warmth = ±1.
    static let warmthKelvinSpan: CGFloat = 2500

    /// Clamps recipe values into the shared editor limits before Core Image sees them.
    static func prepare(_ recipe: EditRecipe) -> EditRecipe {
        recipe.clamped()
    }

    static func isNeutral(_ recipe: EditRecipe) -> Bool {
        prepare(recipe) == EditRecipe()
    }

    static func isRenderable(_ image: CIImage) -> Bool {
        let extent = image.extent
        return extent.width.isFinite
            && extent.height.isFinite
            && !extent.isInfinite
            && extent.width > 0
            && extent.height > 0
    }

    static func exposureParameter(for recipe: EditRecipe) -> Float {
        Float(prepare(recipe).exposureEV)
    }

    static func contrastParameter(for recipe: EditRecipe) -> Float {
        Float(1 + prepare(recipe).contrast)
    }

    static func saturationParameter(for recipe: EditRecipe) -> Float {
        Float(1 + prepare(recipe).saturation)
    }

    static func targetTemperature(for recipe: EditRecipe) -> CGFloat {
        let warmth = prepare(recipe).warmth
        return neutralTemperature - CGFloat(warmth) * warmthKelvinSpan
    }

    /// Applies the prepared recipe. Invalid extents leave the image unchanged.
    /// Out-of-range or non-finite recipe values are clamped first so filter inputs stay finite.
    static func apply(_ recipe: EditRecipe, to image: CIImage) -> CIImage {
        guard isRenderable(image) else { return image }
        let prepared = prepare(recipe)
        if isNeutral(prepared) { return image }

        var result = image

        if prepared.exposureEV != 0 {
            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = result
            exposure.ev = Float(prepared.exposureEV)
            result = exposure.outputImage ?? result
        }

        if prepared.warmth != 0 {
            let temperature = CIFilter.temperatureAndTint()
            temperature.inputImage = result
            temperature.neutral = CIVector(x: neutralTemperature, y: 0)
            temperature.targetNeutral = CIVector(x: targetTemperature(for: prepared), y: 0)
            result = temperature.outputImage ?? result
        }

        if prepared.contrast != 0 || prepared.saturation != 0 {
            let color = CIFilter.colorControls()
            color.inputImage = result
            color.contrast = Float(1 + prepared.contrast)
            color.saturation = Float(1 + prepared.saturation)
            result = color.outputImage ?? result
        }

        return result
    }

    /// Same transforms as `apply`, but reports invalid image extents explicitly.
    static func applyValidated(_ recipe: EditRecipe, to image: CIImage) -> Result<CIImage, AdjustmentRenderFailure> {
        guard isRenderable(image) else {
            return .failure(.invalidImageExtent)
        }
        return .success(apply(recipe, to: image))
    }
}
