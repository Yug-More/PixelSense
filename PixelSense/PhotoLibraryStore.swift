import Photos
import SwiftUI

@MainActor
final class PhotoLibraryStore: ObservableObject {
    @Published private(set) var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published private(set) var assets: [PHAsset] = []

    var hasAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    func requestAccess() async {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { result in
                continuation.resume(returning: result)
            }
        }
        authorizationStatus = status
        refresh()
    }

    func refresh() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard hasAccess else {
            assets = []
            return
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var photos: [PHAsset] = []
        result.enumerateObjects { asset, _, stop in
            // Live Photos need their own content editing flow; keep this proof to still photos.
            if !asset.mediaSubtypes.contains(.photoLive) {
                photos.append(asset)
            }
            if photos.count >= 100 {
                stop.pointee = true
            }
        }
        assets = photos
    }
}
