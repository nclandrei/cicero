import Foundation

/// Generates a self-contained HTML presentation using reveal.js from Cicero slides.
public enum HTMLExportService {

    /// Generate a standalone HTML file from presentation metadata, slides, and theme.
    public static func exportHTML(
        metadata: PresentationMetadata,
        slides: [Slide],
        theme: ThemeDefinition?
    ) -> String {
        let resolvedTheme = theme ?? metadata.resolveTheme() ?? ThemeRegistry.dark
        let title = escapeHTML(metadata.title ?? "Presentation")
        let author = metadata.author.map(escapeHTML) ?? ""

        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(title)</title>
        \(author.isEmpty ? "" : "<meta name=\"author\" content=\"\(author)\">\n")\
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.css">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/plugin/highlight/monokai.css">
        <style>
        \(generateCSS(theme: resolvedTheme))
        </style>
        </head>
        <body>
        <div class="reveal">
        <div class="slides">

        """

        for slide in slides {
            html += renderSlide(slide) + "\n"
        }

        html += """
        </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/plugin/markdown/markdown.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/plugin/highlight/highlight.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/plugin/notes/notes.js"></script>
        <script>
        Reveal.initialize({
            width: 1920,
            height: 1080,
            margin: 0.04,
            hash: true,
            plugins: [RevealMarkdown, RevealHighlight, RevealNotes]
        });
        </script>
        </body>
        </html>
        """

        return html
    }

    // MARK: - CSS Generation

    static func generateCSS(theme: ThemeDefinition) -> String {
        return """
        :root {
            --r-background-color: \(theme.background);
            --r-main-color: \(theme.text);
            --r-heading-color: \(theme.heading);
            --r-link-color: \(theme.accent);
            --r-link-color-hover: \(theme.accent);
            --r-selection-background-color: \(theme.accent);
            --r-code-background: \(theme.codeBackground);
            --r-code-text: \(theme.codeText);
        }
        .reveal {
            background-color: var(--r-background-color);
            color: var(--r-main-color);
        }
        .reveal h1, .reveal h2, .reveal h3, .reveal h4, .reveal h5, .reveal h6 {
            color: var(--r-heading-color);
        }
        .reveal a {
            color: var(--r-link-color);
        }
        .reveal pre {
            background: var(--r-code-background);
            border-radius: 8px;
            padding: 1em;
            width: 100%;
            box-sizing: border-box;
        }
        .reveal pre code {
            color: var(--r-code-text);
            background: transparent;
            max-height: 600px;
        }
        .reveal code {
            color: var(--r-code-text);
            background: var(--r-code-background);
            padding: 0.1em 0.3em;
            border-radius: 4px;
        }
        .reveal blockquote {
            border-left: 4px solid var(--r-link-color);
            padding-left: 1em;
            font-style: italic;
        }
        .reveal table {
            border-collapse: collapse;
            margin: 1em auto;
        }
        .reveal table th, .reveal table td {
            border: 1px solid var(--r-main-color);
            padding: 0.5em 1em;
            text-align: left;
        }
        .reveal table th {
            background: var(--r-code-background);
        }
        .title-slide {
            text-align: center;
        }
        .title-slide h1, .title-slide h2 {
            margin-bottom: 0.5em;
        }
        .two-column {
            display: flex;
            gap: 2em;
            align-items: flex-start;
            text-align: left;
            width: 100%;
        }
        .two-column .column {
            flex: 1;
            min-width: 0;
        }
        .image-layout {
            display: flex;
            gap: 2em;
            align-items: center;
            width: 100%;
        }
        .image-layout img {
            max-width: 50%;
            max-height: 80vh;
            object-fit: contain;
        }
        .image-layout .content {
            flex: 1;
            min-width: 0;
        }
        """
    }

    // MARK: - Slide Rendering

    static func renderSlide(_ slide: Slide) -> String {
        switch slide.layout {
        case .title:
            return renderTitleSlide(slide)
        case .twoColumn:
            return renderTwoColumnSlide(slide)
        case .imageLeft:
            return renderImageSlide(slide, imageFirst: true)
        case .imageRight:
            return renderImageSlide(slide, imageFirst: false)
        default:
            return renderDefaultSlide(slide)
        }
    }

    static func notesHTML(_ slide: Slide) -> String {
        guard let notes = slide.notes else { return "" }
        return "\n<aside class=\"notes\">\(escapeHTML(notes))</aside>"
    }

    static func renderDefaultSlide(_ slide: Slide) -> String {
        return """
        <section data-markdown><textarea data-template>
        \(escapeTextarea(slide.body))
        </textarea>\(notesHTML(slide))</section>
        """
    }

    static func renderTitleSlide(_ slide: Slide) -> String {
        return """
        <section class="title-slide" data-markdown><textarea data-template>
        \(escapeTextarea(slide.body))
        </textarea>\(notesHTML(slide))</section>
        """
    }

    static func renderTwoColumnSlide(_ slide: Slide) -> String {
        let parts = slide.body.components(separatedBy: "|||")
        if parts.count >= 2 {
            let left = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let right = parts[1...].joined(separator: "|||").trimmingCharacters(in: .whitespacesAndNewlines)
            return """
            <section>
            <div class="two-column">
            <div class="column" data-markdown><textarea data-template>
            \(escapeTextarea(left))
            </textarea></div>
            <div class="column" data-markdown><textarea data-template>
            \(escapeTextarea(right))
            </textarea></div>
            </div>\(notesHTML(slide))
            </section>
            """
        }
        // Fallback to default if no ||| separator
        return renderDefaultSlide(slide)
    }

    static func renderImageSlide(_ slide: Slide, imageFirst: Bool) -> String {
        let imageURL = slide.imageURL ?? ""
        let imgTag = "<img src=\"\(escapeHTML(imageURL))\" alt=\"Slide image\">"
        let contentMarkdown = escapeTextarea(slide.body)

        if imageFirst {
            return """
            <section>
            <div class="image-layout">
            \(imgTag)
            <div class="content" data-markdown><textarea data-template>
            \(contentMarkdown)
            </textarea></div>
            </div>\(notesHTML(slide))
            </section>
            """
        } else {
            return """
            <section>
            <div class="image-layout">
            <div class="content" data-markdown><textarea data-template>
            \(contentMarkdown)
            </textarea></div>
            \(imgTag)
            </div>\(notesHTML(slide))
            </section>
            """
        }
    }

    // MARK: - Escaping

    /// Escape HTML special characters.
    public static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Escape content for inside a <textarea> tag. Only </textarea> needs escaping.
    static func escapeTextarea(_ string: String) -> String {
        string.replacingOccurrences(of: "</textarea>", with: "&lt;/textarea>")
    }
}
