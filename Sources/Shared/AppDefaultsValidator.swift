import Foundation

/// Pure validation helpers for user-configurable application defaults.
/// Lives in `Shared` so the unit-test target can exercise it without
/// touching the executable target.
public enum AppDefaultsValidator {

    /// Inclusive lower bound of the user-overridable HTTP port range.
    public static let minPort: Int = 1024

    /// Inclusive upper bound of the user-overridable HTTP port range.
    public static let maxPort: Int = 65535

    /// Returns `true` when `port` is in the safe user-space range.
    public static func isValidPort(_ port: Int) -> Bool {
        port >= minPort && port <= maxPort
    }

    /// All theme names a user can select as their default theme.
    /// `auto` resolves at render time to follow the system appearance;
    /// every other entry is a concrete `ThemeRegistry.builtIn` name.
    public static func themeOptions() -> [String] {
        ["auto"] + ThemeRegistry.builtIn.map(\.name)
    }
}
