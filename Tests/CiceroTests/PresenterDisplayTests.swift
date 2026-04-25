import Testing
import Foundation
@testable import Shared

@Suite("Presenter Display State")
struct PresenterDisplayTests {

    // MARK: - Fixtures

    private func slide(id: Int, _ body: String, notes: String? = nil) -> Slide {
        var content = body
        if let notes {
            content += "\n\n<!-- notes\n\(notes)\n-->"
        }
        return Slide(id: id, content: content)
    }

    // MARK: - Empty state

    @Test("Empty slides produce a zero state")
    func emptySlides() {
        let state = PresenterDisplayState.make(
            slides: [],
            currentIndex: 0,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.totalSlides == 0)
        #expect(state.currentIndex == 0)
        #expect(state.currentSlideTitle == nil)
        #expect(state.nextSlideTitle == nil)
        #expect(state.hasNextSlide == false)
        #expect(state.notes == nil)
        #expect(state.slideCounter == "0 / 0")
        #expect(state.progressFraction == 0)
        #expect(state.isLastSlide == false)
    }

    // MARK: - Single slide

    @Test("Single slide: no next, progress full")
    func singleSlide() {
        let slides = [slide(id: 0, "# Intro")]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 0,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.totalSlides == 1)
        #expect(state.currentIndex == 0)
        #expect(state.currentSlideTitle == "Intro")
        #expect(state.nextSlideTitle == nil)
        #expect(state.hasNextSlide == false)
        #expect(state.slideCounter == "1 / 1")
        #expect(state.progressFraction == 1.0)
        #expect(state.isLastSlide == true)
    }

    // MARK: - Multi-slide navigation

    @Test("Middle slide exposes next slide title")
    func middleSlideHasNext() {
        let slides = [
            slide(id: 0, "# First"),
            slide(id: 1, "# Second"),
            slide(id: 2, "# Third"),
        ]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 1,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.currentSlideTitle == "Second")
        #expect(state.nextSlideTitle == "Third")
        #expect(state.hasNextSlide == true)
        #expect(state.slideCounter == "2 / 3")
        #expect(state.isLastSlide == false)
    }

    @Test("Last slide has no next")
    func lastSlideNoNext() {
        let slides = [
            slide(id: 0, "# First"),
            slide(id: 1, "# Second"),
        ]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 1,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.hasNextSlide == false)
        #expect(state.nextSlideTitle == nil)
        #expect(state.isLastSlide == true)
        #expect(state.progressFraction == 1.0)
    }

    // MARK: - Index clamping

    @Test("Negative index clamps to first slide")
    func negativeIndexClamps() {
        let slides = [
            slide(id: 0, "# First"),
            slide(id: 1, "# Second"),
        ]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: -5,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.currentIndex == 0)
        #expect(state.currentSlideTitle == "First")
    }

    @Test("Out-of-range index clamps to last slide")
    func oversizedIndexClamps() {
        let slides = [
            slide(id: 0, "# First"),
            slide(id: 1, "# Second"),
        ]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 99,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.currentIndex == 1)
        #expect(state.currentSlideTitle == "Second")
        #expect(state.hasNextSlide == false)
    }

    // MARK: - Notes

    @Test("Speaker notes surface from current slide")
    func notesFromCurrentSlide() {
        let slides = [
            slide(id: 0, "# First", notes: "Remember to smile"),
            slide(id: 1, "# Second"),
        ]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 0,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.notes == "Remember to smile")
    }

    @Test("Missing notes on current slide resolves to nil")
    func notesMissing() {
        let slides = [slide(id: 0, "# First")]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 0,
            elapsedSeconds: 0,
            wallClock: "10:00"
        )
        #expect(state.notes == nil)
    }

    // MARK: - Timer passthrough

    @Test("Elapsed seconds formatted via TimeFormatting")
    func elapsedFormatted() {
        let slides = [slide(id: 0, "# Intro")]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 0,
            elapsedSeconds: 95,
            wallClock: "10:00"
        )
        #expect(state.elapsedTimeFormatted == "1:35")
    }

    @Test("Wall clock string passes through verbatim")
    func wallClockPassthrough() {
        let slides = [slide(id: 0, "# Intro")]
        let state = PresenterDisplayState.make(
            slides: slides,
            currentIndex: 0,
            elapsedSeconds: 0,
            wallClock: "14:07"
        )
        #expect(state.wallClock == "14:07")
    }

    // MARK: - Progress

    @Test("Progress fraction reflects slide position")
    func progressFraction() {
        let slides = (0..<4).map { slide(id: $0, "# Slide \($0)") }
        let first = PresenterDisplayState.make(slides: slides, currentIndex: 0, elapsedSeconds: 0, wallClock: "")
        let second = PresenterDisplayState.make(slides: slides, currentIndex: 1, elapsedSeconds: 0, wallClock: "")
        let last = PresenterDisplayState.make(slides: slides, currentIndex: 3, elapsedSeconds: 0, wallClock: "")
        #expect(first.progressFraction == 0.25)
        #expect(second.progressFraction == 0.5)
        #expect(last.progressFraction == 1.0)
    }
}
