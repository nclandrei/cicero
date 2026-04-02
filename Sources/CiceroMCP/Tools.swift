import Foundation
import MCP
import Shared

/// All Cicero MCP tool definitions
enum CiceroTools {
    static let all: [Tool] = [
        Tool(
            name: "list_slides",
            description: "List all slides with their titles and content",
            inputSchema: .object([
                "type": "object",
                "properties": .object([:]),
            ])
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
            ])
        ),
        Tool(
            name: "set_slide",
            description: "Update the content of a specific slide. Supports per-slide layout frontmatter at the top: 'layout: title|two-column|image-left|image-right' and 'image: URL'. Use '|||' to separate columns in two-column layout.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based)"]),
                    "content": .object(["type": "string", "description": "New markdown content for the slide. Add 'layout: <type>' as the first line for layout. Use '|||' to separate columns in two-column layout."]),
                ]),
                "required": .array([.string("index"), .string("content")]),
            ])
        ),
        Tool(
            name: "add_slide",
            description: "Add a new slide to the presentation. Supports per-slide layout frontmatter: 'layout: title|two-column|image-left|image-right' and 'image: URL' as first lines.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "content": .object(["type": "string", "description": "Markdown content for the new slide. Add 'layout: <type>' as the first line for layout."]),
                    "after_index": .object(["type": "integer", "description": "Insert after this slide index. Omit to append at end."]),
                ]),
                "required": .array([.string("content")]),
            ])
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
            ])
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
            ])
        ),
        Tool(
            name: "next_slide",
            description: "Navigate to the next slide",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "prev_slide",
            description: "Navigate to the previous slide",
            inputSchema: .object(["type": "object", "properties": .object([:])])
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
            ])
        ),
        Tool(
            name: "screenshot_slide",
            description: "Capture a rendered screenshot of a slide as PNG",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "index": .object(["type": "integer", "description": "Slide index (0-based). Omit for current slide."]),
                ]),
            ])
        ),
        Tool(
            name: "all_thumbnails",
            description: "Get thumbnail images of all slides as base64 PNGs",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "start_presentation",
            description: "Enter fullscreen presentation mode",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "stop_presentation",
            description: "Exit presentation mode",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "get_status",
            description: "Get the current state of the presentation (current slide, mode, file path)",
            inputSchema: .object(["type": "object", "properties": .object([:])])
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
            ])
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
            ])
        ),
        Tool(
            name: "auth_status",
            description: "Check GitHub authentication status",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "publish_gist",
            description: "Publish the current presentation as a GitHub Gist. Requires GitHub authentication via Settings.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "public": .object(["type": "boolean", "description": "Whether the gist should be public (default: false)"]),
                ]),
            ])
        ),
        Tool(
            name: "export_pdf",
            description: "Export the current presentation as a multi-page PDF",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
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
            ])
        ),
        Tool(
            name: "list_themes",
            description: "List all available built-in themes with their color definitions",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "get_theme",
            description: "Get the current presentation theme name and color definition",
            inputSchema: .object(["type": "object", "properties": .object([:])])
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
            ])
        ),
        Tool(
            name: "undo",
            description: "Undo the last edit to the presentation",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "redo",
            description: "Redo the last undone edit to the presentation",
            inputSchema: .object(["type": "object", "properties": .object([:])])
        ),
        Tool(
            name: "search_slides",
            description: "Search across all slides for a text query. Returns matching slides with excerpts showing context around each match.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "query": .object(["type": "string", "description": "Text to search for (case-insensitive)"]),
                ]),
                "required": .array([.string("query")]),
            ])
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
            return textResult(resp.content)

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
            return .init(
                content: [
                    .text(text: "Screenshot of slide \(resp.slideIndex + 1)", annotations: nil, _meta: nil),
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
            if let path = resp.filePath { text += "  File: \(path)\n" }
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
                return textResult("Not authenticated. Sign in via Settings (Cmd+,) in the Cicero app.")
            }

        case "publish_gist":
            let isPublic = arguments?["public"]?.boolValue ?? false
            let resp: PublishGistResponse = try await client.post(
                "/publish", body: PublishGistRequest(isPublic: isPublic)
            )
            return textResult("Published: \(resp.url)")

        case "export_pdf":
            let resp: ExportPDFResponse = try await client.get("/export/pdf")
            return textResult("PDF exported successfully (\(resp.pageCount) pages). Base64 PDF data length: \(resp.base64PDF.count) characters.")

        case "add_image":
            let base64Data = arguments?["base64_data"]?.stringValue ?? ""
            let name = arguments?["name"]?.stringValue
            let resp: AddImageResponse = try await client.post(
                "/images",
                body: AddImageRequest(base64Data: base64Data, name: name)
            )
            return textResult("Image stored at \(resp.relativePath). Insert this markdown into a slide:\n\(resp.markdownSnippet)")

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
}
