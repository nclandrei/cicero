import Testing
import Foundation

/// Structural test that asserts the `VideoLayoutView` body content is rendered
/// through MarkdownUI (`Markdown(...)`) rather than as a literal `Text(...)` view.
///
/// ## Why a source-inspection test
///
/// The `CiceroTests` target only depends on `Shared` (see `Package.swift`), so it
/// cannot `@testable import Cicero` to instantiate the SwiftUI view directly,
/// nor reflect over its body. SwiftUI views are also notoriously opaque to
/// runtime inspection without third-party frameworks like ViewInspector, which
/// is not a dependency here.
///
/// Snapshot-testing the rendered view would require either booting an NSWindow
/// in headless tests (flaky, slow) or vending out the view to a non-SwiftUI
/// pipeline. Both options are far heavier than the bug requires.
///
/// The bug is mechanical: the wrong view type (`Text`) is used to display the
/// slide body, which prints raw markdown source instead of parsed markdown
/// elements. Asserting the source file uses `Markdown(content)` for the body
/// — and not `Text(content)` — gives a real, deterministic signal that
/// catches the bug and verifies the fix, at the cost of being a structural
/// test instead of a behavioral one.
@Suite("Video Layout Markdown Rendering")
struct VideoLayoutMarkdownTests {

    @Test("VideoLayoutView renders body via Markdown, not Text")
    func videoLayoutUsesMarkdown() throws {
        let source = try readSource(named: "VideoPlayerView.swift")

        // Locate the VideoLayoutView struct body specifically. The file also
        // contains InlineVideoPlayerView, which we don't care about here.
        let videoLayoutBody = try sliceStruct(named: "VideoLayoutView", in: source)

        // The body content (the slide markdown) must flow through MarkdownUI.
        #expect(
            videoLayoutBody.contains("Markdown(content)"),
            "VideoLayoutView must render `content` as parsed markdown via `Markdown(content)`."
        )

        // The literal `Text(content)` would render bullets/bold/etc as raw text.
        #expect(
            !videoLayoutBody.contains("Text(content)"),
            "VideoLayoutView must not render `content` as `Text(content)` — that prints markdown literally instead of parsing it."
        )

        // Sanity: the file should import MarkdownUI to use Markdown(...).
        #expect(
            source.contains("import MarkdownUI"),
            "VideoPlayerView.swift must import MarkdownUI to render the body."
        )
    }

    // MARK: - Helpers

    /// Read a source file from `Sources/Cicero/Views/` relative to this test file.
    private func readSource(named filename: String, file: StaticString = #filePath) throws -> String {
        let testFileURL = URL(fileURLWithPath: String(describing: file))
        // Tests/CiceroTests/<this>.swift -> repo root is two parents up.
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

    /// Extract the textual span of a Swift struct declaration by matching braces.
    /// Naive but adequate: we control the source files under test.
    private func sliceStruct(named name: String, in source: String) throws -> String {
        guard let declRange = source.range(of: "struct \(name)") else {
            throw StructNotFound(name: name)
        }
        // Find the opening brace after the struct declaration.
        guard let openBrace = source.range(of: "{", range: declRange.upperBound..<source.endIndex) else {
            throw StructNotFound(name: name)
        }
        // Walk the source counting braces until we hit zero.
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
