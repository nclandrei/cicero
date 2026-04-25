import Foundation

public enum CiceroConstants {
    public static let httpPort: UInt16 = 19847
    public static let httpHost = "localhost"
    /// The IPv4 address the HTTP server binds to. Loopback only — never expose
    /// the IPC channel to other hosts on the network.
    public static let httpLoopbackAddress = "127.0.0.1"
    public static let httpBaseURL = "http://localhost:19847"
    public static let appBundleIdentifier = "com.andreinicolas.Cicero"
}

/// Validation helpers for presentation-level metadata (theme, font, transition).
public enum MetadataValidator {
    public static func isValidTheme(_ name: String) -> Bool {
        if name.isEmpty { return false }
        if name == "auto" || name == "custom" { return true }
        return ThemeRegistry.find(name) != nil
    }

    public static func isValidFont(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return CuratedFonts.all.contains { $0.lowercased() == trimmed.lowercased() }
    }

    public static func isValidTransition(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return PresentationTransition(rawValue: name) != nil
    }
}
