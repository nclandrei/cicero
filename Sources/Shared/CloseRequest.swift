import Foundation

/// Request body for `POST /close`. Optional `force` flag distinguishes a
/// safe close (refused when the buffer is dirty) from a deliberate
/// discard. The MCP `close_file` tool advertises a matching `force: bool`
/// argument.
public struct CloseRequest: Codable, Sendable {
    public let force: Bool?

    public init(force: Bool? = nil) {
        self.force = force
    }
}

/// Pure policy function: should the server refuse a close because the
/// buffer is dirty? Lives in `Shared` so tests can pin the behavior
/// without touching the HTTP server.
public enum ClosePolicy {
    /// Returns `true` when the close must be refused. The rule is:
    /// reject iff the buffer is dirty AND the caller did not pass force.
    public static func shouldReject(isDirty: Bool, force: Bool?) -> Bool {
        isDirty && (force ?? false) == false
    }
}
