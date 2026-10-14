import Photos

extension EditRecipe {
    /// Reads a PixelSense version-1 recipe. Unknown formats return nil so the editor
    /// keeps the baseline Photos supplied instead of guessing another app's settings.
    static func decode(_ adjustmentData: PHAdjustmentData?) -> EditRecipe? {
        guard let adjustmentData,
              adjustmentData.formatIdentifier == formatIdentifier,
              adjustmentData.formatVersion == formatVersion else {
            return nil
        }
        return try? JSONDecoder().decode(EditRecipe.self, from: adjustmentData.data)
    }
}
