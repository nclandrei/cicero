import Foundation

/// Pure helpers for generating accessibility labels for slide-related controls.
///
/// Extracted into `Shared` so the branching label logic can be unit-tested
/// without an executable-target import. Views call into these helpers from
/// `accessibilityLabel(...)` to keep VoiceOver announcements consistent.
public enum SlideAccessibility {
    /// Label for a slide thumbnail (sidebar, overview grid).
    ///
    /// - Parameters:
    ///   - index: 0-based slide index.
    ///   - total: Total number of slides.
    ///   - title: Optional slide title (the first H1, etc.).
    /// - Returns: A human-readable phrase suitable for `accessibilityLabel`.
    ///
    /// Examples:
    ///   - `thumbnailLabel(index: 0, total: 5, title: "Intro")` → `"Slide 1 of 5: Intro"`
    ///   - `thumbnailLabel(index: 2, total: 5, title: nil)`     → `"Slide 3 of 5"`
    ///   - `thumbnailLabel(index: 1, total: 3, title: "  ")`    → `"Slide 2 of 3"`
    public static func thumbnailLabel(index: Int, total: Int, title: String?) -> String {
        let displayIndex = index + 1
        let base = "Slide \(displayIndex) of \(total)"
        if let title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return "\(base): \(trimmed)"
            }
        }
        return base
    }
}
