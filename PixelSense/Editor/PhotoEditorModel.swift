import CoreImage
import Photos
import SwiftUI
import UniformTypeIdentifiers

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
    @Published var contrast = 0.0
    @Published var saturation = 0.0
    @Published var warmth = 0.0
    @Published private(set) var beforePreview: UIImage?
    @Published private(set) var editedPreview: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var message: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var promptError: String?
    @Published private(set) var enhanceMessage: String?
    @Published private(set) var enhanceError: String?
    @Published private(set) var isEnhancing = false

    private var sourceImage: CIImage?
    /// Downscaled source used for interactive previews so sliders do not reprocess full resolution.
    private var previewSourceImage: CIImage?
    private var lastPreviewRecipe: EditRecipe?
    private let context = CIContext(options: [.workingColorSpace: NSNull()])
    private let previewColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    init(asset: PHAsset) {
        self.asset = asset
    }

    private var recipe: EditRecipe {
        EditRecipe(
            exposureEV: exposureEV,
            contrast: contrast,
            saturation: saturation,
            warmth: warmth
        )
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        message = nil
        promptError = nil
        enhanceMessage = nil
        enhanceError = nil
        beforePreview = nil
        editedPreview = nil
        sourceImage = nil
        previewSourceImage = nil
        lastPreviewRecipe = nil

        do {
            let input = try await requestEditingInput()
            let source = try image(from: input)
            guard AdjustmentRenderer.isRenderable(source) else {
                throw PhotoEditError.renderingFailed
            }
            sourceImage = source
            // Build the preview pyramid once per load; slider updates reuse this CIImage.
            let previewSource = PreviewScaling.scaled(source)
            previewSourceImage = previewSource
            let savedRecipe = EditRecipe.decode(input.adjustmentData) ?? EditRecipe()
            exposureEV = savedRecipe.exposureEV
            contrast = savedRecipe.contrast
            saturation = savedRecipe.saturation
            warmth = savedRecipe.warmth
            beforePreview = try renderPreviewBitmap(previewSource)
            updatePreview()
        } catch {
            // Drop partial session state so a failed load cannot drive preview/save.
            sourceImage = nil
            previewSourceImage = nil
            lastPreviewRecipe = nil
            beforePreview = nil
            editedPreview = nil
            errorMessage = error.localizedDescription
        }
    }

    func updatePreview() {
        guard let previewSourceImage else { return }
        let prepared = AdjustmentRenderer.prepare(recipe)
        if prepared == lastPreviewRecipe { return }

        do {
            if AdjustmentRenderer.isNeutral(prepared) {
                editedPreview = beforePreview
            } else {
                let adjusted = AdjustmentRenderer.apply(prepared, to: previewSourceImage)
                editedPreview = try renderPreviewBitmap(adjusted)
            }
            lastPreviewRecipe = prepared
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetAdjustments() {
        exposureEV = 0
        contrast = 0
        saturation = 0
        warmth = 0
        promptError = nil
        enhanceMessage = nil
        enhanceError = nil
        updatePreview()
    }

    /// Fills the sliders from a supported prompt. A failed prompt leaves the recipe unchanged
    /// and never calls `save()`.
    func applyPrompt(_ text: String) {
        var session = PromptApplication(recipe: recipe)
        session.apply(text)
        promptError = session.errorMessage
        enhanceMessage = nil
        enhanceError = nil
        guard session.errorMessage == nil else { return }
        applyRecipeToSliders(session.recipe)
        updatePreview()
    }

    /// Replaces the current recipe with a named preset. Does not save.
    func applyPreset(_ preset: EditPreset) {
        promptError = nil
        enhanceError = nil
        enhanceMessage = "Applied \(preset.name)."
        applyRecipeToSliders(preset.recipe.clamped())
        updatePreview()
    }

    /// Samples the loaded photo and replaces the recipe with a conservative recommendation.
    /// Uses the unedited preview-scaled source (not the current slider recipe) so repeats do not compound.
    func applyAutoEnhance() {
        // Prefer the cached preview pyramid so large library assets are not re-measured at full resolution.
        guard let sampleSource = previewSourceImage ?? sourceImage else {
            enhanceMessage = nil
            enhanceError = AutoEnhanceFailure.invalidStatistics.message
            return
        }
        isEnhancing = true
        defer { isEnhancing = false }
        promptError = nil
        enhanceError = nil
        guard let stats = ImageStatistics.sample(from: sampleSource, context: context) else {
            enhanceMessage = nil
            enhanceError = AutoEnhanceFailure.invalidStatistics.message
            return
        }
        switch AutoEnhance.recommend(from: stats) {
        case .success(let recommended):
            applyRecipeToSliders(recommended)
            enhanceMessage = recommended == EditRecipe()
                ? "Photo already looks balanced. Little or no change applied."
                : "Applied automatic enhancement from photo measurements."
            updatePreview()
        case .failure(let failure):
            enhanceMessage = nil
            enhanceError = failure.message
        }
    }

    func clearPromptError() {
        promptError = nil
    }

    private func applyRecipeToSliders(_ recipe: EditRecipe) {
        let prepared = AdjustmentRenderer.prepare(recipe)
        exposureEV = prepared.exposureEV
        contrast = prepared.contrast
        saturation = prepared.saturation
        warmth = prepared.warmth
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
            // Clamp before encode so PHAdjustmentData matches the rendered pixels Tejas reopens later.
            let recipe = AdjustmentRenderer.prepare(self.recipe)
            output.adjustmentData = PHAdjustmentData(
                formatIdentifier: EditRecipe.formatIdentifier,
                formatVersion: EditRecipe.formatVersion,
                data: try JSONEncoder().encode(recipe)
            )

            guard AdjustmentRenderer.isRenderable(source) else {
                throw PhotoEditError.renderingFailed
            }
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            // Save always renders full resolution from a fresh Photos input, not the preview pyramid.
            try context.writeJPEGRepresentation(
                of: AdjustmentRenderer.apply(recipe, to: source),
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

    /// Renders a bitmap for an image that is already at preview scale.
    private func renderPreviewBitmap(_ image: CIImage) throws -> UIImage {
        guard AdjustmentRenderer.isRenderable(image) else {
            throw PhotoEditError.renderingFailed
        }
        let extent = image.extent.integral
        guard let output = context.createCGImage(
            image,
            from: extent,
            format: .RGBA8,
            colorSpace: previewColorSpace
        ) else {
            throw PhotoEditError.renderingFailed
        }
        return UIImage(cgImage: output)
    }
}
