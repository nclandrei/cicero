import Foundation
import Testing

// The README's "<n> MCP tools" headline is the user-visible source of truth
// for how many tools an agent can call. It used to drift behind the real
// count in `Sources/CiceroMCP/Tools.swift`, so this test pins the two
// together: any new tool definition must be reflected in the README.
@Suite("MCP tool count")
struct MCPToolCountTests {

    private static let repoRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // CiceroTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // <repo root>
    }()

    /// Counts top-level `Tool(` definitions in CiceroMCP/Tools.swift. Tools
    /// are declared as a static array of `Tool(...)` literals, so a simple
    /// occurrence count is a faithful proxy for the exposed surface.
    private static func actualToolCount() throws -> Int {
        let url = Self.repoRoot
            .appendingPathComponent("Sources/CiceroMCP/Tools.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        return source.components(separatedBy: "Tool(").count - 1
    }

    /// Extracts the integer N from the README bullet "- **N MCP tools**".
    private static func readmeAdvertisedCount() throws -> Int {
        let url = Self.repoRoot.appendingPathComponent("README.md")
        let readme = try String(contentsOf: url, encoding: .utf8)
        let pattern = #"\*\*(\d+) MCP tools\*\*"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(readme.startIndex..., in: readme)
        guard
            let match = regex.firstMatch(in: readme, range: range),
            match.numberOfRanges >= 2,
            let captured = Range(match.range(at: 1), in: readme),
            let value = Int(readme[captured])
        else {
            Issue.record("README.md does not contain a '**<N> MCP tools**' bullet")
            return -1
        }
        return value
    }

    @Test("README's MCP tool count matches Tools.swift")
    func readmeMatchesActualToolCount() throws {
        let actual = try Self.actualToolCount()
        let advertised = try Self.readmeAdvertisedCount()
        #expect(advertised == actual,
                "README claims \(advertised) MCP tools but Tools.swift defines \(actual). Update README.md.")
    }
}
