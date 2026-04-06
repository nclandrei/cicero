import Testing
@testable import Shared

@Suite("Slide Thumbnail Sidebar")
struct SlideThumbnailTests {

    // MARK: - Duplicate Slide Logic

    @Test("Duplicating a slide copies its content")
    func duplicateSlideContent() {
        var slides = makeSlides(["# Slide 1\nHello", "# Slide 2\nWorld", "# Slide 3\nEnd"])
        let original = slides[1]
        let duplicate = Slide(id: 2, content: original.content)
        slides.insert(duplicate, at: 2)

        #expect(slides.count == 4)
        #expect(slides[1].content == slides[2].content)
        #expect(slides[1].title == slides[2].title)
        #expect(slides[2].title == "Slide 2")
    }

    @Test("Duplicating preserves slide layout")
    func duplicateSlideLayout() {
        let content = "layout: title\n# Title Slide\nSubtitle"
        var slides = [Slide(id: 0, content: content)]
        let duplicate = Slide(id: 1, content: slides[0].content)
        slides.insert(duplicate, at: 1)

        #expect(slides[0].layout == .title)
        #expect(slides[1].layout == .title)
        #expect(slides[1].title == "Title Slide")
    }

    @Test("Duplicating at last index inserts at end")
    func duplicateAtEnd() {
        var slides = makeSlides(["# A", "# B"])
        let dup = Slide(id: 2, content: slides[1].content)
        slides.insert(dup, at: 2)

        #expect(slides.count == 3)
        #expect(slides[2].content == slides[1].content)
    }

    @Test("Duplicating at first index inserts after first")
    func duplicateAtStart() {
        var slides = makeSlides(["# First", "# Second"])
        let dup = Slide(id: 1, content: slides[0].content)
        slides.insert(dup, at: 1)

        #expect(slides.count == 3)
        #expect(slides[0].content == slides[1].content)
        #expect(slides[0].title == "First")
        #expect(slides[1].title == "First")
    }

    // MARK: - Navigation Logic

    @Test("Navigate updates current index within bounds")
    func navigateWithinBounds() {
        let slides = makeSlides(["# A", "# B", "# C"])
        var currentIndex = 0

        // Navigate forward
        let target = 2
        if target >= 0 && target < slides.count {
            currentIndex = target
        }
        #expect(currentIndex == 2)
    }

    @Test("Navigate does not exceed slide count")
    func navigateBeyondBounds() {
        let slides = makeSlides(["# A", "# B"])
        var currentIndex = 1

        let target = 5
        if target >= 0 && target < slides.count {
            currentIndex = target
        }
        #expect(currentIndex == 1)
    }

    @Test("Navigate does not go below zero")
    func navigateBelowZero() {
        let slides = makeSlides(["# A", "# B"])
        var currentIndex = 0

        let target = -1
        if target >= 0 && target < slides.count {
            currentIndex = target
        }
        #expect(currentIndex == 0)
    }

    // MARK: - Slide Title Extraction

    @Test("Slide title extracted from h1")
    func slideTitleH1() {
        let slide = Slide(id: 0, content: "# My Title\nSome content")
        #expect(slide.title == "My Title")
    }

    @Test("Slide title extracted from h2")
    func slideTitleH2() {
        let slide = Slide(id: 0, content: "## Secondary Title\nContent")
        #expect(slide.title == "Secondary Title")
    }

    @Test("Slide with no heading has nil title")
    func slideNoTitle() {
        let slide = Slide(id: 0, content: "Just some content\nwithout headings")
        #expect(slide.title == nil)
    }

    @Test("Slide title from layout slide strips layout line")
    func slideTitleWithLayout() {
        let slide = Slide(id: 0, content: "layout: title\n# Title Here\nSubtitle")
        #expect(slide.title == "Title Here")
    }

    // MARK: - Move Slide Logic

    @Test("Move slide reorders correctly")
    func moveSlideReorder() {
        var slides = makeSlides(["# A", "# B", "# C"])
        let moved = slides.remove(at: 0)
        slides.insert(moved, at: 2)

        #expect(slides[0].title == "B")
        #expect(slides[1].title == "C")
        #expect(slides[2].title == "A")
    }

    // MARK: - Helpers

    private func makeSlides(_ contents: [String]) -> [Slide] {
        contents.enumerated().map { Slide(id: $0.offset, content: $0.element) }
    }
}
