import Testing
@testable import Shared

@Suite("SlideAccessibility")
struct SlideAccessibilityTests {

    @Test("Thumbnail label without title uses index and total only")
    func thumbnailLabelNoTitle() {
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 5, title: nil) == "Slide 1 of 5")
        #expect(SlideAccessibility.thumbnailLabel(index: 4, total: 5, title: nil) == "Slide 5 of 5")
    }

    @Test("Thumbnail label appends title when present")
    func thumbnailLabelWithTitle() {
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 3, title: "Intro") == "Slide 1 of 3: Intro")
        #expect(SlideAccessibility.thumbnailLabel(index: 2, total: 3, title: "Goodbye") == "Slide 3 of 3: Goodbye")
    }

    @Test("Empty or whitespace title is treated as missing")
    func thumbnailLabelEmptyTitle() {
        #expect(SlideAccessibility.thumbnailLabel(index: 1, total: 4, title: "") == "Slide 2 of 4")
        #expect(SlideAccessibility.thumbnailLabel(index: 1, total: 4, title: "   ") == "Slide 2 of 4")
        #expect(SlideAccessibility.thumbnailLabel(index: 1, total: 4, title: "\n\t") == "Slide 2 of 4")
    }

    @Test("Title is trimmed of surrounding whitespace and newlines")
    func thumbnailLabelTrimsTitle() {
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 2, title: "  Hello  ") == "Slide 1 of 2: Hello")
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 2, title: "\nHello\n") == "Slide 1 of 2: Hello")
    }

    @Test("Single-slide presentation")
    func thumbnailLabelSingleSlide() {
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 1, title: "Only") == "Slide 1 of 1: Only")
        #expect(SlideAccessibility.thumbnailLabel(index: 0, total: 1, title: nil) == "Slide 1 of 1")
    }
}
