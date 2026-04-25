# Cicero — AI-Native macOS Presentation App

## Architecture

SwiftPM project with 3 targets:
- **Cicero** — macOS SwiftUI app (slide editor + live preview + presenter mode)
- **CiceroMCP** — MCP stdio server (proxies tool calls to app via HTTP)
- **Shared** — Library with slide parser, API models, constants

IPC: CiceroMCP ↔ Cicero app via local HTTP server on `localhost:19847`

## Key Files

- `Package.swift` — Swift 6.0 tools-version, language mode v5
- `Sources/Shared/SlideParser.swift` — Markdown → Slide array (handles frontmatter + `---` separators)
- `Sources/Cicero/Services/LocalServer.swift` — HTTP API (Swifter) for all slide operations
- `Sources/CiceroMCP/Tools.swift` — MCP tool definitions + handler dispatch
- `Sources/CiceroMCP/main.swift` — MCP server entry (stdio transport)

## Dependencies

- MarkdownUI (gonzalezreal/swift-markdown-ui) — Rich markdown rendering
- Splash (JohnSundell/Splash) — Swift syntax highlighting; integrated for Swift code fences in the slide renderer (`SlideView.swift`, `SlideLayoutViews.swift`), the editor highlighter (`MarkdownHighlighter.swift`), and the screenshot service (`ScreenshotService.swift`). Non-Swift fences render as themed plain text.
- Swifter (httpswift/swifter) — Lightweight HTTP server for IPC
- MCP Swift SDK (modelcontextprotocol/swift-sdk v0.12.0) — MCP protocol

## Build & Run

```bash
swift build                    # Build both targets
swift run Cicero               # Launch the app
swift run CiceroMCP            # Run MCP server (needs running app)
```

## HTTP API Endpoints

GET /status, /slides, /slides/:n, /current, /screenshot, /screenshot/:n, /thumbnails
GET /export/pdf, /export/html
POST /slides, /navigate, /presentation/start, /presentation/stop, /open, /create
PUT /slides/:n
DELETE /slides/:n

## Slide Format

Markdown with YAML frontmatter, slides separated by `---`. Code blocks respected (not split).
