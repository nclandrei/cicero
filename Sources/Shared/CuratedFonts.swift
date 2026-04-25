import Foundation

/// Hand-picked list of font families surfaced in pickers across the app.
/// Mirrors the curated list in `ToolbarView` so that user-configurable
/// "Default font" preferences resolve to the same names.
public enum CuratedFonts {
    public static let all: [String] = [
        "SF Pro Display",
        "Helvetica Neue",
        "Georgia",
        "Palatino",
        "Courier New",
        "Menlo",
        "SF Mono",
    ]

    /// The fallback font name when no preference is set.
    public static let defaultFont: String = "SF Pro Display"
}
