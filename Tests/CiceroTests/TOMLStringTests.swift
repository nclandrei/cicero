import Foundation
import Testing
@testable import Shared

@Suite("TOMLString")
struct TOMLStringTests {

    @Test("Plain ASCII path is wrapped as a literal string")
    func plainPath() {
        #expect(TOMLString.quote("/usr/local/bin/cicero-mcp") == "'/usr/local/bin/cicero-mcp'")
    }

    @Test("Path with spaces uses literal string verbatim")
    func pathWithSpaces() {
        // The original buggy code used double quotes without escaping;
        // even though spaces themselves are legal in basic strings, this
        // pins the safer literal-string output for the realistic case.
        #expect(TOMLString.quote("/Users/Foo Bar/cicero-mcp") == "'/Users/Foo Bar/cicero-mcp'")
    }

    @Test("Path with backslash uses literal string verbatim (no double-escape)")
    func pathWithBackslash() {
        // Literal strings take backslashes as data — no escape sequences.
        // This mirrors typical Windows-style paths if Codex ever supports them.
        #expect(TOMLString.quote(#"C:\Program Files\Cicero\cicero-mcp"#) == #"'C:\Program Files\Cicero\cicero-mcp'"#)
    }

    @Test("Path with double-quote uses literal string verbatim")
    func pathWithDoubleQuote() {
        // Double quotes are illegal in basic strings without escaping but
        // legal data in literal strings — favour the literal form.
        #expect(TOMLString.quote(#"/odd"path/cicero-mcp"#) == #"'/odd"path/cicero-mcp'"#)
    }

    @Test("Path with single quote falls back to escaped basic string")
    func pathWithSingleQuote() {
        // Single quotes are forbidden in literal strings, so we must
        // switch to a basic string. The single quote itself doesn't need
        // escaping in a basic string, but the wrapping changes.
        let quoted = TOMLString.quote("/Users/o'brien/cicero-mcp")
        #expect(quoted == "\"/Users/o'brien/cicero-mcp\"")
    }

    @Test("Basic-string fallback escapes embedded backslash and double quote")
    func basicEscapesBackslashAndQuote() {
        // Force the basic-string path by including a single quote.
        let quoted = TOMLString.quote("/a'b\\c\"d")
        #expect(quoted == "\"/a'b\\\\c\\\"d\"")
    }

    @Test("Basic-string fallback escapes control characters")
    func basicEscapesControls() {
        let quoted = TOMLString.quote("a'b\nc\td")
        #expect(quoted == "\"a'b\\nc\\td\"")
    }

    @Test("Empty string round-trips as empty literal")
    func emptyString() {
        #expect(TOMLString.quote("") == "''")
    }
}
