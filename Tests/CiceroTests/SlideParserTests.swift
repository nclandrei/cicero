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
}
