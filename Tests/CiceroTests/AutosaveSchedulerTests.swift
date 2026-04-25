import Testing
import Foundation
@testable import Shared

@Suite("AutosaveScheduler")
struct AutosaveSchedulerTests {

    @Test("New scheduler has no pending save")
    func newSchedulerHasNoPending() {
        let s = AutosaveScheduler(debounceInterval: 2)
        #expect(!s.hasPendingSave)
        #expect(s.pendingSaveDueAt == nil)
        #expect(s.lastSavedAt == nil)
        #expect(s.saveCount == 0)
    }

    @Test("contentChanged schedules save at now + debounce interval")
    func contentChangedSchedules() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        #expect(s.hasPendingSave)
        #expect(s.pendingSaveDueAt == now.addingTimeInterval(2))
    }

    @Test("Second contentChanged resets (debounces) the due time")
    func debouncesMultipleChanges() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let t0 = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: t0)
        let t1 = t0.addingTimeInterval(1) // 1 second later, before due
        s.contentChanged(at: t1)
        #expect(s.pendingSaveDueAt == t1.addingTimeInterval(2))
    }

    @Test("tick before due time does not fire action")
    func tickBeforeDueDoesNotFire() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        let didFire = s.tick(at: now.addingTimeInterval(1)) { fired += 1 }
        #expect(didFire == false)
        #expect(fired == 0)
        #expect(s.hasPendingSave)
    }

    @Test("tick at due time fires action and clears pending")
    func tickAtDueFires() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        let due = now.addingTimeInterval(2)
        let didFire = s.tick(at: due) { fired += 1 }
        #expect(didFire == true)
        #expect(fired == 1)
        #expect(!s.hasPendingSave)
        #expect(s.lastSavedAt == due)
        #expect(s.saveCount == 1)
    }

    @Test("tick after due time fires action")
    func tickAfterDueFires() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        let didFire = s.tick(at: now.addingTimeInterval(5)) { fired += 1 }
        #expect(didFire == true)
        #expect(fired == 1)
    }

    @Test("tick with no pending save does not fire")
    func tickNoPending() {
        let s = AutosaveScheduler(debounceInterval: 2)
        var fired = 0
        let didFire = s.tick(at: Date()) { fired += 1 }
        #expect(didFire == false)
        #expect(fired == 0)
        #expect(s.saveCount == 0)
    }

    @Test("tick after firing does not re-fire")
    func tickAfterFireDoesNotRefire() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        _ = s.tick(at: now.addingTimeInterval(2)) { fired += 1 }
        _ = s.tick(at: now.addingTimeInterval(10)) { fired += 1 }
        #expect(fired == 1)
        #expect(s.saveCount == 1)
    }

    @Test("cancel clears pending save without firing")
    func cancelClearsPending() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        s.cancel()
        #expect(!s.hasPendingSave)
        let didFire = s.tick(at: now.addingTimeInterval(10)) { fired += 1 }
        #expect(didFire == false)
        #expect(fired == 0)
        #expect(s.saveCount == 0)
    }

    @Test("flush fires pending save immediately regardless of due time")
    func flushFiresImmediately() {
        let s = AutosaveScheduler(debounceInterval: 60)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        // only 1 second later, far before 60s debounce:
        let didFire = s.flush(at: now.addingTimeInterval(1)) { fired += 1 }
        #expect(didFire == true)
        #expect(fired == 1)
        #expect(!s.hasPendingSave)
        #expect(s.saveCount == 1)
    }

    @Test("flush with no pending returns false")
    func flushNoPending() {
        let s = AutosaveScheduler(debounceInterval: 2)
        var fired = 0
        let didFire = s.flush(at: Date()) { fired += 1 }
        #expect(didFire == false)
        #expect(fired == 0)
    }

    @Test("Disabled scheduler does not schedule on contentChanged")
    func disabledDoesNotSchedule() {
        let s = AutosaveScheduler(debounceInterval: 2, isEnabled: false)
        s.contentChanged(at: Date())
        #expect(!s.hasPendingSave)
    }

    @Test("Re-enabling allows scheduling again")
    func reEnabling() {
        let s = AutosaveScheduler(debounceInterval: 2, isEnabled: false)
        s.contentChanged(at: Date())
        #expect(!s.hasPendingSave)
        s.isEnabled = true
        s.contentChanged(at: Date())
        #expect(s.hasPendingSave)
    }

    @Test("Disabling cancels a pending save")
    func disablingCancelsPending() {
        let s = AutosaveScheduler(debounceInterval: 2)
        s.contentChanged(at: Date())
        #expect(s.hasPendingSave)
        s.isEnabled = false
        #expect(!s.hasPendingSave)
    }

    @Test("Zero debounce means save is due immediately")
    func zeroDebounceFiresImmediately() {
        let s = AutosaveScheduler(debounceInterval: 0)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)
        var fired = 0
        let didFire = s.tick(at: now) { fired += 1 }
        #expect(didFire == true)
        #expect(fired == 1)
    }

    @Test("Multiple save cycles increment saveCount")
    func multipleCyclesIncrementCount() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let t0 = Date(timeIntervalSince1970: 1000)

        s.contentChanged(at: t0)
        _ = s.tick(at: t0.addingTimeInterval(2)) { }

        s.contentChanged(at: t0.addingTimeInterval(10))
        _ = s.tick(at: t0.addingTimeInterval(12)) { }

        s.contentChanged(at: t0.addingTimeInterval(20))
        _ = s.flush(at: t0.addingTimeInterval(20)) { }

        #expect(s.saveCount == 3)
    }

    @Test("Debounce keeps deferring until quiet period elapses")
    func debounceDefersUntilQuiet() {
        let s = AutosaveScheduler(debounceInterval: 2)
        let t0 = Date(timeIntervalSince1970: 1000)

        // Rapid edits every 1s for 5s — debounce should not fire.
        for i in 0..<5 {
            s.contentChanged(at: t0.addingTimeInterval(Double(i)))
            // tick at the same instant — should not fire because due moved
            _ = s.tick(at: t0.addingTimeInterval(Double(i))) { }
        }
        #expect(s.saveCount == 0)
        #expect(s.hasPendingSave)

        // After a 2-second quiet period, tick fires.
        var fired = 0
        _ = s.tick(at: t0.addingTimeInterval(6)) { fired += 1 }
        #expect(fired == 1)
        #expect(s.saveCount == 1)
    }

    @Test("Action throw propagates and pending state is preserved")
    func actionThrowPreservesPending() {
        struct Boom: Error {}
        let s = AutosaveScheduler(debounceInterval: 2)
        let now = Date(timeIntervalSince1970: 1000)
        s.contentChanged(at: now)

        do {
            _ = try s.tick(at: now.addingTimeInterval(2)) { throw Boom() }
            Issue.record("Expected throw")
        } catch {
            // Still pending because the save didn't succeed; caller can retry.
            #expect(s.hasPendingSave)
            #expect(s.saveCount == 0)
            #expect(s.lastSavedAt == nil)
        }
    }
}
