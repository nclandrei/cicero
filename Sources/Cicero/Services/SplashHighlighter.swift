import SwiftUI
import MarkdownUI
import Splash

/// Bridges Splash syntax highlighting into MarkdownUI's CodeSyntaxHighlighter protocol
struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>

    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        guard language != nil else {
            return Text(content)
        }
        return syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}

// MARK: - TextOutputFormat for SwiftUI Text output

struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme

    init(theme: Splash.Theme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        Builder(theme: theme)
    }
}

extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text]

        fileprivate init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = theme.tokenColors[type] ?? theme.plainTextColor
            accumulatedText.append(Text(token).foregroundColor(Color(nsColor: color)))
        }

        mutating func addPlainText(_ text: String) {
            accumulatedText.append(
                Text(text).foregroundColor(Color(nsColor: theme.plainTextColor))
            )
        }

        mutating func addWhitespace(_ whitespace: String) {
            accumulatedText.append(Text(whitespace))
        }

        func build() -> Text {
            accumulatedText.reduce(Text(""), +)
        }
    }
}

// MARK: - Splash themes matching our SlideTheme

extension Splash.Theme {
    static let ciceroDark = Splash.Theme(
        font: .init(size: 16),
        plainTextColor: .init(red: 0.89, green: 0.91, blue: 0.94, alpha: 1), // #e2e8f0
        tokenColors: [
            .keyword: .init(red: 0.82, green: 0.58, blue: 1.0, alpha: 1),    // purple
            .string: .init(red: 0.6, green: 0.9, blue: 0.6, alpha: 1),       // green
            .type: .init(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),         // cyan
            .call: .init(red: 1.0, green: 0.82, blue: 0.47, alpha: 1),       // yellow
            .number: .init(red: 0.82, green: 0.58, blue: 1.0, alpha: 1),     // purple
            .comment: .init(red: 0.5, green: 0.55, blue: 0.6, alpha: 1),     // gray
            .property: .init(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),     // cyan
            .dotAccess: .init(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),    // cyan
            .preprocessing: .init(red: 1.0, green: 0.62, blue: 0.47, alpha: 1), // orange
        ]
    )

    static let ciceroLight = Splash.Theme(
        font: .init(size: 16),
        plainTextColor: .init(red: 0.2, green: 0.25, blue: 0.33, alpha: 1),  // #334155
        tokenColors: [
            .keyword: .init(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),   // purple
            .string: .init(red: 0.13, green: 0.55, blue: 0.13, alpha: 1),    // green
            .type: .init(red: 0.1, green: 0.4, blue: 0.7, alpha: 1),         // blue
            .call: .init(red: 0.65, green: 0.45, blue: 0.1, alpha: 1),       // gold
            .number: .init(red: 0.1, green: 0.4, blue: 0.7, alpha: 1),       // blue
            .comment: .init(red: 0.45, green: 0.5, blue: 0.55, alpha: 1),    // gray
            .property: .init(red: 0.1, green: 0.4, blue: 0.7, alpha: 1),     // blue
            .dotAccess: .init(red: 0.1, green: 0.4, blue: 0.7, alpha: 1),    // blue
            .preprocessing: .init(red: 0.65, green: 0.35, blue: 0.1, alpha: 1), // orange
        ]
    )
}
