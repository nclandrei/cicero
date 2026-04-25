import Foundation

public enum SaveAsPathResult: Equatable, Sendable {
    case valid
    case empty
    case notAbsolute
    case parentNotCreatable(reason: String)
}

/// Validates a destination path for `save_as`. Used by HTTP handler to
/// fail fast with a structured 400 before mutating presentation state.
public enum SaveAsPathValidator {
    public static func validate(_ path: String) -> SaveAsPathResult {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.hasPrefix("/") else { return .notAbsolute }

        let url = URL(fileURLWithPath: trimmed)
        let parent = url.deletingLastPathComponent()
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: parent.path, isDirectory: &isDir) {
            if isDir.boolValue {
                // Parent already exists and is a directory — valid.
                guard fm.isWritableFile(atPath: parent.path) else {
                    return .parentNotCreatable(reason: "Parent directory '\(parent.path)' is not writable")
                }
                return .valid
            } else {
                return .parentNotCreatable(reason: "Parent path '\(parent.path)' exists but is not a directory")
            }
        }
        // Walk up until we find an existing ancestor; if any ancestor is non-writable, fail.
        var ancestor = parent
        while !fm.fileExists(atPath: ancestor.path) {
            let next = ancestor.deletingLastPathComponent()
            if next.path == ancestor.path { break }
            ancestor = next
        }
        if !fm.fileExists(atPath: ancestor.path) {
            return .parentNotCreatable(reason: "No writable ancestor directory found for \(path)")
        }
        if !fm.isWritableFile(atPath: ancestor.path) {
            return .parentNotCreatable(reason: "Ancestor directory '\(ancestor.path)' is not writable")
        }
        return .valid
    }
}
