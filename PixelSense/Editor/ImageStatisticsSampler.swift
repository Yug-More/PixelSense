import CoreImage
import Foundation

extension ImageStatistics {
    /// Downsamples the image and samples a coarse grid of pixels.
    ///
    /// Full-resolution walks are avoided so automatic enhancement stays responsive
    /// on large Photos library assets. Returns nil when the bitmap cannot be read.
    static func sample(from image: CIImage, context: CIContext = CIContext()) -> ImageStatistics? {
        // Match AdjustmentRenderer: reject empty/infinite extents before downsampling.
        guard AdjustmentRenderer.isRenderable(image) else {
            return nil
        }

        let maxDimension = max(image.extent.width, image.extent.height)
        let target = min(64.0, maxDimension)
        let scale = target / maxDimension
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let extent = scaled.extent.integral
        guard extent.width >= 1, extent.height >= 1, AdjustmentRenderer.isRenderable(scaled) else {
            return nil
        }

        guard let cgImage = context.createCGImage(scaled, from: extent) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let bitmap = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let stepX = max(1, width / 16)
        let stepY = max(1, height / 16)
        var lumaSum = 0.0
        var satSum = 0.0
        var lumaMin = 1.0
        var lumaMax = 0.0
        var count = 0.0

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(pixels[offset]) / 255.0
                let g = Double(pixels[offset + 1]) / 255.0
                let b = Double(pixels[offset + 2]) / 255.0
                let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
                let maxChannel = max(r, max(g, b))
                let minChannel = min(r, min(g, b))
                let saturation = maxChannel > 0 ? (maxChannel - minChannel) / maxChannel : 0

                lumaSum += luma
                satSum += saturation
                lumaMin = min(lumaMin, luma)
                lumaMax = max(lumaMax, luma)
                count += 1
                x += stepX
            }
            y += stepY
        }

        guard count > 0 else { return nil }

        let stats = ImageStatistics(
            averageLuminance: lumaSum / count,
            contrastRange: max(0, lumaMax - lumaMin),
            averageSaturation: satSum / count
        )
        return stats.isValid ? stats : nil
    }
}
