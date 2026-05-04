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

    /// Returns the first index in `indices` that is out of `0..<count`, or nil if all valid.
    public static func firstOutOfRange(_ indices: [Int], count: Int) -> Int? {
        for index in indices {
            if index < 0 || index >= count { return index }
        }
        return nil
    }

    /// Validates a `BulkSetSlidesRequest` against `slideCount`.
    /// Returns nil on success, or an error message string on failure.
    public static func validateBulk(_ request: BulkSetSlidesRequest, slideCount: Int) -> String? {
        if request.updates.isEmpty {
            return "No updates provided"
        }
        if let bad = firstOutOfRange(request.updates.map(\.index), count: slideCount) {
            return "Slide index out of range: \(bad)"
        }
        return nil
    }

    /// Validate a find-and-replace query. An empty or whitespace-only query
    /// is rejected so callers don't accidentally mass-rewrite content (an
    /// empty needle silently matches nothing, but whitespace-only would
    /// match the most common character in every slide).
    public static func validateFindReplaceQuery(_ query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "query must be a non-empty, non-whitespace string"
        }
        return nil
    }
}
