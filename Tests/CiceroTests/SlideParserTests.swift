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

    // MARK: - slideIndex(forLine:in:)

    @Test("slideIndex maps lines to slides in simple deck")
    func slideIndexSimple() {
        let md = """
        # Slide 1

        Body 1

        ---

        # Slide 2

        Body 2

        ---

        # Slide 3
        """
        // Lines:
        // 0: # Slide 1
        // 1: (blank)
        // 2: Body 1
        // 3: (blank)
        // 4: ---
        // 5: (blank)
        // 6: # Slide 2
        // 7: (blank)
        // 8: Body 2
        // 9: (blank)
        // 10: ---
        // 11: (blank)
        // 12: # Slide 3
        #expect(SlideParser.slideIndex(forLine: 0, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 2, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 3, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 4, in: md) == 0) // separator stays on prior slide
        #expect(SlideParser.slideIndex(forLine: 5, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 6, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 8, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 10, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 11, in: md) == 2)
        #expect(SlideParser.slideIndex(forLine: 12, in: md) == 2)
    }

    @Test("slideIndex maps lines inside frontmatter to slide 0")
    func slideIndexFrontmatter() {
        let md = """
        ---
        title: Hi
        theme: ocean
        ---

        # Slide 1

        ---

        # Slide 2
        """
        // 0: ---
        // 1: title: Hi
        // 2: theme: ocean
        // 3: ---
        // 4: (blank)
        // 5: # Slide 1
        // 6: (blank)
        // 7: ---
        // 8: (blank)
        // 9: # Slide 2
        #expect(SlideParser.slideIndex(forLine: 0, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 1, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 3, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 4, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 5, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 7, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 8, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 9, in: md) == 1)
    }

    @Test("slideIndex ignores --- inside code fences")
    func slideIndexCodeFence() {
        let md = """
        # Slide 1

        ```yaml
        ---
        key: value
        ---
        ```

        ---

        # Slide 2
        """
        // 0: # Slide 1
        // 1: (blank)
        // 2: ```yaml
        // 3: ---
        // 4: key: value
        // 5: ---
        // 6: ```
        // 7: (blank)
        // 8: ---
        // 9: (blank)
        // 10: # Slide 2
        #expect(SlideParser.slideIndex(forLine: 3, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 4, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 5, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 8, in: md) == 0) // real separator
        #expect(SlideParser.slideIndex(forLine: 9, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 10, in: md) == 1)
    }

    @Test("slideIndex clamps out-of-range line numbers")
    func slideIndexClamping() {
        let md = """
        # Slide 1

        ---

        # Slide 2
        """
        #expect(SlideParser.slideIndex(forLine: -10, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 999, in: md) == 1)
    }

    @Test("slideIndex handles empty markdown")
    func slideIndexEmpty() {
        #expect(SlideParser.slideIndex(forLine: 0, in: "") == 0)
        #expect(SlideParser.slideIndex(forLine: 5, in: "") == 0)
    }

    @Test("slideIndex handles single-slide deck")
    func slideIndexSingleSlide() {
        let md = """
        # Only

        Content
        """
        #expect(SlideParser.slideIndex(forLine: 0, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 2, in: md) == 0)
    }

    @Test("slideIndex handles consecutive separators (empty slide dropped)")
    func slideIndexConsecutiveSeparators() {
        let md = """
        # Slide 1

        ---

        ---

        # Slide 2
        """
        // 0: # Slide 1
        // 1: (blank)
        // 2: ---
        // 3: (blank)
        // 4: ---
        // 5: (blank)
        // 6: # Slide 2
        // Empty "slide" between separators is dropped by splitSlides, so slide count is 2
        let (_, slides) = SlideParser.parse(md)
        #expect(slides.count == 2)
        #expect(SlideParser.slideIndex(forLine: 0, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 2, in: md) == 0) // first separator
        #expect(SlideParser.slideIndex(forLine: 3, in: md) == 1)
        #expect(SlideParser.slideIndex(forLine: 4, in: md) == 1) // second separator (no content between, stays)
        #expect(SlideParser.slideIndex(forLine: 6, in: md) == 1)
    }

    @Test("slideIndex handles unclosed frontmatter gracefully")
    func slideIndexUnclosedFrontmatter() {
        // Leading `---` with no closing `---` — whole thing is content
        let md = """
        ---
        # Slide 1
        """
        #expect(SlideParser.slideIndex(forLine: 0, in: md) == 0)
        #expect(SlideParser.slideIndex(forLine: 1, in: md) == 0)
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

    // MARK: - Font Parsing Tests

    @Test("Parse font from frontmatter")
    func parseFontFromFrontmatter() {
        let md = """
        ---
        title: Test
        font: Helvetica
        ---

        # Slide 1
        """
        let (meta, _) = SlideParser.parse(md)
        #expect(meta.font == "Helvetica")
    }

    @Test("Serialize font round-trip")
    func serializeFontRoundTrip() {
        let meta = PresentationMetadata(title: "Test", font: "Georgia")
        let slides = [Slide(id: 0, content: "# Hello")]
        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (meta2, _) = SlideParser.parse(serialized)
        #expect(meta2.font == "Georgia")
    }

    @Test("No font in frontmatter")
    func noFontInFrontmatter() {
        let md = """
        ---
        title: Test
        ---

        # Slide 1
        """
        let (meta, _) = SlideParser.parse(md)
        #expect(meta.font == nil)
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

    // MARK: - Speaker Notes Tests

    @Test("Parse notes from HTML comment block")
    func parseNotes() {
        let content = "# Slide Title\n\nContent here\n\n<!-- notes\nRemember to mention the roadmap.\nAlso discuss the timeline.\n-->"
        let slide = Slide(id: 0, content: content)
        #expect(slide.notes == "Remember to mention the roadmap.\nAlso discuss the timeline.")
        #expect(slide.body == "# Slide Title\n\nContent here")
    }

    @Test("Notes stripped from body")
    func notesStrippedFromBody() {
        let content = "# Hello\n\n<!-- notes\nSpeaker note\n-->"
        let slide = Slide(id: 0, content: content)
        #expect(!slide.body.contains("notes"))
        #expect(!slide.body.contains("<!--"))
        #expect(!slide.body.contains("-->"))
        #expect(slide.body == "# Hello")
    }

    @Test("No notes returns nil")
    func noNotesReturnsNil() {
        let slide = Slide(id: 0, content: "# Just a slide\n\nNo notes here")
        #expect(slide.notes == nil)
    }

    @Test("Notes round-trip through serialize/parse")
    func notesRoundTrip() {
        let md = "# Slide 1\n\nContent\n\n<!-- notes\nMy speaker notes\n-->\n\n---\n\n# Slide 2"
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 2)
        #expect(slides[0].notes == "My speaker notes")
        #expect(slides[1].notes == nil)

        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (_, slides2) = SlideParser.parse(serialized)
        #expect(slides2[0].notes == "My speaker notes")
        #expect(slides2[1].notes == nil)
    }

    @Test("Notes coexist with frontmatter")
    func notesCoexistWithFrontmatter() {
        let content = "layout: title\n# Big Title\n\n<!-- notes\nIntro notes\n-->"
        let slide = Slide(id: 0, content: content)
        #expect(slide.layout == .title)
        #expect(slide.notes == "Intro notes")
        #expect(slide.body == "# Big Title")
    }

    @Test("Notes with special characters")
    func notesWithSpecialCharacters() {
        let content = "# Slide\n\n<!-- notes\nUse <angle brackets> & \"quotes\"\n-->"
        let slide = Slide(id: 0, content: content)
        #expect(slide.notes == "Use <angle brackets> & \"quotes\"")
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
