import Foundation

/// Pure helpers for text search-and-replace on slide content.
///
/// Matching is case-sensitive literal substring replacement so that the
/// resulting text preserves the caller's exact casing choice.
public enum SearchReplace {

    public struct Result: Sendable, Equatable {
        public let updatedContent: String
        public let replacements: Int

        public init(updatedContent: String, replacements: Int) {
            self.updatedContent = updatedContent
            self.replacements = replacements
        }
    }

    public static func replaceInContent(
        _ content: String,
        query: String,
        replacement: String
    ) -> Result {
        guard !query.isEmpty else {
            return Result(updatedContent: content, replacements: 0)
        }
        let parts = content.components(separatedBy: query)
        let count = parts.count - 1
        if count == 0 {
            return Result(updatedContent: content, replacements: 0)
        }
        return Result(
            updatedContent: parts.joined(separator: replacement),
            replacements: count
        )
    }
}
