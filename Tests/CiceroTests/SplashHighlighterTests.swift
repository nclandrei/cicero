import Testing
import Foundation
@testable import Shared

// Tests for the Splash highlighter's language-hint handling.
//
// Splash is a Swift-only tokenizer (JohnSundell/Splash). Before this fix, the
// SplashCodeSyntaxHighlighter blindly tokenized every code fence as Swift,
// regardless of the fence's language hint. The decision logic now lives in
// Shared so we can verify it from this (Shared-only) test target without
// having to import the Cicero executable target.
//
// Three behaviors must hold:
//   1. A ```swift fence applies Splash tokenization.
//   2. A ```python (or other non-Swift) fence does NOT apply Swift tokens —
//      it renders as plain styled text instead.
//   3. An un-languaged fence still applies Splash so that plain tokens pick up
//      the theme's plainTextColor (rather than falling back to bare Text with
//      a system default color, as the previous bug did).
@Suite("SplashHighlighter — fence language handling")
struct SplashHighlighterTests {

    @Test("Swift fence applies Splash tokenization")
    func swiftFence_appliesSplashTokenization() {
        #expect(CodeFenceLanguageMode.mode(for: "swift") == .swift)
        #expect(CodeFenceLanguageMode.mode(for: "Swift") == .swift)
        #expect(CodeFenceLanguageMode.mode(for: "SWIFT") == .swift)
        // Tolerate surrounding whitespace from the fence info string.
        #expect(CodeFenceLanguageMode.mode(for: "  swift  ") == .swift)
    }

    @Test("Python fence does not apply Swift tokens (renders plain styled text)")
    func pythonFence_doesNotApplySwiftTokens() {
        #expect(CodeFenceLanguageMode.mode(for: "python") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "Python") == .plain)
    }

    @Test("Other non-Swift fences (js, ruby, go) render as plain styled text")
    func otherFences_renderAsPlainStyled() {
        #expect(CodeFenceLanguageMode.mode(for: "js") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "javascript") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "ruby") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "go") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "rust") == .plain)
        #expect(CodeFenceLanguageMode.mode(for: "typescript") == .plain)
    }

    @Test("Un-languaged fence still routes through Splash so theme.plainTextColor applies")
    func unlanguagedFence_usesThemePlainTextColor() {
        // nil and empty/whitespace-only language strings should both fall through
        // to the Splash path. Splash's TextOutputFormat.Builder colors plain
        // tokens with theme.plainTextColor, so this is what restores the lost
        // theme styling for un-languaged fences.
        #expect(CodeFenceLanguageMode.mode(for: nil) == .swift)
        #expect(CodeFenceLanguageMode.mode(for: "") == .swift)
        #expect(CodeFenceLanguageMode.mode(for: "   ") == .swift)
    }
}
