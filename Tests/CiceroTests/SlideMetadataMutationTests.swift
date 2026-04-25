import Testing
@testable import Shared

@Suite("SlideParser metadata mutation")
struct SlideMetadataMutationTests {

    // MARK: - setSlideMetadataField — layout

    @Test("Set layout on slide with no frontmatter inserts layout line")
    func setLayoutInserts() {
        let content = "# Hello\n\nSome body"
        let updated = SlideParser.setSlideMetadataField(content, key: "layout", value: "title")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .title)
        #expect(slide.body == "# Hello\n\nSome body")
    }

    @Test("Set layout replaces existing layout line, preserves body")
    func setLayoutReplaces() {
        let content = "layout: two-column\n# Hello\nLeft\n|||\nRight"
        let updated = SlideParser.setSlideMetadataField(content, key: "layout", value: "title")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .title)
        #expect(slide.body == "# Hello\nLeft\n|||\nRight")
    }

    @Test("Clearing layout removes the layout line, keeps other metadata")
    func clearLayout() {
        let content = "layout: image-left\nimage: assets/foo.png\n# Slide"
        let updated = SlideParser.setSlideMetadataField(content, key: "layout", value: nil)
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .default)
        #expect(slide.imageURL == "assets/foo.png")
        #expect(slide.body == "# Slide")
    }

    @Test("Set layout preserves image, video, embed, and notes")
    func setLayoutPreservesEverythingElse() {
        let content = "layout: image-left\nimage: assets/foo.png\nvideo: assets/clip.mp4\nembed: https://example.com\n# Title\n\nBody\n\n<!-- notes\nMy notes\n-->"
        let updated = SlideParser.setSlideMetadataField(content, key: "layout", value: "image-right")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .imageRight)
        #expect(slide.imageURL == "assets/foo.png")
        #expect(slide.videoURL == "assets/clip.mp4")
        #expect(slide.embedURL == "https://example.com")
        #expect(slide.notes == "My notes")
        #expect(slide.body == "# Title\n\nBody")
    }

    // MARK: - image / video / embed

    @Test("Set image URL inserts image line")
    func setImageInserts() {
        let content = "# Hi"
        let updated = SlideParser.setSlideMetadataField(content, key: "image", value: "assets/photo.png")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.imageURL == "assets/photo.png")
        #expect(slide.body == "# Hi")
    }

    @Test("Set image URL replaces existing image line")
    func setImageReplaces() {
        let content = "layout: image-left\nimage: old.png\n# Hi"
        let updated = SlideParser.setSlideMetadataField(content, key: "image", value: "new.png")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .imageLeft)
        #expect(slide.imageURL == "new.png")
        #expect(slide.body == "# Hi")
    }

    @Test("Clear image URL removes image line")
    func clearImage() {
        let content = "layout: image-left\nimage: old.png\n# Hi"
        let updated = SlideParser.setSlideMetadataField(content, key: "image", value: nil)
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .imageLeft)
        #expect(slide.imageURL == nil)
        #expect(slide.body == "# Hi")
    }

    @Test("Set video and embed URLs work the same way")
    func setVideoAndEmbed() {
        var content = "# Hi"
        content = SlideParser.setSlideMetadataField(content, key: "video", value: "assets/clip.mp4")
        content = SlideParser.setSlideMetadataField(content, key: "embed", value: "https://example.com")
        let slide = Slide(id: 0, content: content)
        #expect(slide.videoURL == "assets/clip.mp4")
        #expect(slide.embedURL == "https://example.com")
        #expect(slide.body == "# Hi")
    }

    @Test("Mutation preserves speaker notes")
    func mutationPreservesNotes() {
        let content = "# Hi\n\n<!-- notes\nNote text\n-->"
        let updated = SlideParser.setSlideMetadataField(content, key: "layout", value: "title")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .title)
        #expect(slide.notes == "Note text")
        #expect(slide.body == "# Hi")
    }

    @Test("Setting same value is idempotent")
    func idempotent() {
        let content = "layout: title\n# Hi"
        let once = SlideParser.setSlideMetadataField(content, key: "layout", value: "title")
        let twice = SlideParser.setSlideMetadataField(once, key: "layout", value: "title")
        let slide1 = Slide(id: 0, content: once)
        let slide2 = Slide(id: 0, content: twice)
        #expect(slide1.layout == .title)
        #expect(slide2.layout == .title)
        #expect(slide1.body == slide2.body)
    }
}
