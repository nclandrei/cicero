import Foundation

/// Pure validation helpers for HTTP/MCP request payloads. Lives in Shared so it can
/// be exercised by the test target without depending on the Cicero app target.
public enum RequestValidator {

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
}
