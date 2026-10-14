import CoreImage
import CoreImage.CIFilterBuiltins

enum AdjustmentRenderer {
    static func apply(_ recipe: EditRecipe, to image: CIImage) -> CIImage {
        var result = image

        if recipe.exposureEV != 0 {
            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = result
            exposure.ev = Float(recipe.exposureEV)
            result = exposure.outputImage ?? result
        }

        if recipe.warmth != 0 {
            let temperature = CIFilter.temperatureAndTint()
            temperature.inputImage = result
            temperature.neutral = CIVector(x: 6500, y: 0)
            temperature.targetNeutral = CIVector(x: 6500 - recipe.warmth * 2500, y: 0)
            result = temperature.outputImage ?? result
        }

        if recipe.contrast != 0 || recipe.saturation != 0 {
            let color = CIFilter.colorControls()
            color.inputImage = result
            color.contrast = Float(1 + recipe.contrast)
            color.saturation = Float(1 + recipe.saturation)
            result = color.outputImage ?? result
        }

        return result
    }
}
