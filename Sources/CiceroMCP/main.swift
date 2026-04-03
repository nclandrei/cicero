import Foundation
import MCP

private let serverInstructions = """
Cicero is a macOS presentation app controlled through these MCP tools. \
The Cicero app must be running for tools to work.

## Slide Format

Slides are markdown separated by `---`. An optional YAML frontmatter block sets \
document-level metadata (title, theme, author). Code fences containing `---` are \
not treated as separators.

Example:
```
---
title: My Deck
theme: ocean
author: Name
---
# First Slide
Content here.
---
# Second Slide
- Bullet one
- Bullet two
```

## Layouts

Set a layout as the first line of slide content:

- `layout: title` — centered, larger heading
- `layout: two-column` — split content with `|||` separator between columns
- `layout: image-left` / `image-right` — image beside content (add `image: URL`)
- `layout: video` — embedded video (add `video: URL`)
- `layout: embed` — web embed (add `embed: URL`)

Two-column example:
```
layout: two-column
# Left
Content
|||
# Right
Content
```

## Themes

10 built-in themes: dark, light, ocean, forest, sunset, minimal, solarized-dark, \
solarized-light, nord, dracula. Or use `set_theme` with `name: "custom"` plus hex \
color parameters for a custom palette. Use `list_themes` to see all colors.

## Typical Workflows

- **Create a deck:** `create_presentation` with full markdown, or `add_slide` incrementally
- **Edit:** `list_slides` to see structure → `get_slide` to read → `set_slide` to update
- **Visual check:** `screenshot_slide` or `all_thumbnails` to see rendered output
- **Style:** `set_theme`, `set_font`, `set_transition`
- **Present:** `start_presentation` / `stop_presentation`, navigate with `next_slide`, \
`prev_slide`, or `goto_slide`
- **Export:** `export_pdf` for print, `export_html` for browser
- **Publish:** `auth_status` to check login → `publish_gist` to share via GitHub

## Key Details

- All slide indices are **0-based**.
- `add_image` returns a markdown snippet — insert it into a slide with `set_slide`.
- `search_slides` is case-insensitive and returns matching excerpts.
- `get_status` shows current slide, mode, file path, theme, font, and transition.
- `save_file` requires a file path (set by `open_file` or a prior save).
- `create_presentation` and `open_file` replace the current deck — use with care.
"""

let server = Server(
    name: "cicero",
    version: "1.0.0",
    instructions: serverInstructions,
    capabilities: .init(tools: .init(listChanged: false))
)

let appClient = AppClient()

await server.withMethodHandler(ListTools.self) { _ in
    .init(tools: CiceroTools.all)
}

await server.withMethodHandler(CallTool.self) { params in
    do {
        return try await CiceroToolHandler.handle(
            name: params.name,
            arguments: params.arguments,
            client: appClient
        )
    } catch {
        return .init(
            content: [.text(
                text: "Error: \(error.localizedDescription). Is the Cicero app running?",
                annotations: nil,
                _meta: nil
            )],
            isError: true
        )
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
