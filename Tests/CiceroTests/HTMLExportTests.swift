import Testing
import Foundation
@testable import Shared

@Suite("HTML Export")
struct HTMLExportTests {

    let defaultMetadata = PresentationMetadata(title: "Test Presentation", theme: "dark", author: "Tester")
    let darkTheme = ThemeRegistry.dark

    // MARK: - Document Structure

    @Test("Produces valid HTML document with DOCTYPE and tags")
    func validHTMLStructure() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.hasPrefix("<!DOCTYPE html>"))
        #expect(html.contains("<html lang=\"en\">"))
        #expect(html.contains("</html>"))
        #expect(html.contains("<head>"))
        #expect(html.contains("</head>"))
        #expect(html.contains("<body>"))
        #expect(html.contains("</body>"))
        #expect(html.contains("class=\"reveal\""))
        #expect(html.contains("class=\"slides\""))
    }

    @Test("Includes reveal.js CDN links")
    func revealJSLinks() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("reveal.js@5/dist/reveal.css"))
        #expect(html.contains("reveal.js@5/dist/reveal.js"))
        #expect(html.contains("reveal.js@5/plugin/markdown/markdown.js"))
        #expect(html.contains("reveal.js@5/plugin/highlight/highlight.js"))
        #expect(html.contains("reveal.js@5/plugin/notes/notes.js"))
    }

    @Test("Includes Reveal.initialize with correct dimensions")
    func revealInitialize() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("Reveal.initialize"))
        #expect(html.contains("width: 1920"))
        #expect(html.contains("height: 1080"))
        #expect(html.contains("RevealMarkdown"))
        #expect(html.contains("RevealHighlight"))
    }

    // MARK: - Title and Metadata

    @Test("Title appears in HTML title tag")
    func titleInHead() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("<title>Test Presentation</title>"))
    }

    @Test("Author appears in meta tag")
    func authorMeta() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("name=\"author\" content=\"Tester\""))
    }

    @Test("Missing author omits meta tag")
    func noAuthorMeta() {
        let meta = PresentationMetadata(title: "No Author")
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: meta, slides: slides, theme: darkTheme)

        #expect(!html.contains("name=\"author\""))
    }

    // MARK: - Theme Colors

    @Test("Dark theme maps to correct CSS variables")
    func darkThemeCSS() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("--r-background-color: #1a1a2e"))
        #expect(html.contains("--r-main-color: #ffffff"))
        #expect(html.contains("--r-heading-color: #ffffff"))
        #expect(html.contains("--r-link-color: #6c63ff"))
        #expect(html.contains("--r-code-background: #16213e"))
        #expect(html.contains("--r-code-text: #e2e8f0"))
    }

    @Test("All built-in themes produce valid output")
    func allThemesProduceOutput() {
        let slides = [Slide(id: 0, content: "# Hello")]
        for theme in ThemeRegistry.builtIn {
            let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: theme)
            #expect(html.contains("--r-background-color: \(theme.background)"),
                    "Theme \(theme.name) missing background")
            #expect(html.contains("--r-main-color: \(theme.text)"),
                    "Theme \(theme.name) missing text color")
        }
    }

    @Test("Custom theme from metadata is used when no theme parameter")
    func customThemeFromMetadata() {
        let meta = PresentationMetadata(
            title: "Custom",
            theme: "custom",
            themeBackground: "#ff0000",
            themeText: "#00ff00",
            themeHeading: "#0000ff",
            themeAccent: "#ffff00"
        )
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: meta, slides: slides, theme: nil)

        #expect(html.contains("--r-background-color: #ff0000"))
        #expect(html.contains("--r-main-color: #00ff00"))
        #expect(html.contains("--r-heading-color: #0000ff"))
        #expect(html.contains("--r-link-color: #ffff00"))
    }

    // MARK: - Slide Layouts

    @Test("Multiple slides produce multiple section elements")
    func multipleSections() {
        let slides = [
            Slide(id: 0, content: "# Slide 1"),
            Slide(id: 1, content: "# Slide 2"),
            Slide(id: 2, content: "# Slide 3"),
        ]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        let sectionCount = html.components(separatedBy: "<section").count - 1
        #expect(sectionCount == 3, "Expected 3 sections, got \(sectionCount)")
    }

    @Test("Default layout uses data-markdown textarea")
    func defaultLayout() {
        let slides = [Slide(id: 0, content: "## Regular Slide\n\nSome content here.")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("data-markdown"))
        #expect(html.contains("data-template"))
        #expect(html.contains("Regular Slide"))
        #expect(html.contains("Some content here."))
    }

    @Test("Title layout adds title-slide class")
    func titleLayout() {
        let slides = [Slide(id: 0, content: "layout: title\n# Big Title\n\nSubtitle here")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"title-slide\""))
        #expect(html.contains("Big Title"))
    }

    @Test("Two-column layout splits on |||")
    func twoColumnLayout() {
        let slides = [Slide(id: 0, content: "layout: two-column\n## Columns\n\nLeft content\n\n|||\n\nRight content")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"two-column\""))
        #expect(html.contains("class=\"column\""))
        #expect(html.contains("Left content"))
        #expect(html.contains("Right content"))
    }

    @Test("Image-left layout renders image before content")
    func imageLeftLayout() {
        let slides = [Slide(id: 0, content: "layout: image-left\nimage: https://example.com/photo.jpg\n## Caption\n\nDescription")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"image-layout\""))
        #expect(html.contains("src=\"https://example.com/photo.jpg\""))
        // Image should come before content div
        if let imgRange = html.range(of: "<img"),
           let contentRange = html.range(of: "class=\"content\"") {
            #expect(imgRange.lowerBound < contentRange.lowerBound, "Image should appear before content in image-left layout")
        }
    }

    @Test("Image-right layout renders content before image")
    func imageRightLayout() {
        let slides = [Slide(id: 0, content: "layout: image-right\nimage: https://example.com/photo.jpg\n## Caption\n\nDescription")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"image-layout\""))
        // Content div should come before image
        if let contentRange = html.range(of: "class=\"content\""),
           let imgRange = html.range(of: "<img") {
            #expect(contentRange.lowerBound < imgRange.lowerBound, "Content should appear before image in image-right layout")
        }
    }

    // MARK: - Video Layout

    @Test("Video layout renders video element with controls")
    func videoLayout() {
        let slides = [Slide(id: 0, content: "layout: video\nvideo: https://example.com/clip.mp4")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"video-layout\""))
        #expect(html.contains("<video"))
        #expect(html.contains("controls"))
        #expect(html.contains("playsinline"))
        #expect(html.contains("src=\"https://example.com/clip.mp4\""))
    }

    @Test("Video layout shows placeholder when URL is missing")
    func videoLayoutNoURL() {
        let slides = [Slide(id: 0, content: "layout: video")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"video-layout\""))
        #expect(html.contains("class=\"media-placeholder\""))
        #expect(!html.contains("<video"))
    }

    @Test("Video layout includes text overlay from body")
    func videoLayoutOverlay() {
        let slides = [Slide(id: 0, content: "layout: video\nvideo: https://example.com/clip.mp4\nCaption text")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"media-overlay\""))
        #expect(html.contains("Caption text"))
    }

    @Test("Video layout omits overlay when body is empty")
    func videoLayoutNoOverlay() {
        let slides = [Slide(id: 0, content: "layout: video\nvideo: https://example.com/clip.mp4")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(!html.contains("class=\"media-overlay\""))
    }

    // MARK: - Embed Layout

    @Test("Embed layout renders iframe")
    func embedLayout() {
        let slides = [Slide(id: 0, content: "layout: embed\nembed: https://example.com/widget")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"embed-layout\""))
        #expect(html.contains("<iframe"))
        #expect(html.contains("src=\"https://example.com/widget\""))
        #expect(html.contains("allowfullscreen"))
    }

    @Test("Embed layout shows placeholder when URL is missing")
    func embedLayoutNoURL() {
        let slides = [Slide(id: 0, content: "layout: embed")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"embed-layout\""))
        #expect(html.contains("class=\"media-placeholder\""))
        #expect(!html.contains("<iframe"))
    }

    @Test("Embed layout includes text overlay from body")
    func embedLayoutOverlay() {
        let slides = [Slide(id: 0, content: "layout: embed\nembed: https://example.com/widget\nOverlay caption")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"media-overlay\""))
        #expect(html.contains("Overlay caption"))
    }

    @Test("Embed layout normalizes YouTube watch URL to embed")
    func embedYouTubeNormalization() {
        let slides = [Slide(id: 0, content: "layout: embed\nembed: https://www.youtube.com/watch?v=dQw4w9WgXcQ")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\""))
        #expect(!html.contains("watch?v="))
    }

    @Test("Embed layout normalizes youtu.be shortlink to embed")
    func embedYouTubeShortlink() {
        let slides = [Slide(id: 0, content: "layout: embed\nembed: https://youtu.be/dQw4w9WgXcQ")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\""))
    }

    @Test("Embed layout passes through already-embed YouTube URL")
    func embedYouTubeAlreadyEmbed() {
        let slides = [Slide(id: 0, content: "layout: embed\nembed: https://www.youtube.com/embed/dQw4w9WgXcQ")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\""))
    }

    // MARK: - YouTube URL Normalization

    @Test("normalizeYouTubeURLString converts watch URL")
    func normalizeYouTubeWatch() {
        let result = HTMLExportService.normalizeYouTubeURLString("https://www.youtube.com/watch?v=abc123")
        #expect(result == "https://www.youtube.com/embed/abc123")
    }

    @Test("normalizeYouTubeURLString converts shortlink")
    func normalizeYouTubeShortlink() {
        let result = HTMLExportService.normalizeYouTubeURLString("https://youtu.be/abc123")
        #expect(result == "https://www.youtube.com/embed/abc123")
    }

    @Test("normalizeYouTubeURLString passes through non-YouTube URLs")
    func normalizeNonYouTube() {
        let url = "https://figma.com/embed/xyz"
        let result = HTMLExportService.normalizeYouTubeURLString(url)
        #expect(result == url)
    }

    // MARK: - CSS for Video/Embed

    @Test("CSS includes video-layout and embed-layout styles")
    func cssIncludesMediaStyles() {
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains(".video-layout"))
        #expect(html.contains(".embed-layout"))
        #expect(html.contains(".media-overlay"))
        #expect(html.contains(".media-placeholder"))
    }

    // MARK: - Content Preservation

    @Test("Code blocks are preserved in output")
    func codeBlockPreservation() {
        let content = """
        ## Code Example

        ```swift
        let x = 42
        print(x)
        ```
        """
        let slides = [Slide(id: 0, content: content)]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("```swift"))
        #expect(html.contains("let x = 42"))
    }

    @Test("HTML special characters in title are escaped")
    func htmlEscapingInTitle() {
        let meta = PresentationMetadata(title: "A <b>Bold</b> & \"Quoted\" Title")
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: meta, slides: slides, theme: darkTheme)

        #expect(html.contains("A &lt;b&gt;Bold&lt;/b&gt; &amp; &quot;Quoted&quot; Title"))
    }

    // MARK: - Edge Cases

    @Test("Empty slides array produces HTML with no sections")
    func emptySlides() {
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: [], theme: darkTheme)

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("class=\"slides\""))
        let sectionCount = html.components(separatedBy: "<section").count - 1
        #expect(sectionCount == 0)
    }

    @Test("Fallback to dark theme when no theme provided and no metadata theme")
    func fallbackTheme() {
        let meta = PresentationMetadata(title: "No Theme")
        let slides = [Slide(id: 0, content: "# Hello")]
        let html = HTMLExportService.exportHTML(metadata: meta, slides: slides, theme: nil)

        // Should fall back to dark theme
        #expect(html.contains("--r-background-color: \(ThemeRegistry.dark.background)"))
    }

    // MARK: - Speaker Notes

    @Test("Slide with notes produces aside element")
    func slideWithNotesProducesAside() {
        let slides = [Slide(id: 0, content: "# Hello\n\n<!-- notes\nSpeaker note here\n-->")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("<aside class=\"notes\">"))
        #expect(html.contains("Speaker note here"))
    }

    @Test("Slide without notes has no aside")
    func slideWithoutNotesNoAside() {
        let slides = [Slide(id: 0, content: "# Hello\n\nJust content")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(!html.contains("<aside class=\"notes\">"))
    }

    @Test("Notes content is HTML-escaped")
    func notesContentIsEscaped() {
        let slides = [Slide(id: 0, content: "# Hello\n\n<!-- notes\nUse <b>bold</b> & \"quotes\"\n-->")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("&lt;b&gt;bold&lt;/b&gt;"))
        #expect(html.contains("&amp;"))
    }

    @Test("Notes work with title layout")
    func notesWithTitleLayout() {
        let slides = [Slide(id: 0, content: "layout: title\n# Title\n\n<!-- notes\nTitle notes\n-->")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"title-slide\""))
        #expect(html.contains("<aside class=\"notes\">Title notes</aside>"))
    }

    @Test("Notes work with two-column layout")
    func notesWithTwoColumnLayout() {
        let slides = [Slide(id: 0, content: "layout: two-column\nLeft\n|||\nRight\n\n<!-- notes\nColumn notes\n-->")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"two-column\""))
        #expect(html.contains("<aside class=\"notes\">Column notes</aside>"))
    }

    @Test("Notes work with image-left layout")
    func notesWithImageLayout() {
        let slides = [Slide(id: 0, content: "layout: image-left\nimage: https://example.com/img.png\n# Caption\n\n<!-- notes\nImage notes\n-->")]
        let html = HTMLExportService.exportHTML(metadata: defaultMetadata, slides: slides, theme: darkTheme)

        #expect(html.contains("class=\"image-layout\""))
        #expect(html.contains("<aside class=\"notes\">Image notes</aside>"))
    }

    // MARK: - Codable Round-Trip

    @Test("ExportHTMLResponse Codable round-trip")
    func responseCodableRoundTrip() throws {
        let original = ExportHTMLResponse(html: "<html>test</html>", slideCount: 5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExportHTMLResponse.self, from: data)

        #expect(decoded.html == original.html)
        #expect(decoded.slideCount == original.slideCount)
    }
}
