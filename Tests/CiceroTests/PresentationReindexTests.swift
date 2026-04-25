import Testing
import Foundation
@testable import Shared

// Tests that reindexing a slide array preserves all fields on each Slide.
// The bug: Presentation.reindexSlides previously re-initialized each Slide
// forwarding only `imageURL`, dropping videoURL, embedURL, notes, and a
// non-default layout. After this fix, reindexing should ONLY mutate the id
// (index) and preserve every other field.

@Suite("Slide reindex preserves fields")
struct PresentationReindexTests {

    @Test("Reindexing assigns sequential ids starting at 0")
    func reindexAssignsSequentialIds() {
        var slides: [Slide] = [
            Slide(id: 5, content: "# A"),
            Slide(id: 9, content: "# B"),
            Slide(id: 12, content: "# C"),
        ]
        slides.reindex()
        #expect(slides.map(\.id) == [0, 1, 2])
    }

    @Test("Reindex preserves content, body, and layout")
    func reindexPreservesContentLayout() {
        var slides: [Slide] = [
            Slide(
                id: 99,
                content: "layout: title\n# Hello",
                body: "# Hello",
                layout: .title,
                imageURL: nil
            )
        ]
        slides.reindex()
        #expect(slides[0].id == 0)
        #expect(slides[0].content == "layout: title\n# Hello")
        #expect(slides[0].body == "# Hello")
        #expect(slides[0].layout == .title)
    }

    @Test("Reindex preserves imageURL")
    func reindexPreservesImageURL() {
        var slides: [Slide] = [
            Slide(
                id: 0,
                content: "image: foo.png\n# X",
                body: "# X",
                layout: .imageLeft,
                imageURL: "foo.png"
            )
        ]
        slides.reindex()
        #expect(slides[0].imageURL == "foo.png")
    }

    @Test("Reindex preserves videoURL")
    func reindexPreservesVideoURL() {
        var slides: [Slide] = [
            Slide(
                id: 0,
                content: "layout: video\nvideo: https://example.com/v.mp4\n# X",
                body: "# X",
                layout: .video,
                imageURL: nil,
                videoURL: "https://example.com/v.mp4"
            )
        ]
        slides.reindex()
        #expect(slides[0].videoURL == "https://example.com/v.mp4")
        #expect(slides[0].layout == .video)
    }

    @Test("Reindex preserves embedURL")
    func reindexPreservesEmbedURL() {
        var slides: [Slide] = [
            Slide(
                id: 0,
                content: "layout: embed\nembed: https://example.com\n# X",
                body: "# X",
                layout: .embed,
                imageURL: nil,
                videoURL: nil,
                embedURL: "https://example.com"
            )
        ]
        slides.reindex()
        #expect(slides[0].embedURL == "https://example.com")
        #expect(slides[0].layout == .embed)
    }

    @Test("Reindex preserves notes")
    func reindexPreservesNotes() {
        var slides: [Slide] = [
            Slide(
                id: 0,
                content: "# X\n\n<!-- notes\nspeaker notes\n-->",
                body: "# X",
                layout: .default,
                imageURL: nil,
                videoURL: nil,
                embedURL: nil,
                notes: "speaker notes"
            )
        ]
        slides.reindex()
        #expect(slides[0].notes == "speaker notes")
    }

    @Test("Reindex preserves all fields together across multiple slides")
    func reindexPreservesAllFieldsAcrossSlides() {
        var slides: [Slide] = [
            Slide(
                id: 7,
                content: "layout: video\nvideo: v1\n# A",
                body: "# A",
                layout: .video,
                imageURL: nil,
                videoURL: "v1"
            ),
            Slide(
                id: 8,
                content: "layout: embed\nembed: e1\n# B",
                body: "# B",
                layout: .embed,
                imageURL: nil,
                videoURL: nil,
                embedURL: "e1"
            ),
            Slide(
                id: 9,
                content: "image: img.png\n# C\n\n<!-- notes\nN\n-->",
                body: "# C",
                layout: .imageRight,
                imageURL: "img.png",
                videoURL: nil,
                embedURL: nil,
                notes: "N"
            ),
        ]
        slides.reindex()
        #expect(slides[0].id == 0)
        #expect(slides[0].videoURL == "v1")
        #expect(slides[0].layout == .video)
        #expect(slides[1].id == 1)
        #expect(slides[1].embedURL == "e1")
        #expect(slides[1].layout == .embed)
        #expect(slides[2].id == 2)
        #expect(slides[2].imageURL == "img.png")
        #expect(slides[2].notes == "N")
        #expect(slides[2].layout == .imageRight)
    }
}
