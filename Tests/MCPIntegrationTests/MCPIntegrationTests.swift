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
            "reorder_slide", "duplicate_slide", "undo", "redo", "search_slides",
            "set_image_transform",
            "get_font", "set_font", "get_transition", "set_transition",
            "save_file", "get_markdown",
            "get_notes", "set_notes",
            "get_presenter_tool", "set_presenter_tool", "clear_drawings",
            "get_timer", "start_timer", "stop_timer",
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

    @Test("Font operations: get and set font")
    func testFontOperations() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get font — should list available fonts
        let getResponse = try Self.client.callTool(name: "get_font")
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.lowercased().contains("available"), "Expected available fonts list, got: \(getText)")

        // Set font to Georgia
        let setResponse = try Self.client.callTool(
            name: "set_font",
            arguments: ["name": "Georgia"]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.contains("Georgia"), "Expected Georgia in response, got: \(setText)")

        // Get font again — verify it's Georgia
        let getResponse2 = try Self.client.callTool(name: "get_font")
        let getText2 = try Self.client.extractText(from: getResponse2)
        #expect(getText2.contains("Georgia"), "Expected current font Georgia, got: \(getText2)")

        // Reset to system default (no name arg)
        let resetResponse = try Self.client.callTool(
            name: "set_font",
            arguments: [:]
        )
        let resetText = try Self.client.extractText(from: resetResponse)
        #expect(!Self.client.isErrorResult(resetResponse), "Reset font returned error: \(resetText)")
    }

    @Test("Transition operations: get and set transition")
    func testTransitionOperations() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get transition — should list available types
        let getResponse = try Self.client.callTool(name: "get_transition")
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.contains("none"), "Expected 'none' in available transitions, got: \(getText)")
        #expect(getText.contains("fade"), "Expected 'fade' in available transitions, got: \(getText)")
        #expect(getText.contains("slide"), "Expected 'slide' in available transitions, got: \(getText)")
        #expect(getText.contains("push"), "Expected 'push' in available transitions, got: \(getText)")

        // Set transition to fade
        let setResponse = try Self.client.callTool(
            name: "set_transition",
            arguments: ["name": "fade"]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.contains("fade"), "Expected fade in response, got: \(setText)")

        // Get transition — verify it's fade
        let getResponse2 = try Self.client.callTool(name: "get_transition")
        let getText2 = try Self.client.extractText(from: getResponse2)
        #expect(getText2.contains("fade"), "Expected current transition fade, got: \(getText2)")

        // Reset to none
        _ = try Self.client.callTool(
            name: "set_transition",
            arguments: ["name": "none"]
        )
    }

    @Test("Get markdown: full document with frontmatter")
    func testGetMarkdown() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "get_markdown")
        let text = try Self.client.extractText(from: response)

        // Verify it contains frontmatter markers
        #expect(text.contains("---"), "Expected frontmatter markers (---) in markdown, got: \(text)")
        // Verify it contains the title from metadata
        #expect(text.contains("Integration Test Deck"), "Expected title in markdown, got: \(text)")
        // Verify it contains slide content
        #expect(text.contains("Title Slide"), "Expected slide content in markdown, got: \(text)")
    }

    @Test("Status includes metadata fields")
    func testStatusMetadata() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        let response = try Self.client.callTool(name: "get_status")
        let text = try Self.client.extractText(from: response)

        // The test presentation has author: "Test Suite", theme: "dark"
        #expect(text.contains("Test Suite") || text.contains("Author"),
                "Expected author info in status, got: \(text)")
        #expect(text.contains("dark") || text.contains("Theme"),
                "Expected theme info in status, got: \(text)")
    }

    @Test("Duplicate slide: creates copy after original")
    func testDuplicateSlide() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get initial count
        let before = try Self.client.callTool(name: "list_slides")
        let beforeText = try Self.client.extractText(from: before)
        let initialCount = extractSlideCount(from: beforeText)

        // Duplicate slide 0
        let dupResponse = try Self.client.callTool(
            name: "duplicate_slide",
            arguments: ["index": 0]
        )
        let dupText = try Self.client.extractText(from: dupResponse)
        #expect(dupText.lowercased().contains("duplicated"))

        // Verify count increased by 1
        let after = try Self.client.callTool(name: "list_slides")
        let afterText = try Self.client.extractText(from: after)
        let newCount = extractSlideCount(from: afterText)
        #expect(newCount == initialCount + 1, "Expected \(initialCount + 1) slides after duplicate, got \(newCount)")

        // Verify the duplicated slide has same content as original
        let original = try Self.client.callTool(name: "get_slide", arguments: ["index": 0])
        _ = try Self.client.extractText(from: original)
        let copy = try Self.client.callTool(name: "get_slide", arguments: ["index": 1])
        let copyText = try Self.client.extractText(from: copy)
        #expect(copyText.contains("Title Slide"), "Duplicated slide should have same content")
    }

    @Test("Speaker notes: get, set, and remove")
    func testSpeakerNotes() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get notes for slide 0 — should have none initially
        let getResponse = try Self.client.callTool(
            name: "get_notes",
            arguments: ["index": 0]
        )
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.lowercased().contains("no speaker notes") || getText.contains("no notes"),
                "Expected no notes initially, got: \(getText)")

        // Set notes
        let setResponse = try Self.client.callTool(
            name: "set_notes",
            arguments: ["index": 0, "notes": "Remember to greet the audience"]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.contains("Remember to greet the audience"),
                "Expected notes in response, got: \(setText)")

        // Get notes again — verify they're set
        let getResponse2 = try Self.client.callTool(
            name: "get_notes",
            arguments: ["index": 0]
        )
        let getText2 = try Self.client.extractText(from: getResponse2)
        #expect(getText2.contains("Remember to greet the audience"),
                "Expected set notes, got: \(getText2)")

        // Remove notes by passing empty string
        let removeResponse = try Self.client.callTool(
            name: "set_notes",
            arguments: ["index": 0, "notes": ""]
        )
        let removeText = try Self.client.extractText(from: removeResponse)
        #expect(removeText.lowercased().contains("removed"),
                "Expected removal confirmation, got: \(removeText)")

        // Verify notes are gone
        let getResponse3 = try Self.client.callTool(
            name: "get_notes",
            arguments: ["index": 0]
        )
        let getText3 = try Self.client.extractText(from: getResponse3)
        #expect(getText3.lowercased().contains("no"),
                "Expected no notes, got: \(getText3)")
    }

    @Test("Presenter tools: get, set, and clear drawings")
    func testPresenterTools() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get current tool — should be none
        let getResponse = try Self.client.callTool(name: "get_presenter_tool")
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.contains("none"), "Expected no active tool, got: \(getText)")
        #expect(getText.contains("pointer"), "Expected pointer in available list")
        #expect(getText.contains("spotlight"), "Expected spotlight in available list")
        #expect(getText.contains("drawing"), "Expected drawing in available list")

        // Set to pointer
        let setResponse = try Self.client.callTool(
            name: "set_presenter_tool",
            arguments: ["tool": "pointer"]
        )
        let setText = try Self.client.extractText(from: setResponse)
        #expect(setText.contains("pointer"), "Expected pointer confirmation, got: \(setText)")

        // Set to spotlight
        let spotResponse = try Self.client.callTool(
            name: "set_presenter_tool",
            arguments: ["tool": "spotlight"]
        )
        let spotText = try Self.client.extractText(from: spotResponse)
        #expect(spotText.contains("spotlight"), "Expected spotlight, got: \(spotText)")

        // Set to drawing
        let drawResponse = try Self.client.callTool(
            name: "set_presenter_tool",
            arguments: ["tool": "drawing"]
        )
        let drawText = try Self.client.extractText(from: drawResponse)
        #expect(drawText.contains("drawing"), "Expected drawing, got: \(drawText)")

        // Clear drawings
        let clearResponse = try Self.client.callTool(name: "clear_drawings")
        let clearText = try Self.client.extractText(from: clearResponse)
        #expect(clearText.lowercased().contains("cleared"), "Expected cleared confirmation, got: \(clearText)")

        // Reset to none
        let resetResponse = try Self.client.callTool(
            name: "set_presenter_tool",
            arguments: ["tool": "none"]
        )
        let resetText = try Self.client.extractText(from: resetResponse)
        #expect(resetText.contains("none"), "Expected none, got: \(resetText)")
    }

    @Test("Timer: start, check, and stop")
    func testTimer() throws {
        try skipIfNotAvailable()
        try ensureSetUp()
        try createTestPresentation()

        // Get initial timer state — should be stopped
        let getResponse = try Self.client.callTool(name: "get_timer")
        let getText = try Self.client.extractText(from: getResponse)
        #expect(getText.lowercased().contains("stopped"), "Expected timer stopped, got: \(getText)")

        // Start timer
        let startResponse = try Self.client.callTool(name: "start_timer")
        let startText = try Self.client.extractText(from: startResponse)
        #expect(startText.lowercased().contains("started"), "Expected timer started, got: \(startText)")

        // Brief pause to let timer tick
        Thread.sleep(forTimeInterval: 1.5)

        // Get timer — should be running with elapsed > 0
        let checkResponse = try Self.client.callTool(name: "get_timer")
        let checkText = try Self.client.extractText(from: checkResponse)
        #expect(checkText.lowercased().contains("running"), "Expected timer running, got: \(checkText)")

        // Stop timer
        let stopResponse = try Self.client.callTool(name: "stop_timer")
        let stopText = try Self.client.extractText(from: stopResponse)
        #expect(stopText.lowercased().contains("stopped"), "Expected timer stopped, got: \(stopText)")

        // Verify stopped state
        let finalResponse = try Self.client.callTool(name: "get_timer")
        let finalText = try Self.client.extractText(from: finalResponse)
        #expect(finalText.lowercased().contains("stopped"), "Expected timer stopped, got: \(finalText)")
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
