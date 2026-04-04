import AppKit
import Splash

/// Applies markdown syntax highlighting to an NSTextView using text storage attributes.
/// Uses Splash for code fence content highlighting.
final class MarkdownHighlighter {
    var isDark: Bool = true
    var baseFont: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    private let splashTokenizer = SyntaxHighlighter(format: TokenRangeFormat())

    /// The default typing attributes (base font + default text color).
    var typingAttributes: [NSAttributedString.Key: Any] {
        let colors = isDark ? Self.darkColors : Self.lightColors
        return [
            .font: baseFont,
            .foregroundColor: colors.text,
        ]
    }

    func highlight(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        guard fullRange.length > 0 else { return }

        let colors = isDark ? Self.darkColors : Self.lightColors
        let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)

        // Begin batch editing
        textStorage.beginEditing()

        // Reset all to default
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: colors.text,
        ], range: fullRange)

        // Track ranges excluded from inline patterns (code fences, frontmatter)
        var excludedRanges: [NSRange] = []

        // 1. YAML frontmatter
        applyFrontmatter(nsText: nsText, storage: textStorage, colors: colors)
        // Collect frontmatter as excluded
        collectFrontmatterRanges(nsText: nsText, excluded: &excludedRanges)

        // 2. Code fences with Splash highlighting
        applyCodeFences(nsText: nsText, storage: textStorage, colors: colors, excluded: &excludedRanges)

        // 3. Slide separators (---)
        applySeparators(nsText: nsText, storage: textStorage, colors: colors, boldFont: boldFont, excluded: excludedRanges)

        // 4. Headings
        applyHeadings(nsText: nsText, storage: textStorage, colors: colors, boldFont: boldFont, excluded: excludedRanges)

        // 5. Layout directives
        applyDirectives(nsText: nsText, storage: textStorage, colors: colors, excluded: excludedRanges)

        // 6. Bold
        applyBold(nsText: nsText, storage: textStorage, boldFont: boldFont, excluded: excludedRanges)

        // 7. Italic
        applyItalic(nsText: nsText, storage: textStorage, excluded: excludedRanges)

        // 8. Inline code
        applyInlineCode(nsText: nsText, storage: textStorage, colors: colors, excluded: excludedRanges)

        // 9. Links
        applyLinks(nsText: nsText, storage: textStorage, colors: colors, excluded: excludedRanges)

        // 10. HTML comments
        applyHTMLComments(nsText: nsText, storage: textStorage, colors: colors, excluded: excludedRanges)

        textStorage.endEditing()

        // Keep typing attributes at baseline so new text doesn't inherit special styling
        textView.typingAttributes = typingAttributes
    }

    // MARK: - Frontmatter

    private static let frontmatterRegex = try! NSRegularExpression(
        pattern: "\\A(---\\n[\\s\\S]*?\\n---)",
        options: []
    )

    private func collectFrontmatterRanges(nsText: NSString, excluded: inout [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.frontmatterRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            excluded.append(range)
        }
    }

    private func applyFrontmatter(nsText: NSString, storage: NSTextStorage, colors: Colors) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.frontmatterRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            storage.addAttribute(.foregroundColor, value: colors.frontmatter, range: range)
        }
    }

    // MARK: - Code fences

    private static let codeFenceRegex = try! NSRegularExpression(
        pattern: "^```(\\w*)\\n([\\s\\S]*?)\\n```$",
        options: [.anchorsMatchLines]
    )

    private func applyCodeFences(nsText: NSString, storage: NSTextStorage, colors: Colors, excluded: inout [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        let splashTheme: Splash.Theme = isDark ? .ciceroDark : .ciceroLight

        Self.codeFenceRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match else { return }
            let fenceRange = match.range
            let codeRange = match.range(at: 2)

            // Color the fence delimiters and language tag
            storage.addAttribute(.foregroundColor, value: colors.codeFence, range: fenceRange)

            // Background for the whole fence
            storage.addAttribute(.backgroundColor, value: colors.codeBackground, range: fenceRange)

            // Apply Splash highlighting to the code content
            if codeRange.location != NSNotFound && codeRange.length > 0 {
                let codeText = nsText.substring(with: codeRange)
                let tokens = self.splashTokenizer.highlight(codeText)
                for (tokenRange, tokenType) in tokens {
                    let adjustedRange = NSRange(
                        location: codeRange.location + tokenRange.location,
                        length: tokenRange.length
                    )
                    guard adjustedRange.location + adjustedRange.length <= nsText.length else { continue }
                    let color: NSColor
                    if let tokenType {
                        color = splashTheme.tokenColors[tokenType] ?? splashTheme.plainTextColor
                    } else {
                        color = splashTheme.plainTextColor
                    }
                    storage.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                }
            }

            excluded.append(fenceRange)
        }
    }

    // MARK: - Slide separators

    private static let separatorRegex = try! NSRegularExpression(
        pattern: "^---$",
        options: [.anchorsMatchLines]
    )

    private func applySeparators(nsText: NSString, storage: NSTextStorage, colors: Colors, boldFont: NSFont, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.separatorRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let range = match?.range, !self.isExcluded(range, by: excluded) else { return }
            storage.addAttribute(.foregroundColor, value: colors.separator, range: range)
            storage.addAttribute(.font, value: boldFont, range: range)
        }
    }

    // MARK: - Headings

    private static let headingRegex = try! NSRegularExpression(
        pattern: "^(#{1,6})\\s+(.+)$",
        options: [.anchorsMatchLines]
    )

    private func applyHeadings(nsText: NSString, storage: NSTextStorage, colors: Colors, boldFont: NSFont, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.headingRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            let hashRange = match.range(at: 1)
            let textRange = match.range(at: 2)
            storage.addAttribute(.foregroundColor, value: colors.headingMarker, range: hashRange)
            storage.addAttribute(.foregroundColor, value: colors.heading, range: textRange)
            storage.addAttribute(.font, value: boldFont, range: textRange)
        }
    }

    // MARK: - Layout directives

    private static let directiveRegex = try! NSRegularExpression(
        pattern: "^(layout|image|video|embed):\\s*(.+)$",
        options: [.anchorsMatchLines]
    )

    private func applyDirectives(nsText: NSString, storage: NSTextStorage, colors: Colors, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.directiveRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            let keyRange = match.range(at: 1)
            let valueRange = match.range(at: 2)
            storage.addAttribute(.foregroundColor, value: colors.directiveKey, range: keyRange)
            storage.addAttribute(.foregroundColor, value: colors.directiveValue, range: valueRange)
        }
    }

    // MARK: - Bold

    private static let boldRegex = try! NSRegularExpression(
        pattern: "\\*\\*(.+?)\\*\\*",
        options: []
    )

    private func applyBold(nsText: NSString, storage: NSTextStorage, boldFont: NSFont, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.boldRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            storage.addAttribute(.font, value: boldFont, range: match.range)
        }
    }

    // MARK: - Italic

    private static let italicRegex = try! NSRegularExpression(
        pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)",
        options: []
    )

    private func applyItalic(nsText: NSString, storage: NSTextStorage, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        let italicFont: NSFont = {
            let descriptor = self.baseFont.fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: self.baseFont.pointSize) ?? self.baseFont
        }()
        Self.italicRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            storage.addAttribute(.font, value: italicFont, range: match.range)
        }
    }

    // MARK: - Inline code

    private static let inlineCodeRegex = try! NSRegularExpression(
        pattern: "(?<!`)`(?!`)([^`]+)`(?!`)",
        options: []
    )

    private func applyInlineCode(nsText: NSString, storage: NSTextStorage, colors: Colors, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.inlineCodeRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            storage.addAttribute(.foregroundColor, value: colors.inlineCode, range: match.range)
            storage.addAttribute(.backgroundColor, value: colors.codeBackground, range: match.range)
        }
    }

    // MARK: - Links

    private static let linkRegex = try! NSRegularExpression(
        pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)",
        options: []
    )

    private func applyLinks(nsText: NSString, storage: NSTextStorage, colors: Colors, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.linkRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let match, !self.isExcluded(match.range, by: excluded) else { return }
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            storage.addAttribute(.foregroundColor, value: colors.linkText, range: textRange)
            storage.addAttribute(.foregroundColor, value: colors.linkURL, range: urlRange)
        }
    }

    // MARK: - HTML comments

    private static let htmlCommentRegex = try! NSRegularExpression(
        pattern: "<!--[\\s\\S]*?-->",
        options: []
    )

    private func applyHTMLComments(nsText: NSString, storage: NSTextStorage, colors: Colors, excluded: [NSRange]) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        Self.htmlCommentRegex.enumerateMatches(in: nsText as String, range: fullRange) { match, _, _ in
            guard let range = match?.range, !self.isExcluded(range, by: excluded) else { return }
            storage.addAttribute(.foregroundColor, value: colors.comment, range: range)
        }
    }

    // MARK: - Helpers

    private func isExcluded(_ range: NSRange, by excludedRanges: [NSRange]) -> Bool {
        for excluded in excludedRanges {
            if NSIntersectionRange(range, excluded).length > 0 { return true }
        }
        return false
    }

    // MARK: - Color definitions

    struct Colors {
        let text: NSColor
        let heading: NSColor
        let headingMarker: NSColor
        let separator: NSColor
        let codeFence: NSColor
        let codeBackground: NSColor
        let inlineCode: NSColor
        let linkText: NSColor
        let linkURL: NSColor
        let frontmatter: NSColor
        let directiveKey: NSColor
        let directiveValue: NSColor
        let comment: NSColor
    }

    static let darkColors = Colors(
        text: NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1),
        heading: NSColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1),
        headingMarker: NSColor(red: 0.45, green: 0.55, blue: 0.7, alpha: 1),
        separator: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1),
        codeFence: NSColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1),
        codeBackground: NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1),
        inlineCode: NSColor(red: 0.82, green: 0.58, blue: 1.0, alpha: 1),
        linkText: NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),
        linkURL: NSColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1),
        frontmatter: NSColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1),
        directiveKey: NSColor(red: 0.82, green: 0.58, blue: 1.0, alpha: 1),
        directiveValue: NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1),
        comment: NSColor(red: 0.42, green: 0.47, blue: 0.52, alpha: 1)
    )

    static let lightColors = Colors(
        text: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1),
        heading: NSColor(red: 0.1, green: 0.35, blue: 0.7, alpha: 1),
        headingMarker: NSColor(red: 0.35, green: 0.5, blue: 0.7, alpha: 1),
        separator: NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1),
        codeFence: NSColor(red: 0.45, green: 0.5, blue: 0.55, alpha: 1),
        codeBackground: NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1),
        inlineCode: NSColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),
        linkText: NSColor(red: 0.1, green: 0.4, blue: 0.7, alpha: 1),
        linkURL: NSColor(red: 0.45, green: 0.5, blue: 0.55, alpha: 1),
        frontmatter: NSColor(red: 0.45, green: 0.5, blue: 0.55, alpha: 1),
        directiveKey: NSColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),
        directiveValue: NSColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1),
        comment: NSColor(red: 0.55, green: 0.6, blue: 0.65, alpha: 1)
    )
}

// MARK: - Splash TokenRangeFormat

/// Output format that collects token ranges and types for applying to NSTextView
struct TokenRangeFormat: OutputFormat {
    func makeBuilder() -> Builder { Builder() }
}

extension TokenRangeFormat {
    struct Builder: OutputBuilder {
        private(set) var tokens: [(NSRange, TokenType?)] = []
        private var offset = 0

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let len = (token as NSString).length
            tokens.append((NSRange(location: offset, length: len), type))
            offset += len
        }

        mutating func addPlainText(_ text: String) {
            let len = (text as NSString).length
            tokens.append((NSRange(location: offset, length: len), nil))
            offset += len
        }

        mutating func addWhitespace(_ whitespace: String) {
            offset += (whitespace as NSString).length
        }

        func build() -> [(NSRange, TokenType?)] { tokens }
    }
}
