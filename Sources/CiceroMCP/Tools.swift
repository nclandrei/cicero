import Foundation
import MCP
import Shared

/// All Cicero MCP tool definitions
enum CiceroTools {
    static let all: [Tool] = [
        // MARK: - Slide CRUD

        Tool(
            name: "list_slides",
            description: "List all slides with their titles and content",
            inputSchema: .object([
                "type": "object",
                "properties": .object([:]),
            ]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "get_slide",
            description: "Get the markdown content of a specific slide",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_slide",
            description: "Update the content of a specific slide. Supports per-slide layout frontmatter at the top: 'layout: title|two-column|image-left|image-right|video|embed', 'image: URL', 'video: URL' (for layout: video), 'embed: URL' (for layout: embed). Use '|||' to separate columns in two-column layout. Add speaker notes at the end with '<!-- notes\\n...\\n-->'.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                    "content": .object(["type": "string", "description": "New markdown content for the slide. Add 'layout: <type>' as the first line for layout. Use '|||' to separate columns in two-column layout."]),
                ]),
                "required": .array([.string("index"), .string("content")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "add_slide",
            description: "Add a new slide to the presentation. Supports per-slide layout frontmatter: 'layout: title|two-column|image-left|image-right|video|embed', 'image: URL', 'video: URL', 'embed: URL' as first lines. Add speaker notes at the end with '<!-- notes\\n...\\n-->'.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "content": .object(["type": "string", "description": "Markdown content for the new slide. Add 'layout: <type>' as the first line for layout."]),
                    "after_index": .object(["type": "integer", "description": "Insert after this slide index. Omit to append at end."]),
                ]),
                "required": .array([.string("content")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "remove_slide",
            description: "Remove a slide from the presentation",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index to remove (0-based)"]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "reorder_slide",
            description: "Move a slide from one position to another (0-based indices)",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "from": .object(["type": "integer", "description": "Source slide index (0-based)"]),
                    "to": .object(["type": "integer", "description": "Destination slide index (0-based)"]),
                ]),
                "required": .array([.string("from"), .string("to")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        Tool(
            name: "duplicate_slide",
            description: "Duplicate a slide, inserting the copy immediately after the original",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index to duplicate (0-based)"]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),

        // MARK: - Navigation

        Tool(
            name: "next_slide",
            description: "Navigate to the next slide",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "prev_slide",
            description: "Navigate to the previous slide",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "goto_slide",
            description: "Navigate to a specific slide by index",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Screenshots

        Tool(
            name: "screenshot_slide",
            description: "Capture a rendered screenshot of a slide as PNG",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based). Omit for current slide."]),
                    "save_path": .object(["type": "string", "description": "Optional absolute file path to save the PNG to disk. If omitted, the image is returned inline only."]),
                ]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "all_thumbnails",
            description: "Get thumbnail images of all slides as base64 PNGs",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),

        // MARK: - Presentation mode

        Tool(
            name: "start_presentation",
            description: "Enter fullscreen presentation mode",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "stop_presentation",
            description: "Exit presentation mode",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Status & files

        Tool(
            name: "get_status",
            description: "Get the current state of the presentation (current slide, mode, file path)",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "open_file",
            description: "Open a markdown file as a presentation",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "path": .object(["type": "string", "description": "Absolute path to the .md file"]),
                ]),
                "required": .array([.string("path")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "create_presentation",
            description: "Create a new presentation from markdown content. Use --- to separate slides. Optionally include YAML frontmatter for title/theme/author.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "markdown": .object(["type": "string", "description": "Full markdown content including slide separators (---)"]),
                ]),
                "required": .array([.string("markdown")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - GitHub

        Tool(
            name: "auth_status",
            description: "Check GitHub authentication status",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "publish_gist",
            description: "Share the current presentation online and get a shareable link. Publishes as a GitHub Gist. Will prompt for GitHub sign-in if needed.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "public": .object(["type": "boolean", "description": "Whether the gist should be public (default: false)"]),
                ]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: true)
        ),

        // MARK: - Export

        Tool(
            name: "export_pdf",
            description: "Export the current presentation as a multi-page PDF. If output_path is provided, the PDF is written to that file and the absolute path is returned. Otherwise the base64-encoded PDF data is returned inline.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "output_path": .object(["type": "string", "description": "Optional absolute file path to write the PDF to. Parent directories are created as needed. If omitted, returns the base64 PDF data inline."]),
                ]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Images

        Tool(
            name: "add_image",
            description: "Add an image to the presentation assets. Returns a markdown snippet to insert into a slide.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "base64_data": .object(["type": "string", "description": "Base64-encoded image data (PNG, JPEG, GIF, or TIFF)"]),
                    "name": .object(["type": "string", "description": "Optional name for the image file (without extension)"]),
                ]),
                "required": .array([.string("base64_data")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_image_transform",
            description: "Move or resize a positioned image on a slide. Coordinates (x, y, width) are in the 960×540 reference space. Each parameter is optional — omitted values are left unchanged.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "slide_index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                    "path": .object(["type": "string", "description": "Image path as it appears in the markdown (e.g. 'assets/image-1.png')"]),
                    "x": .object(["type": "number", "description": "Horizontal offset in the 960×540 reference space (pixels from left edge)"]),
                    "y": .object(["type": "number", "description": "Vertical offset in the 960×540 reference space (pixels from top edge)"]),
                    "width": .object(["type": "number", "description": "Image width in the 960×540 reference space (pixels)"]),
                ]),
                "required": .array([.string("slide_index"), .string("path")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Presenter tools

        Tool(
            name: "get_presenter_tool",
            description: "Get the active presenter tool and list of available tools (none, pointer, spotlight, drawing)",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_presenter_tool",
            description: "Activate a presenter tool during presentation mode. Use 'none' to deactivate all tools.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "tool": .object(["type": "string", "description": "Tool to activate: none, pointer, spotlight, or drawing"]),
                ]),
                "required": .array([.string("tool")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "clear_drawings",
            description: "Clear all drawing strokes made with the drawing presenter tool",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Theming

        Tool(
            name: "list_themes",
            description: "List all available built-in themes with their color definitions",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "get_theme",
            description: "Get the current presentation theme name and color definition",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_theme",
            description: "Set the presentation theme. Use a built-in name (dark, light, ocean, forest, sunset, minimal, solarized-dark, solarized-light, nord, dracula) or 'custom' with hex colors.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "name": .object(["type": "string", "description": "Theme name: a built-in theme name, 'auto', or 'custom'"]),
                    "background": .object(["type": "string", "description": "Hex background color (required for custom theme, e.g. '#1a1a2e')"]),
                    "text": .object(["type": "string", "description": "Hex text color"]),
                    "heading": .object(["type": "string", "description": "Hex heading color"]),
                    "accent": .object(["type": "string", "description": "Hex accent color"]),
                    "code_background": .object(["type": "string", "description": "Hex code block background color"]),
                    "code_text": .object(["type": "string", "description": "Hex code block text color"]),
                ]),
                "required": .array([.string("name")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Font

        Tool(
            name: "get_font",
            description: "Get the current font and list of available font families",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_font",
            description: "Set the presentation font family. Omit or pass null for system default.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "name": .object(["type": "string", "description": "Font family name (e.g. 'Georgia', 'SF Mono'). Omit for system default."]),
                ]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Transition

        Tool(
            name: "get_transition",
            description: "Get the current slide transition and list of available transition types",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_transition",
            description: "Set the slide transition type used in presentation mode",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "name": .object(["type": "string", "description": "Transition type: none, fade, slide, or push"]),
                ]),
                "required": .array([.string("name")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Timer

        Tool(
            name: "get_timer",
            description: "Get the presentation timer state (running, elapsed seconds, wall clock)",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "start_timer",
            description: "Start (or restart) the presentation timer. Resets elapsed time to zero.",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "stop_timer",
            description: "Stop the presentation timer and reset elapsed time to zero.",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - Save & markdown

        Tool(
            name: "save_file",
            description: "Save the current presentation to disk. Requires a file path (opened or previously saved).",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
        Tool(
            name: "get_markdown",
            description: "Get the full raw markdown of the presentation including YAML frontmatter, all slides, and separators",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),

        // MARK: - Undo/redo

        Tool(
            name: "undo",
            description: "Undo the last edit to the presentation",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),
        Tool(
            name: "redo",
            description: "Redo the last undone edit to the presentation",
            inputSchema: .object(["type": "object", "properties": .object([:])]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false)
        ),

        // MARK: - Search

        Tool(
            name: "search_slides",
            description: "Search across all slides for a text query. Returns matching slides with excerpts showing context around each match.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "query": .object(["type": "string", "description": "Text to search for (case-insensitive)"]),
                ]),
                "required": .array([.string("query")]),
            ]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),

        // MARK: - Speaker Notes

        Tool(
            name: "get_notes",
            description: "Get the speaker notes for a specific slide",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: true, destructiveHint: false, openWorldHint: false)
        ),
        Tool(
            name: "set_notes",
            description: "Set or remove speaker notes for a specific slide. Pass notes text to set, or null/empty to remove notes.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                    "notes": .object(["type": "string", "description": "Speaker notes text. Omit or pass empty string to remove notes."]),
                ]),
                "required": .array([.string("index")]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),

        // MARK: - HTML export

        Tool(
            name: "export_html",
            description: "Export the current presentation as a self-contained HTML file using reveal.js. The HTML works in any browser with theming, layouts, code highlighting, and speaker notes.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "output_path": .object(["type": "string", "description": "Optional file path to write the HTML to. If omitted, returns the HTML content."]),
                ]),
            ]),
            annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
        ),
    ]
}

/// Execute a tool call by proxying to the Cicero app's HTTP API
enum CiceroToolHandler {
    static func handle(
        name: String,
        arguments: [String: Value]?,
        client: AppClient
    ) async throws -> CallTool.Result {
        switch name {
        case "list_slides":
            let resp: SlidesResponse = try await client.get("/slides")
            var text = "Presentation: \(resp.count) slides (currently on slide \(resp.currentIndex + 1))\n\n"
            for slide in resp.slides {
                let title = slide.title ?? "(untitled)"
                let layoutBadge = slide.layout.map { " [\($0)]" } ?? ""
                text += "[\(slide.index + 1)] \(title)\(layoutBadge)\n"
            }
            return textResult(text)

        case "get_slide":
            let index = arguments?["index"]?.intValue ?? 0
            let resp: SlideInfo = try await client.get("/slides/\(index)")
            var text = resp.content
            if let notes = resp.notes {
                text += "\n\nNotes: \(notes)"
            }
            return textResult(text)

        case "set_slide":
            let index = arguments?["index"]?.intValue ?? 0
            let content = arguments?["content"]?.stringValue ?? ""
            let _: SuccessResponse = try await client.put(
                "/slides/\(index)",
                body: UpdateSlideRequest(content: content)
            )
            return textResult("Slide \(index + 1) updated.")

        case "add_slide":
            let content = arguments?["content"]?.stringValue ?? ""
            let afterIndex = arguments?["after_index"]?.intValue
            let _: SuccessResponse = try await client.post(
                "/slides",
                body: AddSlideRequest(content: content, afterIndex: afterIndex)
            )
            return textResult("Slide added.")

        case "remove_slide":
            let index = arguments?["index"]?.intValue ?? 0
            let _: SuccessResponse = try await client.delete("/slides/\(index)")
            return textResult("Slide \(index + 1) removed.")

        case "reorder_slide":
            let from = arguments?["from"]?.intValue ?? 0
            let to = arguments?["to"]?.intValue ?? 0
            let _: SuccessResponse = try await client.post(
                "/slides/reorder",
                body: ReorderRequest(from: from, to: to)
            )
            return textResult("Moved slide from position \(from + 1) to \(to + 1).")

        case "duplicate_slide":
            let index = arguments?["index"]?.intValue ?? 0
            let _: SuccessResponse = try await client.postEmpty("/slides/\(index)/duplicate")
            return textResult("Slide \(index + 1) duplicated.")

        case "next_slide":
            let resp: NavigateResponse = try await client.post(
                "/navigate", body: NavigateRequest(action: "next")
            )
            return textResult("Now on slide \(resp.currentIndex + 1) of \(resp.totalSlides).")

        case "prev_slide":
            let resp: NavigateResponse = try await client.post(
                "/navigate", body: NavigateRequest(action: "prev")
            )
            return textResult("Now on slide \(resp.currentIndex + 1) of \(resp.totalSlides).")

        case "goto_slide":
            let index = arguments?["index"]?.intValue ?? 0
            let resp: NavigateResponse = try await client.post(
                "/navigate", body: NavigateRequest(action: "goto", index: index)
            )
            return textResult("Now on slide \(resp.currentIndex + 1) of \(resp.totalSlides).")

        case "screenshot_slide":
            let path: String
            if let index = arguments?["index"]?.intValue {
                path = "/screenshot/\(index)"
            } else {
                path = "/screenshot"
            }
            let resp: ScreenshotResponse = try await client.get(path)
            var savedMessage = ""
            if let savePath = arguments?["save_path"]?.stringValue, !savePath.isEmpty {
                if let pngData = Data(base64Encoded: resp.base64PNG) {
                    let url = URL(fileURLWithPath: savePath)
                    try pngData.write(to: url)
                    savedMessage = " (saved to \(savePath))"
                }
            }
            return .init(
                content: [
                    .text(text: "Screenshot of slide \(resp.slideIndex + 1)\(savedMessage)", annotations: nil, _meta: nil),
                    .image(data: resp.base64PNG, mimeType: "image/png", annotations: nil, _meta: nil),
                ],
                isError: false
            )

        case "all_thumbnails":
            let resp: ThumbnailsResponse = try await client.get("/thumbnails")
            var content: [Tool.Content] = [
                .text(text: "Thumbnails for \(resp.thumbnails.count) slides:", annotations: nil, _meta: nil)
            ]
            for thumb in resp.thumbnails {
                content.append(.image(data: thumb.base64PNG, mimeType: "image/png", annotations: nil, _meta: nil))
            }
            return .init(content: content, isError: false)

        case "start_presentation":
            let _: SuccessResponse = try await client.postEmpty("/presentation/start")
            return textResult("Presentation mode started.")

        case "stop_presentation":
            let _: SuccessResponse = try await client.postEmpty("/presentation/stop")
            return textResult("Presentation mode stopped.")

        case "get_status":
            let resp: StatusResponse = try await client.get("/status")
            var text = "Status:\n"
            text += "  Slide: \(resp.currentSlide + 1) of \(resp.totalSlides)\n"
            text += "  Presenting: \(resp.presenting)\n"
            if let title = resp.title { text += "  Title: \(title)\n" }
            if let author = resp.author { text += "  Author: \(author)\n" }
            if let path = resp.filePath { text += "  File: \(path)\n" }
            if let theme = resp.theme { text += "  Theme: \(theme)\n" }
            if let font = resp.font { text += "  Font: \(font)\n" }
            if let transition = resp.transition { text += "  Transition: \(transition)\n" }
            return textResult(text)

        case "open_file":
            let path = arguments?["path"]?.stringValue ?? ""
            let _: SuccessResponse = try await client.post(
                "/open", body: OpenFileRequest(path: path)
            )
            return textResult("Opened \(path)")

        case "create_presentation":
            let markdown = arguments?["markdown"]?.stringValue ?? ""
            let _: SuccessResponse = try await client.post(
                "/create", body: CreatePresentationRequest(markdown: markdown)
            )
            return textResult("Presentation created from provided markdown.")

        case "auth_status":
            let resp: AuthStatusResponse = try await client.get("/auth/status")
            if resp.authenticated {
                let user = resp.username ?? "unknown"
                return textResult("Authenticated as \(user)")
            } else {
                return textResult("Not authenticated. Sign in to GitHub in the Cicero app to share presentations.")
            }

        case "publish_gist":
            let isPublic = arguments?["public"]?.boolValue ?? false
            let resp: PublishGistResponse = try await client.post(
                "/publish", body: PublishGistRequest(isPublic: isPublic)
            )
            return textResult("Published: \(resp.url)")

        case "export_pdf":
            let resp: ExportPDFResponse = try await client.get("/export/pdf")
            if let outputPath = arguments?["output_path"]?.stringValue, !outputPath.isEmpty {
                guard let pdfData = Data(base64Encoded: resp.base64PDF) else {
                    return .init(
                        content: [.text(
                            text: "Failed to decode base64 PDF data from /export/pdf.",
                            annotations: nil,
                            _meta: nil
                        )],
                        isError: true
                    )
                }
                let url = URL(fileURLWithPath: outputPath)
                let parent = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: parent, withIntermediateDirectories: true
                )
                try pdfData.write(to: url)
                return textResult("PDF exported to \(outputPath) (\(resp.pageCount) pages).")
            }
            return textResult("PDF exported (\(resp.pageCount) pages). Base64 PDF data:\n\n\(resp.base64PDF)")

        case "add_image":
            let base64Data = arguments?["base64_data"]?.stringValue ?? ""
            let name = arguments?["name"]?.stringValue
            let resp: AddImageResponse = try await client.post(
                "/images",
                body: AddImageRequest(base64Data: base64Data, name: name)
            )
            return textResult("Image stored at \(resp.relativePath). Insert this markdown into a slide:\n\(resp.markdownSnippet)")

        case "set_image_transform":
            let slideIndex = arguments?["slide_index"]?.intValue ?? 0
            let path = arguments?["path"]?.stringValue ?? ""
            let req = SetImageTransformRequest(
                path: path,
                x: arguments?["x"]?.doubleValue,
                y: arguments?["y"]?.doubleValue,
                width: arguments?["width"]?.doubleValue
            )
            let _: SuccessResponse = try await client.put(
                "/slides/\(slideIndex)/image-transform",
                body: req
            )
            return textResult("Image transform updated on slide \(slideIndex + 1).")

        case "get_presenter_tool":
            let resp: PresenterToolResponse = try await client.get("/presenter/tool")
            var text = "Active tool: \(resp.activeTool)\n"
            text += "Available: \(resp.available.joined(separator: ", "))\n"
            text += "Drawing strokes: \(resp.drawingStrokeCount)"
            return textResult(text)

        case "set_presenter_tool":
            let tool = arguments?["tool"]?.stringValue ?? "none"
            let resp: PresenterToolResponse = try await client.put(
                "/presenter/tool",
                body: SetPresenterToolRequest(tool: tool)
            )
            return textResult("Presenter tool set to: \(resp.activeTool)")

        case "clear_drawings":
            let _: SuccessResponse = try await client.postEmpty("/presenter/clear-drawings")
            return textResult("All drawing strokes cleared.")

        case "list_themes":
            let resp: ThemeListResponse = try await client.get("/themes")
            var text = "Available themes (\(resp.themes.count)):\n\n"
            for t in resp.themes {
                text += "  \(t.name) — bg:\(t.background) text:\(t.text) heading:\(t.heading) accent:\(t.accent)\n"
            }
            return textResult(text)

        case "get_theme":
            let resp: ThemeResponse = try await client.get("/theme")
            var text = "Current theme: \(resp.current ?? "auto")\n"
            if let def = resp.definition {
                text += "  background: \(def.background)\n"
                text += "  text: \(def.text)\n"
                text += "  heading: \(def.heading)\n"
                text += "  accent: \(def.accent)\n"
                text += "  codeBackground: \(def.codeBackground)\n"
                text += "  codeText: \(def.codeText)\n"
            }
            return textResult(text)

        case "set_theme":
            let name = arguments?["name"]?.stringValue ?? "auto"
            let req = SetThemeRequest(
                name: name,
                background: arguments?["background"]?.stringValue,
                text: arguments?["text"]?.stringValue,
                heading: arguments?["heading"]?.stringValue,
                accent: arguments?["accent"]?.stringValue,
                codeBackground: arguments?["code_background"]?.stringValue,
                codeText: arguments?["code_text"]?.stringValue
            )
            let resp: ThemeResponse = try await client.put("/theme", body: req)
            return textResult("Theme set to: \(resp.current ?? "auto")")

        case "get_font":
            let resp: FontResponse = try await client.get("/font")
            var text = "Current font: \(resp.current ?? "System Default")\n\nAvailable fonts:\n"
            for f in resp.available {
                text += "  \(f)\n"
            }
            return textResult(text)

        case "set_font":
            let name = arguments?["name"]?.stringValue
            let req = SetFontRequest(name: name)
            let resp: FontResponse = try await client.put("/font", body: req)
            return textResult("Font set to: \(resp.current ?? "System Default")")

        case "get_transition":
            let resp: TransitionResponse = try await client.get("/transition")
            var text = "Current transition: \(resp.current)\n\nAvailable transitions:\n"
            for t in resp.available {
                text += "  \(t)\n"
            }
            return textResult(text)

        case "set_transition":
            let name = arguments?["name"]?.stringValue ?? "none"
            let req = SetTransitionRequest(name: name)
            let resp: TransitionResponse = try await client.put("/transition", body: req)
            return textResult("Transition set to: \(resp.current)")

        case "get_timer":
            let resp: TimerResponse = try await client.get("/timer")
            var text = "Timer: \(resp.running ? "running" : "stopped")\n"
            text += "Elapsed: \(resp.elapsedSeconds)s"
            if resp.running {
                let mins = resp.elapsedSeconds / 60
                let secs = resp.elapsedSeconds % 60
                text += " (\(mins)m \(secs)s)"
            }
            text += "\nWall clock: \(resp.wallClock)"
            return textResult(text)

        case "start_timer":
            let resp: TimerResponse = try await client.postEmpty("/timer/start")
            return textResult("Timer started. Wall clock: \(resp.wallClock)")

        case "stop_timer":
            let _: TimerResponse = try await client.postEmpty("/timer/stop")
            return textResult("Timer stopped.")

        case "save_file":
            let resp: SaveResponse = try await client.postEmpty("/save")
            switch resp.outcome {
            case .saved(let path):
                return textResult("Saved to \(path)")
            case .noPath:
                return .init(
                    content: [.text(
                        text: "No file path set; call save_as first.",
                        annotations: nil,
                        _meta: nil
                    )],
                    isError: true
                )
            }

        case "get_markdown":
            let resp: GetMarkdownResponse = try await client.get("/markdown")
            var text = "File: \(resp.filePath ?? "(unsaved)")\n"
            text += "Dirty: \(resp.isDirty)\n\n"
            text += resp.markdown
            return textResult(text)

        case "undo":
            let resp: UndoRedoResponse = try await client.postEmpty("/undo")
            if resp.success {
                return textResult("Undo successful.")
            } else {
                return textResult("Nothing to undo.")
            }

        case "redo":
            let resp: UndoRedoResponse = try await client.postEmpty("/redo")
            if resp.success {
                return textResult("Redo successful.")
            } else {
                return textResult("Nothing to redo.")
            }

        case "search_slides":
            let query = arguments?["query"]?.stringValue ?? ""
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let resp: SearchResponse = try await client.get("/search?q=\(encoded)")
            if resp.matches.isEmpty {
                return textResult("No matches found for \"\(resp.query)\".")
            }
            var text = "Found \(resp.matches.count) match(es) for \"\(resp.query)\":\n\n"
            for match in resp.matches {
                let title = match.title ?? "(untitled)"
                text += "[\(match.index + 1)] \(title)\n"
                text += "  …\(match.excerpt)…\n\n"
            }
            return textResult(text)

        case "get_notes":
            let index = arguments?["index"]?.intValue ?? 0
            let resp: NotesResponse = try await client.get("/slides/\(index)/notes")
            if let notes = resp.notes {
                return textResult("Slide \(index + 1) notes:\n\(notes)")
            } else {
                return textResult("Slide \(index + 1) has no speaker notes.")
            }

        case "set_notes":
            let index = arguments?["index"]?.intValue ?? 0
            let notes = arguments?["notes"]?.stringValue
            let resp: NotesResponse = try await client.put(
                "/slides/\(index)/notes",
                body: SetNotesRequest(notes: notes)
            )
            if let notes = resp.notes {
                return textResult("Notes updated for slide \(index + 1):\n\(notes)")
            } else {
                return textResult("Notes removed from slide \(index + 1).")
            }

        case "export_html":
            let resp: ExportHTMLResponse = try await client.get("/export/html")
            if let outputPath = arguments?["output_path"]?.stringValue, !outputPath.isEmpty {
                let url = URL(fileURLWithPath: outputPath)
                try resp.html.write(to: url, atomically: true, encoding: .utf8)
                return textResult("HTML exported to \(outputPath) (\(resp.slideCount) slides).")
            }
            return textResult("HTML exported successfully (\(resp.slideCount) slides). HTML length: \(resp.html.count) characters.\n\n\(resp.html)")

        default:
            return .init(
                content: [.text(text: "Unknown tool: \(name)", annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }

    private static func textResult(_ text: String) -> CallTool.Result {
        .init(
            content: [.text(text: text, annotations: nil, _meta: nil)],
            isError: false
        )
    }
}

// MARK: - Value helpers

extension Value {
    var intValue: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let b): return b
        default: return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        case .string(let s): return Double(s)
        default: return nil
        }
    }
}
