import Testing
import Foundation

/// Structural test that asserts the `EmbedLayoutView` body content is rendered
/// through MarkdownUI (`Markdown(...)`) rather than as a literal `Text(...)` view.
///
/// See `VideoLayoutMarkdownTests` for the rationale on choosing a
/// source-shape assertion over runtime view inspection or snapshot tests:
/// the test target only links Shared, SwiftUI views are opaque without
/// ViewInspector, and the bug is a one-line `Text` → `Markdown` swap.
@Suite("Embed Layout Markdown Rendering")
struct EmbedLayoutMarkdownTests {

    @Test("EmbedLayoutView renders body via Markdown, not Text")
    func embedLayoutUsesMarkdown() throws {
        let source = try readSource(named: "WebEmbedView.swift")

        // Slice out just the EmbedLayoutView struct — the file also contains
        // InlineWebEmbedView and WebEmbedRepresentable.
        let embedLayoutBody = try sliceStruct(named: "EmbedLayoutView", in: source)

        #expect(
            embedLayoutBody.contains("Markdown(content)"),
            "EmbedLayoutView must render `content` as parsed markdown via `Markdown(content)`."
        )

        #expect(
            !embedLayoutBody.contains("Text(content)"),
            "EmbedLayoutView must not render `content` as `Text(content)` — that prints markdown literally instead of parsing it."
        )

        #expect(
            source.contains("import MarkdownUI"),
            "WebEmbedView.swift must import MarkdownUI to render the body."
        )
    }

    // MARK: - Helpers

    private func readSource(named filename: String, file: StaticString = #filePath) throws -> String {
        let testFileURL = URL(fileURLWithPath: String(describing: file))
        let repoRoot = testFileURL
            .deletingLastPathComponent() // CiceroTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // repo root
        let sourceURL = repoRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("Cicero")
            .appendingPathComponent("Views")
            .appendingPathComponent(filename)
        return try String(contentsOf: sourceURL, encoding: .utf8)
    }

    private func sliceStruct(named name: String, in source: String) throws -> String {
        guard let declRange = source.range(of: "struct \(name)") else {
            throw StructNotFound(name: name)
        }
        guard let openBrace = source.range(of: "{", range: declRange.upperBound..<source.endIndex) else {
            throw StructNotFound(name: name)
        }
        var depth = 1
        var idx = openBrace.upperBound
        while idx < source.endIndex {
            let ch = source[idx]
            if ch == "{" {
                depth += 1
            } else if ch == "}" {
                depth -= 1
                if depth == 0 {
                    return String(source[openBrace.upperBound..<idx])
                }
            }
            idx = source.index(after: idx)
        }
        throw StructNotFound(name: name)
    }

    private struct StructNotFound: Error { let name: String }
}
