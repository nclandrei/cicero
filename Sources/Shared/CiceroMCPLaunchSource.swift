import Foundation

/// Describes how the Cicero MCP server should be launched on the user's
/// machine. Two cases:
///   - `.bundled`: the pre-built `CiceroMCP` binary that ships inside
///     `Cicero.app/Contents/MacOS/CiceroMCP` (used by users who installed
///     via the released `.app` / Homebrew cask).
///   - `.source(packagePath:)`: a SwiftPM checkout containing `Package.swift`
///     where we can `swift run --package-path … CiceroMCP` (dev-builds).
///
/// The enum is the single source of truth for what command + args we write
/// into MCP client config files (Claude Desktop, Cursor, Codex, etc.).
public enum CiceroMCPLaunchSource: Equatable, Sendable {
    /// Absolute path to the pre-built `CiceroMCP` executable.
    case bundled(URL)
    /// Path to the directory containing `Package.swift`.
    case source(packagePath: URL)

    /// File-existence-aware detection. Tries the bundled binary first,
    /// then walks up from the executable URL looking for `Package.swift`,
    /// then falls back to `currentDirectoryPath`.
    ///
    /// All file-system access is funnelled through `fileExists` so tests
    /// can inject a synthetic universe.
    public static func detect(
        bundleURL: URL,
        executableURL: URL?,
        currentDirectoryPath: String,
        fileExists: (URL) -> Bool
    ) -> CiceroMCPLaunchSource? {
        // 1. Bundled binary wins if it exists.
        let bundledBinary = bundleURL.appendingPathComponent("Contents/MacOS/CiceroMCP")
        if fileExists(bundledBinary) {
            return .bundled(bundledBinary)
        }

        // 2. Walk up from the executable URL looking for Package.swift
        //    (development case: `swift run Cicero` from a checkout).
        if let exec = executableURL {
            var dir = exec.deletingLastPathComponent()
            for _ in 0..<10 {
                if fileExists(dir.appendingPathComponent("Package.swift")) {
                    return .source(packagePath: dir)
                }
                let parent = dir.deletingLastPathComponent()
                if parent.path == dir.path { break }
                dir = parent
            }
        }

        // 3. Fall back to the process's current working directory.
        let cwd = URL(fileURLWithPath: currentDirectoryPath)
        if fileExists(cwd.appendingPathComponent("Package.swift")) {
            return .source(packagePath: cwd)
        }

        return nil
    }

    /// Path to display in the Settings UI (folder/file icon row).
    public var displayPath: String {
        switch self {
        case .bundled(let url):           return url.path
        case .source(let packagePath):    return packagePath.path
        }
    }

    /// JSON dictionary for `mcpServers["cicero"]` (or the OpenCode variant
    /// when `forOpenCode` is true).
    public func serverEntry(forOpenCode: Bool) -> [String: Any] {
        if forOpenCode {
            return [
                "type": "local",
                "command": commandArray,
                "enabled": true,
            ]
        }
        switch self {
        case .bundled(let url):
            return [
                "command": url.path,
                "args": [String](),
            ]
        case .source(let packagePath):
            return [
                "command": "swift",
                "args": ["run", "--package-path", packagePath.path, "CiceroMCP"],
            ]
        }
    }

    /// Single-string argv list used by OpenCode's `command` field.
    public var commandArray: [String] {
        switch self {
        case .bundled(let url):
            return [url.path]
        case .source(let packagePath):
            return ["swift", "run", "--package-path", packagePath.path, "CiceroMCP"]
        }
    }

    /// Codex-style TOML block. Paths are emitted via `TOMLString.quote`,
    /// which prefers a literal string for typical filesystem paths and
    /// only falls back to an escaped basic string when the path contains
    /// a single quote. Spaces, backslashes, and double quotes round-trip
    /// untouched in the literal-string form.
    public func tomlEntry() -> String {
        switch self {
        case .bundled(let url):
            let command = TOMLString.quote(url.path)
            return """

                [mcp_servers.cicero]
                command = \(command)
                args = []

                """
        case .source(let packagePath):
            let path = TOMLString.quote(packagePath.path)
            return """

                [mcp_servers.cicero]
                command = "swift"
                args = ["run", "--package-path", \(path), "CiceroMCP"]

                """
        }
    }
}
