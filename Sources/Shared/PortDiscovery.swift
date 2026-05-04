import Foundation

/// File-based discovery of the port the running Cicero app is listening
/// on. The HTTP port is user-configurable via Settings, so the bundled
/// CiceroMCP proxy can no longer assume `CiceroConstants.httpPort` —
/// it must learn the chosen port at startup.
///
/// Resolution order (caller responsibility):
///   1. `CICERO_PORT` environment variable (override / scripted runs).
///   2. The discovery file, written by the app on successful bind.
///   3. The compiled-in `AppDefaultsStore.fallbackHTTPPort`.
///
/// All file paths are derived purely so the helper is unit-testable
/// without touching the user's filesystem.
public enum PortDiscovery {

    /// Name of the discovery file inside `~/Library/Application Support/Cicero`.
    public static let discoveryFilename = "server-port"

    /// Environment variable consulted by `resolve(env:fileReader:)`.
    public static let envVarName = "CICERO_PORT"

    /// Resolves the active port, given the process environment and a
    /// reader closure (so tests can inject content). Returns the first
    /// successfully parsed port in [env, file] order, or `fallback`
    /// when none is available.
    public static func resolve(
        env: [String: String],
        fileReader: () -> String?,
        fallback: Int
    ) -> Int {
        if let raw = env[envVarName], let parsed = parse(raw) {
            return parsed
        }
        if let raw = fileReader(), let parsed = parse(raw) {
            return parsed
        }
        return fallback
    }

    /// Encode `port` as the on-disk discovery file content. Trailing
    /// newline so editors don't complain.
    public static func encode(_ port: Int) -> String {
        "\(port)\n"
    }

    /// Parse an arbitrary string into a port. Trims whitespace, requires
    /// the value to fall in the allowed user-port range. Returns nil
    /// for empty, garbage, or out-of-range input.
    public static func parse(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int(trimmed) else { return nil }
        return AppDefaultsValidator.isValidPort(value) ? value : nil
    }
}
