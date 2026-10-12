import Photos
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library = PhotoLibraryStore()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if library.hasAccess {
                    ScrollView {
                        if library.assets.isEmpty {
                            ContentUnavailableView(
                                "No supported photos found",
                                systemImage: "photo",
                                description: Text("Add a still photo or allow PixelSense to see more photos in Settings.")
                            )
                        } else {
                            LazyVGrid(columns: columns, spacing: 3) {
                                ForEach(library.assets, id: \.localIdentifier) { asset in
                                    NavigationLink {
                                        PhotoEditorView(asset: asset)
                                    } label: {
                                        PhotoThumbnailView(asset: asset)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 56))
                        Text("Edit a photo already in your library")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("PixelSense needs access to the photos you choose. Saving will update the selected photo, not add another gallery item.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        if library.authorizationStatus == .denied || library.authorizationStatus == .restricted {
                            Button("Open Settings") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(url)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Allow Photos Access") {
                                Task { await library.requestAccess() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(28)
                }
            }
            .navigationTitle("PixelSense")
            .toolbar {
                if library.hasAccess {
                    Button("Refresh") { library.refresh() }
                }
            }
            .onAppear { library.refresh() }
            .onChange(of: scenePhase) {
                if scenePhase == .active { library.refresh() }
            }
        }
    }
}

private struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear {
            guard image == nil else { return }
            requestID = PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: nil
            ) { result, _ in
                DispatchQueue.main.async { image = result }
            }
        }
        .onDisappear {
            if let requestID {
                PHImageManager.default().cancelImageRequest(requestID)
            }
        }
    }
}

private struct PhotoEditorView: View {
    @StateObject private var model: PhotoEditorModel
    @State private var showBefore = false

    init(asset: PHAsset) {
        _model = StateObject(wrappedValue: PhotoEditorModel(asset: asset))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = showBefore ? model.beforePreview : model.editedPreview {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 360)
                } else if model.isLoading {
                    ProgressView("Opening photo…")
                        .frame(height: 300)
                }

                Button(showBefore ? "Show edit" : "Show before") {
                    showBefore.toggle()
                }
                .disabled(model.beforePreview == nil)

                VStack(spacing: 14) {
                    adjustmentControl("Exposure", value: $model.exposureEV, range: -2...2, step: 0.1, format: "%+.1f EV")
                    adjustmentControl("Contrast", value: $model.contrast, range: -0.5...0.5, step: 0.05, format: "%+.0f%%", multiplier: 100)
                    adjustmentControl("Saturation", value: $model.saturation, range: -1...1, step: 0.05, format: "%+.0f%%", multiplier: 100)
                    adjustmentControl("Warmth", value: $model.warmth, range: -1...1, step: 0.05, format: "%+.0f%%", multiplier: 100)
                }
                .disabled(model.isLoading || model.isSaving)

                Button("Reset settings") { model.resetAdjustments() }
                    .disabled(model.isLoading || model.isSaving || model.editedPreview == nil)

                Button {
                    Task { await model.save() }
                } label: {
                    if model.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save to this photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isLoading || model.isSaving || model.editedPreview == nil)

                if let message = model.message {
                    Text(message).foregroundStyle(.green)
                }
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Edit photo")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .onChange(of: model.exposureEV) { model.updatePreview() }
        .onChange(of: model.contrast) { model.updatePreview() }
        .onChange(of: model.saturation) { model.updatePreview() }
        .onChange(of: model.warmth) { model.updatePreview() }
    }

    private func adjustmentControl(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        multiplier: Double = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
