import Foundation

/// Deterministic, clock-injected debounce scheduler for autosave.
///
/// Pure logic: callers pass `Date` values for `now` and supply the save action
/// as a closure to `tick` / `flush`. Real timers live at the integration layer
/// (the app holds a repeating `Timer` that calls `tick(at: Date())`).
public final class AutosaveScheduler {
    public var debounceInterval: TimeInterval
    public var isEnabled: Bool {
        didSet {
            if !isEnabled { cancel() }
        }
    }

    public private(set) var pendingSaveDueAt: Date?
    public private(set) var lastSavedAt: Date?
    public private(set) var saveCount: Int = 0

    public var hasPendingSave: Bool { pendingSaveDueAt != nil }

    public init(debounceInterval: TimeInterval = 2.0, isEnabled: Bool = true) {
        self.debounceInterval = debounceInterval
        self.isEnabled = isEnabled
    }

    /// Record a content change. Schedules (or reschedules) the autosave for
    /// `now + debounceInterval`. No-op when disabled.
    public func contentChanged(at now: Date) {
        guard isEnabled else { return }
        pendingSaveDueAt = now.addingTimeInterval(debounceInterval)
    }

    /// Advance the clock. If a save is pending and due at/before `now`, run
    /// `action` and clear the pending save. Returns whether the action fired.
    ///
    /// If `action` throws, the pending state is preserved so the caller can retry.
    @discardableResult
    public func tick(at now: Date, action: () throws -> Void) rethrows -> Bool {
        guard let due = pendingSaveDueAt, now >= due else { return false }
        try action()
        pendingSaveDueAt = nil
        lastSavedAt = now
        saveCount += 1
        return true
    }

    /// Fire any pending save immediately, ignoring the due time. Returns
    /// whether a save fired. Preserves pending state if `action` throws.
    @discardableResult
    public func flush(at now: Date, action: () throws -> Void) rethrows -> Bool {
        guard pendingSaveDueAt != nil else { return false }
        try action()
        pendingSaveDueAt = nil
        lastSavedAt = now
        saveCount += 1
        return true
    }

    /// Drop any pending save without firing it.
    public func cancel() {
        pendingSaveDueAt = nil
    }
}
