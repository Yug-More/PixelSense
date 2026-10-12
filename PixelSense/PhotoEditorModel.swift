import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI
import UniformTypeIdentifiers

struct EditRecipe: Codable {
    static let formatIdentifier = "edu.sjsu.pixelsense.recipe"
    static let formatVersion = "1"

    var exposureEV: Double

    static func decode(_ adjustmentData: PHAdjustmentData?) -> EditRecipe? {
        guard let adjustmentData,
              adjustmentData.formatIdentifier == formatIdentifier,
              adjustmentData.formatVersion == formatVersion else {
            return nil
        }
        return try? JSONDecoder().decode(EditRecipe.self, from: adjustmentData.data)
    }
}

enum PhotoEditError: LocalizedError {
    case noEditingInput
    case noImageData
    case unsupportedOutput
    case renderingFailed
    case savingFailed

    var errorDescription: String? {
        switch self {
        case .noEditingInput: return "Photos could not open this item for editing. Check access and try another still photo."
        case .noImageData: return "This photo has no supported full-size image data. Try a standard JPEG or HEIC photo."
        case .unsupportedOutput: return "Photos cannot accept a JPEG edit for this item. Try another still photo."
        case .renderingFailed: return "PixelSense could not render this photo."
        case .savingFailed: return "Photos did not save the edit. Please try again."
        }
    }
}

@MainActor
final class PhotoEditorModel: ObservableObject {
    let asset: PHAsset

    @Published var exposureEV = 0.0
    @Published private(set) var beforePreview: UIImage?
    @Published private(set) var editedPreview: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var message: String?
    @Published private(set) var errorMessage: String?

    private var sourceImage: CIImage?
    private let context = CIContext()

    init(asset: PHAsset) {
        self.asset = asset
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        message = nil
        beforePreview = nil
        editedPreview = nil
        sourceImage = nil

        do {
            let input = try await requestEditingInput()
            let source = try image(from: input)
            sourceImage = source
            exposureEV = EditRecipe.decode(input.adjustmentData)?.exposureEV ?? 0
            beforePreview = try renderPreview(source)
            updatePreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePreview() {
        guard let sourceImage else { return }
        do {
            editedPreview = try renderPreview(adjust(sourceImage, exposureEV: exposureEV))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        message = nil
        errorMessage = nil

        do {
            // Always request fresh input: Photos may have changed since the preview was loaded.
            let input = try await requestEditingInput()
            let source = try image(from: input)
            let output = PHContentEditingOutput(contentEditingInput: input)
            guard output.supportedRenderedContentTypes.contains(.jpeg) else {
                throw PhotoEditError.unsupportedOutput
            }
            let outputURL = try output.renderedContentURL(for: .jpeg)
            let recipe = EditRecipe(exposureEV: exposureEV)
            output.adjustmentData = PHAdjustmentData(
                formatIdentifier: EditRecipe.formatIdentifier,
                formatVersion: EditRecipe.formatVersion,
                data: try JSONEncoder().encode(recipe)
            )

            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            try context.writeJPEGRepresentation(
                of: adjust(source, exposureEV: exposureEV),
                to: outputURL,
                colorSpace: colorSpace,
                options: [:]
            )

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest(for: self.asset)
                    request.contentEditingOutput = output
                } completionHandler: { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? PhotoEditError.savingFailed)
                    }
                }
            }
            message = "Saved to the same photo in your library."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestEditingInput() async throws -> PHContentEditingInput {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = { EditRecipe.decode($0) != nil }

        return try await withCheckedThrowingContinuation { continuation in
            asset.requestContentEditingInput(with: options) { input, _ in
                if let input {
                    continuation.resume(returning: input)
                } else {
                    continuation.resume(throwing: PhotoEditError.noEditingInput)
                }
            }
        }
    }

    private func image(from input: PHContentEditingInput) throws -> CIImage {
        guard let url = input.fullSizeImageURL,
              let image = CIImage(contentsOf: url) else {
            throw PhotoEditError.noImageData
        }
        return image.oriented(forExifOrientation: input.fullSizeImageOrientation)
    }

    private func adjust(_ image: CIImage, exposureEV: Double) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(exposureEV)
        return filter.outputImage ?? image
    }

    private func renderPreview(_ image: CIImage) throws -> UIImage {
        let maxDimension = max(image.extent.width, image.extent.height)
        let scale = min(1, 1400 / maxDimension)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let output = context.createCGImage(scaled, from: scaled.extent) else {
            throw PhotoEditError.renderingFailed
        }
        return UIImage(cgImage: output)
    }
}
