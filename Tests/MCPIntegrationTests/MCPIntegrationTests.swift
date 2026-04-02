import Foundation
import Testing

/// Integration tests for the CiceroMCP server over its actual stdio JSON-RPC transport.
///
/// **Prerequisite:** The Cicero app must be running (`swift run Cicero`) as it provides
/// the HTTP backend that CiceroMCP proxies to. Tests skip gracefully if unavailable.
@Suite("MCP Integration", .serialized)
struct MCPIntegrationTests {
    static let client = MCPTestClient()

    // Whether setup has been performed
    static var isSetUp = false

    /// Markdown content with all supported content types for testing.
    static let testMarkdown = """
        ---
        title: Integration Test Deck
        theme: dark
        author: Test Suite
        ---

        # Title Slide

        Welcome to the **integration test** presentation.

        ---

        ## Code Examples

        Swift code:

        ```swift
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }
        ```

        Python code:

        ```python
        def greet(name: str) -> str:
            return f"Hello, {name}!"
        ```

        ---

        ## Lists

        Bullet list:
        - First item
        - Second item
        - Third item

        Numbered list:
        1. Step one
        2. Step two
        3. Step three

        ---

        ## Table Data

        | Language | Year | Creator |
        |----------|------|---------|
        | Swift | 2014 | Apple |
        | Python | 1991 | van Rossum |
        | Rust | 2010 | Hoare |

        ---

        layout: two-column

        ## Two Column Layout

        Left column content with **bold** and *italic* text.

        |||

        Right column content with `inline code` and a [link](https://example.com).

        ---

        ## Rich Formatting

        > This is a blockquote that should be preserved.

        Text with **bold**, *italic*, ~~strikethrough~~, and `inline code`.

        ---

        ## Final Slide

        Thank you for testing!
        """

    // MARK: - Tests

    @Test("Handshake: initialize and verify server info")
    func testHandshake() throws {
        try skipIfNotAvailable()
        try ensureSetUp()

        // The handshake was already done in ensureSetUp, but let's verify
        // by checking status — if handshake failed, this would too
        let response = try Self.client.callTool(name: "get_status")
        let text = try Self.client.extractText(from: response)
        #expect(text.contains("Status:"))
    }

    @Test("List tools: verify all tools present")
    func testListTools() throws {
        try skipIfNotAvailable()
        try ensureSetUp()

        let tools = try Self.client.listTools()

        let expectedTools: Set<String> = [
            "list_slides", "get_slide", "set_slide", "add_slide", "remove_slide",
            "next_slide", "prev_slide", "goto_slide",
            "screenshot_slide", "all_thumbnails",
            "start_presentation", "stop_presentation",
            "get_status", "open_file", "create_presentation",
            "auth_status", "publish_gist", "export_pdf", "export_html", "add_image",
            "list_themes", "get_theme", "set_theme",
        ]

        let toolNames = Set(tools.compactMap { $0["name"] as? String })

        for expected in expectedTools {
            #expect(toolNames.contains(expected), "Missing tool: \(expected)")
        }
        #expect(tools.count >= expectedTools.count,
                "Expected at least \(expectedTools.count) tools, got \(tools.count)")
    }

    @Test("Create presentation with all content types")
    func testCreatePresentation() throws {
        try skipIfNotAvailable()
        try ensureSetUp()

        let response = try Self.client.callTool(
            name: "create_presentation",
            arguments: ["markdown": Self.testMarkdown]
        )
        let text = try Self.client.extractText(from: response)
        #expect(text.lowercased().contains("created"), "Expected creation confirmation, got: \(text)")
    }

    @Test("List slides: verify count and titles")
    func testListSlides() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "list_slides")
        let text = try Self.client.extractText(from: response)

        // We expect 7 slides
        #expect(text.contains("7 slides"), "Expected 7 slides in: \(text)")
        #expect(text.contains("Title Slide"))
        #expect(text.contains("Code Examples"))
        #expect(text.contains("Lists"))
        #expect(text.contains("Table Data"))
        #expect(text.contains("Two Column Layout"))
        #expect(text.contains("Rich Formatting"))
        #expect(text.contains("Final Slide"))
    }

    @Test("Get slide: verify content preserved for each type")
    func testGetSlide() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Slide 0: Title slide
        let slide0 = try Self.client.callTool(name: "get_slide", arguments: ["index": 0])
        let text0 = try Self.client.extractText(from: slide0)
        #expect(text0.contains("Title Slide"))
        #expect(text0.contains("integration test"))

        // Slide 1: Code blocks
        let slide1 = try Self.client.callTool(name: "get_slide", arguments: ["index": 1])
        let text1 = try Self.client.extractText(from: slide1)
        #expect(text1.contains("```swift"))
        #expect(text1.contains("func greet"))
        #expect(text1.contains("```python"))
        #expect(text1.contains("def greet"))

        // Slide 2: Lists
        let slide2 = try Self.client.callTool(name: "get_slide", arguments: ["index": 2])
        let text2 = try Self.client.extractText(from: slide2)
        #expect(text2.contains("- First item"))
        #expect(text2.contains("1. Step one"))

        // Slide 3: Table
        let slide3 = try Self.client.callTool(name: "get_slide", arguments: ["index": 3])
        let text3 = try Self.client.extractText(from: slide3)
        #expect(text3.contains("| Language"))
        #expect(text3.contains("Swift"))
        #expect(text3.contains("Python"))

        // Slide 4: Two-column
        let slide4 = try Self.client.callTool(name: "get_slide", arguments: ["index": 4])
        let text4 = try Self.client.extractText(from: slide4)
        #expect(text4.contains("Two Column"))
        #expect(text4.contains("|||"))

        // Slide 5: Rich formatting
        let slide5 = try Self.client.callTool(name: "get_slide", arguments: ["index": 5])
        let text5 = try Self.client.extractText(from: slide5)
        #expect(text5.contains("blockquote"))
        #expect(text5.contains("**bold**"))
    }

    @Test("Set slide: update and verify")
    func testSetSlide() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let newContent = "# Updated Slide\n\nThis content was updated by the test."

        let setResponse = try Self.client.callTool(
            name: "set_slide",
            arguments: ["index": 0, "content": newContent]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.lowercased().contains("updated"))

        // Read it back
        let getResponse = try Self.client.callTool(name: "get_slide", arguments: ["index": 0])
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.contains("Updated Slide"))
        #expect(getText.contains("updated by the test"))
    }

    @Test("Add and remove slide")
    func testAddAndRemoveSlide() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get initial count
        let before = try Self.client.callTool(name: "list_slides")
        let beforeText = try Self.client.extractText(from: before)
        let initialCount = extractSlideCount(from: beforeText)

        // Add a slide
        let addResponse = try Self.client.callTool(
            name: "add_slide",
            arguments: ["content": "# New Slide\n\nAdded by integration test."]
        )
        let addText = try Self.client.extractText(from: addResponse)
        #expect(addText.lowercased().contains("added"))

        // Verify count increased
        let after = try Self.client.callTool(name: "list_slides")
        let afterText = try Self.client.extractText(from: after)
        let newCount = extractSlideCount(from: afterText)
        #expect(newCount == initialCount + 1, "Expected \(initialCount + 1) slides, got \(newCount)")

        // Remove the last slide
        let removeResponse = try Self.client.callTool(
            name: "remove_slide",
            arguments: ["index": newCount - 1]
        )
        let removeText = try Self.client.extractText(from: removeResponse)
        #expect(removeText.lowercased().contains("removed"))

        // Verify count restored
        let final = try Self.client.callTool(name: "list_slides")
        let finalText = try Self.client.extractText(from: final)
        let finalCount = extractSlideCount(from: finalText)
        #expect(finalCount == initialCount, "Expected \(initialCount) slides after removal, got \(finalCount)")
    }

    @Test("Navigation: next, prev, goto")
    func testNavigation() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Go to first slide
        let goto0 = try Self.client.callTool(name: "goto_slide", arguments: ["index": 0])
        let goto0Text = try Self.client.extractText(from: goto0)
        #expect(goto0Text.contains("slide 1"))

        // Next
        let next = try Self.client.callTool(name: "next_slide")
        let nextText = try Self.client.extractText(from: next)
        #expect(nextText.contains("slide 2"))

        // Next again
        let next2 = try Self.client.callTool(name: "next_slide")
        let next2Text = try Self.client.extractText(from: next2)
        #expect(next2Text.contains("slide 3"))

        // Prev
        let prev = try Self.client.callTool(name: "prev_slide")
        let prevText = try Self.client.extractText(from: prev)
        #expect(prevText.contains("slide 2"))

        // Goto specific
        let goto5 = try Self.client.callTool(name: "goto_slide", arguments: ["index": 4])
        let goto5Text = try Self.client.extractText(from: goto5)
        #expect(goto5Text.contains("slide 5"))
    }

    @Test("Screenshot: capture slide as PNG")
    func testScreenshot() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(
            name: "screenshot_slide",
            arguments: ["index": 0]
        )
        #expect(!Self.client.isErrorResult(response), "Screenshot returned error")
        #expect(Self.client.hasImageContent(in: response), "Expected image content in screenshot")
        // Should have text + image = 2 content items
        #expect(Self.client.contentCount(in: response) >= 2,
                "Expected at least 2 content items (text + image)")
    }

    @Test("Thumbnails: get all slide thumbnails")
    func testThumbnails() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "all_thumbnails")
        #expect(!Self.client.isErrorResult(response), "Thumbnails returned error")

        // Should have 1 text + 7 image items = 8 total
        let count = Self.client.contentCount(in: response)
        #expect(count >= 8, "Expected at least 8 content items (1 text + 7 images), got \(count)")
        #expect(Self.client.hasImageContent(in: response), "Expected image content in thumbnails")
    }

    @Test("Theme operations: list, set, get")
    func testThemeOperations() throws {
        try skipIfNotAvailable()
        try ensureSetUp()

        // List themes
        let listResponse = try Self.client.callTool(name: "list_themes")
        let listText = try Self.client.extractText(from: listResponse)
        #expect(listText.contains("dark"))
        #expect(listText.contains("light"))
        #expect(listText.contains("ocean"))
        #expect(listText.contains("nord"))
        #expect(listText.contains("dracula"))

        // Set theme to ocean
        let setResponse = try Self.client.callTool(
            name: "set_theme",
            arguments: ["name": "ocean"]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.lowercased().contains("ocean"))

        // Get theme — verify it's ocean
        let getResponse = try Self.client.callTool(name: "get_theme")
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.contains("ocean"), "Expected ocean theme, got: \(getText)")

        // Restore dark theme
        _ = try Self.client.callTool(name: "set_theme", arguments: ["name": "dark"])
    }

    @Test("Status: verify fields")
    func testStatus() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "get_status")
        let text = try Self.client.extractText(from: response)

        #expect(text.contains("Status:"))
        #expect(text.contains("Slide:"))
        #expect(text.contains("Presenting:"))
    }

    @Test("Presentation mode: start and stop")
    func testPresentationMode() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Start presentation
        let startResponse = try Self.client.callTool(name: "start_presentation")
        let startText = try Self.client.extractText(from: startResponse)
        #expect(startText.lowercased().contains("started"))

        // Brief pause so the app can enter presentation mode
        Thread.sleep(forTimeInterval: 0.5)

        // Check status — should show presenting
        let statusResponse = try Self.client.callTool(name: "get_status")
        let statusText = try Self.client.extractText(from: statusResponse)
        #expect(statusText.contains("true"), "Expected presenting to be true, got: \(statusText)")

        // Stop presentation
        let stopResponse = try Self.client.callTool(name: "stop_presentation")
        let stopText = try Self.client.extractText(from: stopResponse)
        #expect(stopText.lowercased().contains("stopped"))

        // Brief pause for mode change
        Thread.sleep(forTimeInterval: 0.5)
    }

    @Test("Export HTML: returns valid HTML with reveal.js")
    func testExportHTML() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "export_html")
        let text = try Self.client.extractText(from: response)

        #expect(text.contains("HTML exported successfully"), "Expected export confirmation, got: \(text)")
        #expect(text.contains("7 slides"), "Expected 7 slides in export")
        #expect(text.contains("<!DOCTYPE html>"), "Expected HTML doctype in output")
        #expect(text.contains("reveal.js"), "Expected reveal.js reference in output")
    }

    // MARK: - Helpers

    /// Ensure the MCP client is connected and handshake is done.
    private func ensureSetUp() throws {
        if !Self.isSetUp {
            try Self.client.start()
            let result = try Self.client.handshake()

            // Verify handshake succeeded
            guard let resultObj = result["result"] as? [String: Any],
                  let serverInfo = resultObj["serverInfo"] as? [String: Any],
                  let name = serverInfo["name"] as? String
            else {
                throw MCPTestError.unexpectedResponse("Handshake failed: \(result)")
            }
            #expect(name == "cicero", "Expected server name 'cicero', got '\(name)'")

            Self.isSetUp = true
        }
    }

    /// Skip the test if the Cicero app is not running.
    private func skipIfNotAvailable() throws {
        try #require(MCPTestClient.isCiceroAppRunning(),
                     "Cicero app not running on localhost:19847 — skipping integration tests")
    }

    /// Create (or recreate) the test presentation.
    private func createTestPresentation() throws {
        let response = try Self.client.callTool(
            name: "create_presentation",
            arguments: ["markdown": Self.testMarkdown]
        )
        let text = try Self.client.extractText(from: response)
        guard text.lowercased().contains("created") else {
            throw MCPTestError.serverError("Failed to create test presentation: \(text)")
        }
    }

    /// Extract slide count from list_slides output text (e.g. "7 slides").
    private func extractSlideCount(from text: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)\s+slides?"#),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return 0 }
        return Int(text[range]) ?? 0
    }
}
