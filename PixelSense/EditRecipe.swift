import Photos

struct EditRecipe: Codable, Equatable {
    static let formatIdentifier = "edu.sjsu.pixelsense.recipe"
    static let formatVersion = "1"

    var exposureEV: Double = 0
    var contrast: Double = 0
    var saturation: Double = 0
    var warmth: Double = 0

    private enum CodingKeys: String, CodingKey {
        case exposureEV, contrast, saturation, warmth
    }

    init(exposureEV: Double = 0, contrast: Double = 0, saturation: Double = 0, warmth: Double = 0) {
        self.exposureEV = exposureEV
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        exposureEV = try values.decodeIfPresent(Double.self, forKey: .exposureEV) ?? 0
        contrast = try values.decodeIfPresent(Double.self, forKey: .contrast) ?? 0
        saturation = try values.decodeIfPresent(Double.self, forKey: .saturation) ?? 0
        warmth = try values.decodeIfPresent(Double.self, forKey: .warmth) ?? 0
    }

    static func decode(_ adjustmentData: PHAdjustmentData?) -> EditRecipe? {
        guard let adjustmentData,
              adjustmentData.formatIdentifier == formatIdentifier,
              adjustmentData.formatVersion == formatVersion else {
            return nil
        }
        return try? JSONDecoder().decode(EditRecipe.self, from: adjustmentData.data)
    }
}
