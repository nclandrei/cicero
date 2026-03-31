# Cicero

<p align="center">
  <img src="icon/final/icon-512.png" width="128" height="128" alt="Cicero app icon" />
</p>

A macOS presentation app where slides are plain Markdown files and an AI agent can build, edit, and present the deck through MCP tools.

## How It Works

Cicero is a SwiftUI macOS app with a built-in HTTP server. A separate MCP server binary (`CiceroMCP`) exposes every operation as an MCP tool. The two communicate over `localhost:19847`, so any MCP-compatible agent (Claude Code, Claude Desktop, etc.) can create presentations, edit slides, switch themes, and start a fullscreen presentation — all without touching the GUI.

You can also use the app directly. It has a split-pane editor with live preview, a slide overview grid, presenter mode, PDF export, and GitHub Gist publishing.

## Architecture

Three SwiftPM targets:

| Target | What it does |
|---|---|
| **Cicero** | macOS SwiftUI app — editor, live preview, presenter mode, HTTP server |
| **CiceroMCP** | MCP stdio server — proxies tool calls to the app over HTTP |
| **Shared** | Library — slide parser, data models, theme definitions |

## Build & Run

Requires macOS 14+ and Swift 6.0.

```bash
swift build
swift run Cicero
```

To use the MCP tools, start the app first, then run the MCP server:

```bash
swift run CiceroMCP
```

Or add CiceroMCP to your MCP client config (e.g. Claude Code `settings.json`):

```json
{
  "mcpServers": {
    "cicero": {
      "command": "swift",
      "args": ["run", "--package-path", "/path/to/cicero", "CiceroMCP"]
    }
  }
}
```

## Slide Format

Presentations are `.md` files. An optional YAML frontmatter block sets document-level metadata, and `---` on its own line separates slides. Code blocks containing `---` are not treated as separators.

```markdown
---
title: My Presentation
theme: ocean
author: Name
---

# First Slide

This is the first slide.

---

# Second Slide

- Bullet one
- Bullet two
```

### Frontmatter Fields

| Field | Description |
|---|---|
| `title` | Presentation title |
| `theme` | Theme name: `auto`, any built-in name, or `custom` |
| `author` | Author name |
| `gist_id` | GitHub Gist ID (set automatically on publish) |
| `theme_background` | Custom background hex color |
| `theme_text` | Custom text hex color |
| `theme_heading` | Custom heading hex color |
| `theme_accent` | Custom accent hex color |
| `theme_code_background` | Custom code block background hex color |
| `theme_code_text` | Custom code block text hex color |

### Layouts

Each slide can set a layout in its first line:

```markdown
layout: title
# Welcome
```

| Layout | Description |
|---|---|
| `default` | Standard scrollable markdown slide |
| `title` | Center-aligned with larger heading fonts |
| `two-column` | Content split by `\|\|\|` separator into left and right columns |
| `image-left` | Image on left, content on right |
| `image-right` | Image on right, content on left |

### Images

Standard markdown image syntax. Images are stored in an `assets/` directory alongside the `.md` file. Width can be set via URL fragment:

```markdown
![Photo](assets/photo.png#w=400)
```

## Themes

10 built-in themes: `dark`, `light`, `ocean`, `forest`, `sunset`, `minimal`, `solarized-dark`, `solarized-light`, `nord`, `dracula`.

Each theme defines six colors: background, text, heading, accent, code background, and code text.

Set `theme: auto` to follow the system appearance. Set `theme: custom` and provide `theme_*` frontmatter fields for a fully custom palette.

## Presenter Mode

Enter from the toolbar play button or via the `start_presentation` MCP tool. Slides display fullscreen with a slide counter in the bottom right.

Navigation:
- Left/right arrow keys
- Space bar (next)
- Click left half (previous) / right half (next)
- Escape to exit

## PDF Export

File > Export PDF (Cmd+Shift+E). Each slide renders at 1920x1080 and is embedded as a page in the output PDF, preserving the active theme.

## GitHub Publishing

Authenticate with GitHub via Settings (Cmd+,) using the OAuth device flow. Publish presentations as Gists (public or private) and get a shareable link to the Cicero web viewer at `https://cicero.nicolaeandrei.com/#/g/{gistId}`.

## MCP Tools

CiceroMCP exposes 24 tools:

**Slides** — `list_slides`, `get_slide`, `set_slide`, `add_slide`, `remove_slide`
**Navigation** — `next_slide`, `prev_slide`, `goto_slide`
**Presentation** — `start_presentation`, `stop_presentation`
**Screenshots** — `screenshot_slide`, `all_thumbnails`
**Files** — `open_file`, `create_presentation`, `get_status`
**Export** — `export_pdf`
**Images** — `add_image`
**Themes** — `list_themes`, `get_theme`, `set_theme`
**Publishing** — `auth_status`, `publish_gist`

## HTTP API

The app runs a local HTTP server on port `19847`. All responses are JSON.

**GET**

| Endpoint | Description |
|---|---|
| `/status` | Current slide index, total count, presenting state, file path, title, theme |
| `/slides` | All slides with indices, titles, content, layouts |
| `/slides/:index` | Single slide details |
| `/current` | Current index and total count |
| `/screenshot` | Current slide as base64 PNG |
| `/screenshot/:index` | Specific slide as base64 PNG |
| `/thumbnails` | Base64 PNG thumbnails of all slides |
| `/auth/status` | GitHub authentication status |
| `/themes` | All available theme definitions |
| `/theme` | Current theme name and colors |
| `/export/pdf` | Full presentation as base64 PDF |

**POST**

| Endpoint | Body | Description |
|---|---|---|
| `/navigate` | `{action, index?}` | Navigate: `next`, `prev`, or `goto` |
| `/slides` | `{content, afterIndex?}` | Add a slide |
| `/open` | `{path}` | Open a `.md` file |
| `/create` | `{markdown}` | Create presentation from markdown string |
| `/presentation/start` | — | Enter presenter mode |
| `/presentation/stop` | — | Exit presenter mode |
| `/images` | `{base64Data, name?}` | Add image to assets directory |
| `/publish` | `{isPublic}` | Publish as GitHub Gist |

**PUT**

| Endpoint | Body | Description |
|---|---|---|
| `/slides/:index` | `{content}` | Update slide content |
| `/theme` | `{name, background?, text?, ...}` | Set theme |

**DELETE**

| Endpoint | Description |
|---|---|
| `/slides/:index` | Remove a slide |

## Dependencies

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Markdown rendering
- [Splash](https://github.com/JohnSundell/Splash) — Code syntax highlighting
- [Swifter](https://github.com/httpswift/swifter) — HTTP server for IPC
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) — MCP protocol

## Development

```bash
swift build
swift test
```
