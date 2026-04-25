import Foundation

/// Pure helpers for find-and-replace across slide content. Keeping this in Shared
/// lets the test target exercise it without touching the Cicero target.
public enum FindReplace {

    /// Result of replacing within a single string.
    public struct StringResult: Sendable, Equatable {
        public let newContent: String
        public let count: Int

        public init(newContent: String, count: Int) {
            self.newContent = newContent
            self.count = count
        }
    }

    /// Replace all occurrences of `query` with `replacement` in `content`.
    /// `caseSensitive=false` matches case-insensitively but preserves the replacement as-given.
    public static func replace(in content: String, query: String, replacement: String, caseSensitive: Bool) -> StringResult {
        guard !query.isEmpty else { return StringResult(newContent: content, count: 0) }
        if caseSensitive {
            // Count occurrences first, then replace.
            let count = countOccurrences(of: query, in: content, caseSensitive: true)
            if count == 0 { return StringResult(newContent: content, count: 0) }
            let replaced = content.replacingOccurrences(of: query, with: replacement)
            return StringResult(newContent: replaced, count: count)
        } else {
            // Case-insensitive: walk via NSRegularExpression on an escaped pattern.
            let escaped = NSRegularExpression.escapedPattern(for: query)
            guard let regex = try? NSRegularExpression(pattern: escaped, options: [.caseInsensitive]) else {
                return StringResult(newContent: content, count: 0)
            }
            let nsContent = content as NSString
            let range = NSRange(location: 0, length: nsContent.length)
            let count = regex.numberOfMatches(in: content, range: range)
            if count == 0 { return StringResult(newContent: content, count: 0) }
            // Escape `$` etc in replacement template.
            let template = NSRegularExpression.escapedTemplate(for: replacement)
            let replaced = regex.stringByReplacingMatches(in: content, range: range, withTemplate: template)
            return StringResult(newContent: replaced, count: count)
        }
    }

    /// Apply find/replace to a list of (index, content) pairs, only operating on
    /// indices listed in `slideIndices` (or all if nil). Returns updates suitable
    /// for `Presentation.bulkUpdateSlides`, plus aggregate counts.
    public struct SlideResult: Sendable {
        public let updates: [BulkSlideUpdate]
        public let totalReplacements: Int
        public let affectedSlides: [Int]

        public init(updates: [BulkSlideUpdate], totalReplacements: Int, affectedSlides: [Int]) {
            self.updates = updates
            self.totalReplacements = totalReplacements
            self.affectedSlides = affectedSlides
        }
    }

    public static func apply(
        to slides: [(index: Int, content: String)],
        query: String,
        replacement: String,
        slideIndices: [Int]?,
        caseSensitive: Bool
    ) -> SlideResult {
        var updates: [BulkSlideUpdate] = []
        var totalReplacements = 0
        var affected: [Int] = []
        let allowed: Set<Int>? = slideIndices.map { Set($0) }
        for slide in slides {
            if let allowed, !allowed.contains(slide.index) { continue }
            let result = replace(in: slide.content, query: query, replacement: replacement, caseSensitive: caseSensitive)
            if result.count > 0 {
                updates.append(BulkSlideUpdate(index: slide.index, content: result.newContent))
                totalReplacements += result.count
                affected.append(slide.index)
            }
        }
        return SlideResult(updates: updates, totalReplacements: totalReplacements, affectedSlides: affected)
    }

    private static func countOccurrences(of needle: String, in haystack: String, caseSensitive: Bool) -> Int {
        guard !needle.isEmpty else { return 0 }
        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        var count = 0
        var searchStart = haystack.startIndex
        while let range = haystack.range(of: needle, options: options, range: searchStart..<haystack.endIndex) {
            count += 1
            searchStart = range.upperBound
        }
        return count
    }
}
