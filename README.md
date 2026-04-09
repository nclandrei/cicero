<p align="center">
  <img src="icon/cicero-icon-1024.png" width="128" height="128" alt="Cicero icon">
</p>

# Cicero

A macOS presentation app where slides are plain Markdown and an AI agent can build, edit, and present the deck through MCP tools.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)
![MIT License](https://img.shields.io/badge/license-MIT-blue)

## How It Works

Cicero is a SwiftUI app with a built-in HTTP server. A separate MCP server binary (`CiceroMCP`) exposes every operation as an MCP tool. The two communicate over `localhost:19847`, so any MCP-compatible agent (Claude Code, Claude Desktop, etc.) can create presentations, edit slides, switch themes, and run a fullscreen presentation — all without touching the GUI.

You can also use the app directly. It has a split-pane editor with live preview, a slide overview grid, presenter mode with timer, PDF and HTML export, and GitHub Gist publishing with a [web viewer](https://cicero.nicolaeandrei.com).

## Features

- **Markdown slides** -- Write presentations in plain `.md` files with YAML frontmatter. Slides are separated by `---`.
- **Live preview** -- Split-pane editor with instant rendering. Code blocks are syntax-highlighted via Splash.
- **Slide layouts** -- Title, two-column, image-left, image-right, video, and embed layouts per slide.
- **10 built-in themes** -- Dark, light, ocean, forest, sunset, minimal, solarized-dark, solarized-light, nord, dracula. Or define a fully custom palette.
- **Presenter mode** -- Fullscreen presentation with slide counter, timer, and keyboard/mouse navigation.
- **Font picker** -- Choose from any installed system font directly from the toolbar.
- **PDF and HTML export** -- Each slide renders at 1920x1080. HTML export is self-contained with reveal.js.
- **GitHub publishing** -- OAuth device flow authentication. Publish decks as Gists and share via the web viewer.
- **33 MCP tools** -- Full agent parity. An AI agent can do everything the GUI can: create, edit, reorder, theme, screenshot, present, export, and publish.
- **Proctor CLI** -- `swift run Proctor validate deck.md` to lint presentations from the terminal.
- **File watching** -- Edits to the `.md` file on disk are picked up automatically.
- **Undo/redo** -- Full edit history with keyboard shortcuts.

## Install

### Build from source

Requires Xcode 15+ / Swift 6.0.

```bash
swift build
swift run Cicero
```

## MCP Setup

Cicero includes an MCP server (`CiceroMCP`) that lets AI agents control the app. Start Cicero, then configure your agent.

**Quick install:** Open Cicero → Settings → MCP Server and click **Install** next to your agent. Or add the config manually:

### Claude Code

```bash
claude mcp add cicero -- swift run --package-path /path/to/cicero CiceroMCP
```

Or add to `.mcp.json` in your project (or `~/.claude.json` for global):

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

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

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

### Cursor

Add to `.cursor/mcp.json` in your project or `~/.cursor/mcp.json` for global:

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

### Windsurf

Add to `~/.codeium/windsurf/mcp_config.json`:

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

### Amp

```bash
amp mcp add cicero -- swift run --package-path /path/to/cicero CiceroMCP
```

Or add to `~/.config/amp/settings.json`:

```json
{
  "amp.mcpServers": {
    "cicero": {
      "command": "swift",
      "args": ["run", "--package-path", "/path/to/cicero", "CiceroMCP"]
    }
  }
}
```

### Codex

```bash
codex mcp add cicero -- swift run --package-path /path/to/cicero CiceroMCP
```

Or add to `~/.codex/config.toml`:

```toml
[mcp_servers.cicero]
command = "swift"
args = ["run", "--package-path", "/path/to/cicero", "CiceroMCP"]
```

### OpenCode

Add to `~/.config/opencode/opencode.json` or `opencode.json` in your project:

```json
{
  "mcp": {
    "cicero": {
      "type": "local",
      "command": ["swift", "run", "--package-path", "/path/to/cicero", "CiceroMCP"],
      "enabled": true
    }
  }
}
```

### Run directly

```bash
swift run CiceroMCP
```

## Slide Format

An optional YAML frontmatter block sets document-level metadata. `---` on its own line separates slides. Code blocks containing `---` are not treated as separators.

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

### Frontmatter fields

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

### Slide layouts

Each slide can set a layout as its first line:

```markdown
layout: two-column
# Left Column

Content here

|||

# Right Column

More content
```

| Layout | Description |
|---|---|
| `default` | Standard scrollable markdown |
| `title` | Center-aligned with larger heading fonts |
| `two-column` | Content split by `\|\|\|` into left and right columns |
| `image-left` | Image on left, content on right |
| `image-right` | Image on right, content on left |
| `video` | Embedded video player |
| `embed` | Web content embed |

## Architecture

Three SwiftPM targets plus a CLI:

```
Sources/
  Cicero/              macOS SwiftUI app — editor, preview, presenter, HTTP server
    Models/            Presentation state, theme model, edit history
    Services/          Local HTTP server, PDF export, screenshots, GitHub auth, file watcher
    Views/             Editor, slide renderer, presenter, settings, toolbar
  CiceroMCP/           MCP stdio server — proxies tool calls to app over HTTP
  Shared/              Slide parser, theme registry, API models, HTML export
  Proctor/             CLI validator for presentation files

docs/                  Web viewer (GitHub Pages)
```

### Dependencies

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) -- Markdown rendering
- [Splash](https://github.com/JohnSundell/Splash) -- Code syntax highlighting
- [Swifter](https://github.com/httpswift/swifter) -- HTTP server for IPC
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) -- MCP protocol

### Key implementation details

- Slides are parsed from Markdown by walking lines and splitting on `---` separators, with special handling to avoid splitting inside fenced code blocks.
- The app runs a local HTTP server (Swifter) on port 19847. CiceroMCP calls these endpoints to execute every tool.
- Themes are defined as six-color palettes (background, text, heading, accent, code background, code text). `auto` follows the system appearance.
- Presenter mode renders slides fullscreen with a HUD overlay showing slide counter and elapsed time.
- PDF export renders each slide at 1920x1080 into a multi-page PDF using the active theme.
- HTML export produces a self-contained reveal.js file that works in any browser.
- GitHub publishing uses the OAuth device flow. Tokens are stored in the macOS Keychain.

## Development

```bash
swift build
swift test
```

## License

[MIT](LICENSE)
