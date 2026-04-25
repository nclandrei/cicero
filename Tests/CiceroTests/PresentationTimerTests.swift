import Testing
import Foundation
@testable import Shared

// Tests for the timer state machine that backs Presentation's timer.
// The state machine itself lives in Shared as `PresentationTimerState`
// (a pure-data type with no Foundation Timer source), so it is unit-
// testable without importing the Cicero target. Presentation owns one
// of these and drives it from a scheduled Timer.

@Suite("Presentation timer state machine")
struct PresentationTimerTests {

    // MARK: - startTimer

    @Test("startTimer transitions idle to running and zeroes elapsed")
    func startFromIdle() {
        var t = PresentationTimerState()
        #expect(t.state == .idle)
        t.start()
        #expect(t.state == .running)
        #expect(t.isRunning)
        #expect(t.elapsedSeconds == 0)
    }

    @Test("startTimer resets elapsed even when running")
    func startResetsElapsedWhenRunning() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick(); t.tick()
        #expect(t.elapsedSeconds == 3)
        t.start()
        #expect(t.elapsedSeconds == 0)
        #expect(t.state == .running)
    }

    @Test("startTimer from paused resets and runs fresh")
    func startFromPausedResets() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick()
        t.pause()
        #expect(t.elapsedSeconds == 2)
        t.start()
        #expect(t.state == .running)
        #expect(t.elapsedSeconds == 0)
    }

    // MARK: - pauseTimer

    @Test("pauseTimer transitions running to paused, preserves elapsed")
    func pausePreservesElapsed() {
        var t = PresentationTimerState()
        t.start()
        for _ in 0..<5 { t.tick() }
        #expect(t.elapsedSeconds == 5)
        t.pause()
        #expect(t.state == .paused)
        #expect(!t.isRunning)
        #expect(t.elapsedSeconds == 5)
    }

    @Test("pauseTimer is a no-op when idle")
    func pauseFromIdleIsNoOp() {
        var t = PresentationTimerState()
        t.pause()
        #expect(t.state == .idle)
        #expect(t.elapsedSeconds == 0)
    }

    @Test("pauseTimer is a no-op when already paused")
    func pauseFromPausedIsNoOp() {
        var t = PresentationTimerState()
        t.start()
        t.tick()
        t.pause()
        #expect(t.state == .paused)
        t.pause()
        #expect(t.state == .paused)
        #expect(t.elapsedSeconds == 1)
    }

    @Test("Paused timer does not advance on tick")
    func pausedDoesNotTick() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick()
        t.pause()
        t.tick(); t.tick(); t.tick()
        #expect(t.elapsedSeconds == 2)
    }

    // MARK: - resumeTimer

    @Test("resumeTimer transitions paused to running, accumulates from current elapsed")
    func resumeAccumulates() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick(); t.tick()
        t.pause()
        #expect(t.elapsedSeconds == 3)
        t.resume()
        #expect(t.state == .running)
        t.tick(); t.tick()
        #expect(t.elapsedSeconds == 5)
    }

    @Test("resumeTimer is a no-op when idle")
    func resumeFromIdleIsNoOp() {
        var t = PresentationTimerState()
        t.resume()
        #expect(t.state == .idle)
        #expect(t.elapsedSeconds == 0)
    }

    @Test("resumeTimer is a no-op when already running")
    func resumeFromRunningIsNoOp() {
        var t = PresentationTimerState()
        t.start()
        t.tick()
        t.resume()
        #expect(t.state == .running)
        t.tick()
        #expect(t.elapsedSeconds == 2)
    }

    // MARK: - resetTimer

    @Test("resetTimer zeroes elapsed and goes idle from running")
    func resetFromRunning() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick()
        t.reset()
        #expect(t.state == .idle)
        #expect(t.elapsedSeconds == 0)
    }

    @Test("resetTimer zeroes elapsed and goes idle from paused")
    func resetFromPaused() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick(); t.tick()
        t.pause()
        t.reset()
        #expect(t.state == .idle)
        #expect(t.elapsedSeconds == 0)
    }

    // MARK: - stopTimer (back-compat)

    @Test("stopTimer goes idle and zeroes elapsed (existing semantics)")
    func stopGoesIdleAndZeroes() {
        var t = PresentationTimerState()
        t.start()
        t.tick(); t.tick()
        t.stop()
        #expect(t.state == .idle)
        #expect(t.elapsedSeconds == 0)
    }

    // MARK: - typical user flow

    @Test("Pause-then-resume mid-talk preserves accumulated time")
    func pauseResumeFlow() {
        var t = PresentationTimerState()
        t.start()
        for _ in 0..<10 { t.tick() } // 10 seconds elapsed
        t.pause()
        // user takes a break — ticks during pause should not accumulate
        for _ in 0..<5 { t.tick() }
        #expect(t.elapsedSeconds == 10)
        t.resume()
        for _ in 0..<7 { t.tick() } // resume: 17 seconds total
        #expect(t.elapsedSeconds == 17)
    }
}
