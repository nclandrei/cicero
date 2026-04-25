import Foundation

/// Pure-data snapshot of what the speaker-view window should render.
/// The audience window shows only the current slide; the presenter display
/// augments it with the next slide, speaker notes, timers, and progress.
public struct PresenterDisplayState: Sendable, Equatable {
    public let currentIndex: Int
    public let totalSlides: Int
    public let currentSlideTitle: String?
    public let nextSlideTitle: String?
    public let hasNextSlide: Bool
    public let isLastSlide: Bool
    public let notes: String?
    public let elapsedTimeFormatted: String
    public let wallClock: String
    public let slideCounter: String
    public let progressFraction: Double

    public init(
        currentIndex: Int,
        totalSlides: Int,
        currentSlideTitle: String?,
        nextSlideTitle: String?,
        hasNextSlide: Bool,
        isLastSlide: Bool,
        notes: String?,
        elapsedTimeFormatted: String,
        wallClock: String,
        slideCounter: String,
        progressFraction: Double
    ) {
        self.currentIndex = currentIndex
        self.totalSlides = totalSlides
        self.currentSlideTitle = currentSlideTitle
        self.nextSlideTitle = nextSlideTitle
        self.hasNextSlide = hasNextSlide
        self.isLastSlide = isLastSlide
        self.notes = notes
        self.elapsedTimeFormatted = elapsedTimeFormatted
        self.wallClock = wallClock
        self.slideCounter = slideCounter
        self.progressFraction = progressFraction
    }

    public static func make(
        slides: [Slide],
        currentIndex: Int,
        elapsedSeconds: Int,
        wallClock: String
    ) -> PresenterDisplayState {
        let total = slides.count
        let elapsed = TimeFormatting.elapsedTime(seconds: elapsedSeconds)

        guard total > 0 else {
            return PresenterDisplayState(
                currentIndex: 0,
                totalSlides: 0,
                currentSlideTitle: nil,
                nextSlideTitle: nil,
                hasNextSlide: false,
                isLastSlide: false,
                notes: nil,
                elapsedTimeFormatted: elapsed,
                wallClock: wallClock,
                slideCounter: "0 / 0",
                progressFraction: 0
            )
        }

        let clamped = max(0, min(currentIndex, total - 1))
        let current = slides[clamped]
        let nextIndex = clamped + 1
        let next: Slide? = nextIndex < total ? slides[nextIndex] : nil

        return PresenterDisplayState(
            currentIndex: clamped,
            totalSlides: total,
            currentSlideTitle: current.title,
            nextSlideTitle: next?.title,
            hasNextSlide: next != nil,
            isLastSlide: clamped == total - 1,
            notes: current.notes,
            elapsedTimeFormatted: elapsed,
            wallClock: wallClock,
            slideCounter: "\(clamped + 1) / \(total)",
            progressFraction: Double(clamped + 1) / Double(total)
        )
    }
}
