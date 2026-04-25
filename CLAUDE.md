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

All routes are served by `Sources/Cicero/Services/LocalServer.swift` on `localhost:19847`.

**GET**
- `/status` — current slide, total, presenting flag, file path, metadata
- `/slides` — full slide list with current index
- `/slides/:index` — single slide
- `/slides/:index/notes` — speaker notes for a slide
- `/current` — current slide index + total
- `/screenshot` — render current slide PNG (optional `?save_path=`)
- `/screenshot/:index` — render specific slide PNG (optional `?save_path=`)
- `/thumbnails` — base64 thumbnails for every slide
- `/presenter/tool` — active presenter tool (none/pointer/spotlight/drawing)
- `/timer` — timer state (running, elapsed, wall clock)
- `/export/pdf` — base64 PDF of the deck
- `/export/html` — self-contained reveal.js HTML
- `/auth/status` — GitHub auth state + username
- `/themes` — list of built-in themes
- `/theme` — current theme + resolved palette
- `/font` — current font + suggestion list
- `/transition` — current transition + available list
- `/markdown` — raw markdown buffer + dirty flag
- `/search?q=…` — substring search across slides

**POST**
- `/slides` — append/insert a slide
- `/slides/:index/duplicate` — clone a slide
- `/slides/reorder` — move slide `from` → `to`
- `/navigate` — `next`/`prev`/`goto` (with `index`)
- `/presentation/start`, `/presentation/stop` — fullscreen presenter
- `/presenter/clear-drawings` — wipe drawing strokes
- `/timer/start`, `/timer/stop`
- `/undo`, `/redo`
- `/open` — load file at path
- `/create` — replace deck with provided markdown
- `/images` — store base64 image, return markdown snippet
- `/save` — write current deck to disk
- `/publish` — publish (or update) GitHub Gist; requires auth

**PUT**
- `/slides/:index` — replace slide content
- `/slides/:index/image-transform` — set/update `#w=&x=&y=` fragment for an image
- `/slides/:index/notes` — set speaker notes
- `/presenter/tool` — set active presenter tool
- `/theme` — switch to built-in or custom theme
- `/font` — set font (nil clears)
- `/transition` — set deck transition

**DELETE**
- `/slides/:index` — remove a slide

## GitHub Auth

`Sources/Cicero/Services/GitHubAuth.swift` writes the OAuth token as a 0600-permissioned
plaintext file at `~/Library/Application Support/Cicero/github-token` (mirrors the `gh`
CLI). Keychain was tried and rejected: SecItem ACLs are bound to the binary's code
signature, and debug rebuilds churn that signature, producing repeated "Always Allow"
prompts.

## Slide Format

Markdown with YAML frontmatter, slides separated by `---`. Code blocks respected (not split).
