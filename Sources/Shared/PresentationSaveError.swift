import Foundation

/// Errors thrown by the presentation save path. Lives in `Shared` so both
/// the Cicero app target (which throws them) and the test target (which
/// asserts on them) can refer to the same type. The HTTP layer maps these
/// onto 4xx responses; the MCP layer maps them onto user-facing error text.
public enum PresentationSaveError: Error, LocalizedError, Equatable, Sendable {
    /// `save()` was called when the presentation has no file path yet.
    /// The caller should run `save_as` (or open/create a file) first.
    case noFilePath
    /// The file on disk was modified by something else (a different
    /// editor, a sync agent) since Cicero last touched it. The caller
    /// should reload the file or pass `force: true` to overwrite.
    case externalConflict(path: String)

    public var errorDescription: String? {
        switch self {
        case .noFilePath:
            return "No file path set; call save_as first."
        case .externalConflict(let path):
            return "The file at \(path) was modified outside Cicero. Reload to see the external changes, or save again with force=true to overwrite."
        }
    }
}
