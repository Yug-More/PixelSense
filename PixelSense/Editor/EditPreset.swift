import Foundation

/// A named, centralized edit recipe for the editor UI.
///
/// Presets only use adjustments supported by `AdjustmentRenderer`. Applying a
/// preset replaces the current recipe; it does not stack onto existing values.
struct EditPreset: Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var recipe: EditRecipe

    var isWithinLimits: Bool {
        recipe.clamped() == recipe && recipe.isWithinLimits
    }
}

enum EditPresets {
    static let natural = EditPreset(
        id: "natural",
        name: "Natural",
        description: "No color or tone change.",
        recipe: EditRecipe()
    )

    static let portrait = EditPreset(
        id: "portrait",
        name: "Portrait",
        description: "Slightly brighter and warmer with softer color.",
        recipe: EditRecipe(exposureEV: 0.3, contrast: 0.05, saturation: -0.1, warmth: 0.15)
    )

    static let vibrant = EditPreset(
        id: "vibrant",
        name: "Vibrant",
        description: "Stronger color with a little contrast.",
        recipe: EditRecipe(exposureEV: 0.1, contrast: 0.15, saturation: 0.45, warmth: 0.05)
    )

    static let warm = EditPreset(
        id: "warm",
        name: "Warm",
        description: "Noticeably warmer tone.",
        recipe: EditRecipe(exposureEV: 0.1, contrast: 0.05, saturation: 0.1, warmth: 0.55)
    )

    static let cinematic = EditPreset(
        id: "cinematic",
        name: "Cinematic",
        description: "Cooler look with higher contrast and muted color.",
        recipe: EditRecipe(exposureEV: -0.15, contrast: 0.25, saturation: -0.2, warmth: -0.1)
    )

    /// Stable display order for the editor.
    static let all: [EditPreset] = [
        natural,
        portrait,
        vibrant,
        warm,
        cinematic
    ]

    static func preset(id: String) -> EditPreset? {
        all.first { $0.id == id }
    }
}
