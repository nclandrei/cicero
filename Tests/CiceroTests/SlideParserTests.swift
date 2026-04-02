import Testing
@testable import Shared

@Suite("SlideParser")
struct SlideParserTests {

    @Test("Parse basic frontmatter")
    func parseFrontmatter() {
        let md = """
        ---
        title: My Talk
        theme: ocean
        author: Test
        ---

        # Slide 1
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(meta.title == "My Talk")
        #expect(meta.theme == "ocean")
        #expect(meta.author == "Test")
        #expect(slides.count == 1)
    }

    @Test("Parse custom theme fields in frontmatter")
    func parseCustomThemeFields() {
        let md = """
        ---
        theme: custom
        theme_background: #1a1a2e
        theme_text: #ffffff
        theme_heading: #ff0000
        theme_accent: #00ff00
        theme_code_background: #111111
        theme_code_text: #eeeeee
        ---

        # Hello
        """
        let (meta, _) = SlideParser.parse(md)
        #expect(meta.theme == "custom")
        #expect(meta.themeBackground == "#1a1a2e")
        #expect(meta.themeText == "#ffffff")
        #expect(meta.themeHeading == "#ff0000")
        #expect(meta.themeAccent == "#00ff00")
        #expect(meta.themeCodeBackground == "#111111")
        #expect(meta.themeCodeText == "#eeeeee")
    }

    @Test("Split slides on ---")
    func splitSlides() {
        let md = """
        # Slide 1

        ---

        # Slide 2

        ---

        # Slide 3
        """
        let (_, slides) = SlideParser.parse(md)
        #expect(slides.count == 3)
        #expect(slides[0].content.contains("Slide 1"))
        #expect(slides[1].content.contains("Slide 2"))
        #expect(slides[2].content.contains("Slide 3"))
    }

    @Test("Code blocks with --- are not treated as separators")
    func codeBlockPreservation() {
        let md = """
        # Code Example

        ```yaml
        ---
        key: value
        ---
        ```
        """
        let (_, slides) = SlideParser.parse(md)
        #expect(slides.count == 1)
        #expect(slides[0].content.contains("key: value"))
    }

    @Test("Serialize round-trip preserves metadata")
    func serializeRoundTrip() {
        let md = """
        ---
        title: Test
        theme: ocean
        author: Me
        ---

        # Slide 1

        ---

        # Slide 2
        """
        let (meta, slides) = SlideParser.parse(md)
        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (meta2, slides2) = SlideParser.parse(serialized)
        #expect(meta2.title == meta.title)
        #expect(meta2.theme == meta.theme)
        #expect(meta2.author == meta.author)
        #expect(slides2.count == slides.count)
    }

    @Test("Serialize custom theme fields round-trip")
    func serializeCustomThemeRoundTrip() {
        let meta = PresentationMetadata(
            theme: "custom",
            themeBackground: "#112233",
            themeText: "#aabbcc"
        )
        let slides = [Slide(id: 0, content: "# Hello")]
        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (meta2, _) = SlideParser.parse(serialized)
        #expect(meta2.theme == "custom")
        #expect(meta2.themeBackground == "#112233")
        #expect(meta2.themeText == "#aabbcc")
    }

    @Test("No frontmatter produces empty metadata")
    func noFrontmatter() {
        let md = "# Just a slide"
        let (meta, slides) = SlideParser.parse(md)
        #expect(meta.title == nil)
        #expect(meta.theme == nil)
        #expect(slides.count == 1)
    }

    @Test("Slide title extraction")
    func slideTitles() {
        let slide1 = Slide(id: 0, content: "# Main Title\nSome text")
        let slide2 = Slide(id: 1, content: "## Sub Title\nMore text")
        let slide3 = Slide(id: 2, content: "No heading here")
        #expect(slide1.title == "Main Title")
        #expect(slide2.title == "Sub Title")
        #expect(slide3.title == nil)
    }

    // MARK: - Slide Reordering Tests

    @Test("Reorder: move first slide to last")
    func reorderFirstToLast() {
        let slides = [
            Slide(id: 0, content: "# A"),
            Slide(id: 1, content: "# B"),
            Slide(id: 2, content: "# C"),
        ]
        var reordered = slides
        let moved = reordered.remove(at: 0)
        reordered.insert(moved, at: 2)
        #expect(reordered[0].content == "# B")
        #expect(reordered[1].content == "# C")
        #expect(reordered[2].content == "# A")
    }

    @Test("Reorder: move last slide to first")
    func reorderLastToFirst() {
        let slides = [
            Slide(id: 0, content: "# A"),
            Slide(id: 1, content: "# B"),
            Slide(id: 2, content: "# C"),
        ]
        var reordered = slides
        let moved = reordered.remove(at: 2)
        reordered.insert(moved, at: 0)
        #expect(reordered[0].content == "# C")
        #expect(reordered[1].content == "# A")
        #expect(reordered[2].content == "# B")
    }

    @Test("Reorder: adjacent swap")
    func reorderAdjacentSwap() {
        let slides = [
            Slide(id: 0, content: "# A"),
            Slide(id: 1, content: "# B"),
            Slide(id: 2, content: "# C"),
        ]
        var reordered = slides
        let moved = reordered.remove(at: 0)
        reordered.insert(moved, at: 1)
        #expect(reordered[0].content == "# B")
        #expect(reordered[1].content == "# A")
        #expect(reordered[2].content == "# C")
    }

    @Test("Reorder round-trip: parse, reorder, serialize, re-parse")
    func reorderRoundTrip() {
        let md = """
        ---
        title: Test
        ---

        # Slide A

        ---

        # Slide B

        ---

        # Slide C
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 3)

        // Move slide 0 (A) to position 2 (last)
        var reordered = slides
        let moved = reordered.remove(at: 0)
        reordered.insert(moved, at: 2)

        // Re-index
        let reindexed = reordered.enumerated().map { i, s in
            Slide(id: i, content: s.content, body: s.body, layout: s.layout, imageURL: s.imageURL)
        }

        let serialized = SlideParser.serialize(metadata: meta, slides: reindexed)
        let (meta2, slides2) = SlideParser.parse(serialized)

        #expect(meta2.title == "Test")
        #expect(slides2.count == 3)
        #expect(slides2[0].title == "Slide B")
        #expect(slides2[1].title == "Slide C")
        #expect(slides2[2].title == "Slide A")
    }

    @Test("Reorder preserves frontmatter in slides")
    func reorderPreservesFrontmatter() {
        let md = """
        layout: title
        # Title Slide

        ---

        ## Content Slide

        Some text
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 2)
        #expect(slides[0].layout == .title)

        // Swap the two slides
        var reordered = slides
        let moved = reordered.remove(at: 0)
        reordered.insert(moved, at: 1)
        let reindexed = reordered.enumerated().map { i, s in
            Slide(id: i, content: s.content, body: s.body, layout: s.layout, imageURL: s.imageURL)
        }

        let serialized = SlideParser.serialize(metadata: meta, slides: reindexed)
        let (_, slides2) = SlideParser.parse(serialized)

        #expect(slides2.count == 2)
        #expect(slides2[0].title == "Content Slide")
        #expect(slides2[1].layout == .title)
        #expect(slides2[1].title == "Title Slide")
    }

    @Test("Same position is a no-op")
    func reorderSamePosition() {
        let slides = [
            Slide(id: 0, content: "# A"),
            Slide(id: 1, content: "# B"),
        ]
        let reordered = slides
        // "Move" from 0 to 0 — no-op
        #expect(reordered[0].content == slides[0].content)
        #expect(reordered[1].content == slides[1].content)
    }

    // MARK: - Video & Embed Tests

    @Test("Parse video frontmatter")
    func parseVideoFrontmatter() {
        let content = "layout: video\nvideo: assets/demo.mp4\n# Optional overlay"
        let slide = Slide(id: 0, content: content)
        #expect(slide.layout == .video)
        #expect(slide.videoURL == "assets/demo.mp4")
        #expect(slide.body == "# Optional overlay")
    }

    @Test("Parse embed frontmatter")
    func parseEmbedFrontmatter() {
        let content = "layout: embed\nembed: https://www.youtube.com/embed/dQw4w9WgXcQ\n# Demo"
        let slide = Slide(id: 0, content: content)
        #expect(slide.layout == .embed)
        #expect(slide.embedURL == "https://www.youtube.com/embed/dQw4w9WgXcQ")
        #expect(slide.body == "# Demo")
    }

    @Test("Video slide serialize round-trip")
    func videoSlideSerializeRoundTrip() {
        let md = """
        layout: video
        video: assets/demo.mp4
        # Overlay text
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 1)
        #expect(slides[0].layout == .video)
        #expect(slides[0].videoURL == "assets/demo.mp4")

        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (_, slides2) = SlideParser.parse(serialized)
        #expect(slides2.count == 1)
        #expect(slides2[0].layout == .video)
        #expect(slides2[0].videoURL == "assets/demo.mp4")
    }

    @Test("Embed slide serialize round-trip")
    func embedSlideSerializeRoundTrip() {
        let md = """
        layout: embed
        embed: https://example.com/widget
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 1)
        #expect(slides[0].layout == .embed)
        #expect(slides[0].embedURL == "https://example.com/widget")

        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (_, slides2) = SlideParser.parse(serialized)
        #expect(slides2.count == 1)
        #expect(slides2[0].layout == .embed)
        #expect(slides2[0].embedURL == "https://example.com/widget")
    }

    @Test("Video and image coexist on same slide")
    func videoAndImageCoexist() {
        let content = "layout: video\nvideo: assets/demo.mp4\nimage: assets/poster.png\n# Title"
        let slide = Slide(id: 0, content: content)
        #expect(slide.layout == .video)
        #expect(slide.videoURL == "assets/demo.mp4")
        #expect(slide.imageURL == "assets/poster.png")
        #expect(slide.body == "# Title")
    }

    @Test("Reorder preserves video and embed metadata")
    func reorderPreservesVideoEmbed() {
        let md = """
        layout: video
        video: assets/clip.mp4
        # Video Slide

        ---

        layout: embed
        embed: https://example.com
        # Embed Slide

        ---

        # Normal Slide
        """
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 3)
        #expect(slides[0].videoURL == "assets/clip.mp4")
        #expect(slides[1].embedURL == "https://example.com")

        // Move last slide to first
        var reordered = slides
        let moved = reordered.remove(at: 2)
        reordered.insert(moved, at: 0)
        let reindexed = reordered.enumerated().map { i, s in
            Slide(id: i, content: s.content, body: s.body, layout: s.layout, imageURL: s.imageURL, videoURL: s.videoURL, embedURL: s.embedURL)
        }

        let serialized = SlideParser.serialize(metadata: meta, slides: reindexed)
        let (_, slides2) = SlideParser.parse(serialized)
        #expect(slides2.count == 3)
        #expect(slides2[0].title == "Normal Slide")
        #expect(slides2[1].layout == .video)
        #expect(slides2[1].videoURL == "assets/clip.mp4")
        #expect(slides2[2].layout == .embed)
        #expect(slides2[2].embedURL == "https://example.com")
    }
}
