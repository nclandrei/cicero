import Foundation

/// Lifecycle states for the presentation timer.
public enum PresentationTimerLifecycle: String, Codable, Sendable {
    case idle
    case running
    case paused
}

/// Pure-data state machine that backs Presentation's elapsed-seconds timer.
/// The actual `Timer.scheduledTimer` source lives on Presentation; this type
/// only tracks lifecycle and elapsed seconds, so it's deterministically
/// testable in isolation. Presentation drives `tick()` from its scheduled
/// Timer's repeating callback.
///
/// Transitions:
/// - `start()`  — any → `.running`, elapsedSeconds = 0 (fresh start)
/// - `pause()`  — `.running` → `.paused`, elapsedSeconds preserved (no-op otherwise)
/// - `resume()` — `.paused` → `.running`, elapsedSeconds preserved (no-op otherwise)
/// - `reset()`  — any → `.idle`, elapsedSeconds = 0
/// - `stop()`   — any → `.idle`, elapsedSeconds = 0 (back-compat alias for reset)
public struct PresentationTimerState: Sendable {
    public private(set) var state: PresentationTimerLifecycle
    public private(set) var elapsedSeconds: Int

    public var isRunning: Bool { state == .running }

    public init(state: PresentationTimerLifecycle = .idle, elapsedSeconds: Int = 0) {
        self.state = state
        self.elapsedSeconds = elapsedSeconds
    }

    public mutating func start() {
        elapsedSeconds = 0
        state = .running
    }

    public mutating func pause() {
        guard state == .running else { return }
        state = .paused
    }

    public mutating func resume() {
        guard state == .paused else { return }
        state = .running
    }

    public mutating func reset() {
        elapsedSeconds = 0
        state = .idle
    }

    public mutating func stop() {
        // Back-compat: stop fully clears state and elapsed. Equivalent to reset().
        elapsedSeconds = 0
        state = .idle
    }

    /// Advance the elapsed counter by one second. No-op unless running.
    /// Presentation's scheduled Timer calls this once per second.
    public mutating func tick() {
        guard state == .running else { return }
        elapsedSeconds += 1
    }
}
