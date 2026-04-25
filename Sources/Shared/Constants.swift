import Foundation

public enum CiceroConstants {
    public static let httpPort: UInt16 = 19847
    public static let httpHost = "localhost"
    public static let httpBaseURL = "http://localhost:19847"
    public static let appBundleIdentifier = "com.andreinicolas.Cicero"
}

/// Curated set of font families that the Cicero UI exposes as suggestions.
/// Used both for the /font endpoint's `available` list and for set_metadata
/// validation.
public enum CiceroFonts {
    public static let curated: [String] = [
        "SF Pro Display",
        "Helvetica Neue",
        "Georgia",
        "Palatino",
        "Courier New",
        "Menlo",
        "SF Mono",
    ]
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
        return CiceroFonts.curated.contains { $0.lowercased() == trimmed.lowercased() }
    }

    public static func isValidTransition(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return PresentationTransition(rawValue: name) != nil
    }
}
