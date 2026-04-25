import Foundation

/// Pure helpers used by the HTTP layer to validate request inputs before
/// mutating presentation state. Centralized so logic is testable from the
/// CiceroTests target without importing the Cicero app target.
public enum RequestValidator {

    /// Validate a 0-based slide index against the current slide count.
    /// Returns nil when valid, or an error message when out of range.
    public static func validateSlideIndex(_ index: Int, slideCount: Int) -> String? {
        guard slideCount >= 0 else {
            return "Invalid slide count"
        }
        if index < 0 || index >= slideCount {
            return "Slide index \(index) is out of range (deck has \(slideCount) slide\(slideCount == 1 ? "" : "s"))"
        }
        return nil
    }

    /// Validate an "after-index" used by POST /slides (insert after index).
    /// `afterIndex` is allowed to be -1 (insert at very front, after nothing) or
    /// in range [0, slideCount - 1]. Anything else is rejected. Nil afterIndex is always valid (append).
    public static func validateAfterIndex(_ afterIndex: Int?, slideCount: Int) -> String? {
        guard let index = afterIndex else { return nil }
        if index < -1 || index >= slideCount {
            return "afterIndex \(index) is out of range. Valid range: -1 to \(slideCount - 1) (deck has \(slideCount) slide\(slideCount == 1 ? "" : "s"))"
        }
        return nil
    }

    /// Validate a font name against the curated list returned by GET /font.
    /// Nil/empty are valid (system default). Returns error message when invalid.
    public static func validateCuratedFont(
        _ name: String?,
        curated: [String]
    ) -> String? {
        guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if curated.contains(trimmed) {
            return nil
        }
        return "Unknown font '\(trimmed)'. Valid: \(curated.joined(separator: ", "))"
    }
}

/// The curated list of fonts surfaced via GET /font and accepted by PUT /font.
/// Kept here so HTTP, MCP, and the tests share a single source of truth.
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
}
