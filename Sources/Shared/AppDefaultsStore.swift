import Foundation

/// Type-safe UserDefaults-backed store for user-configurable application
/// defaults. Lives in `Shared` so it's exercisable from the test target
/// (which only depends on `Shared`).
///
/// The Cicero app target consumes this through a thin `AppDefaults` adapter
/// that pins the `defaults` parameter to `UserDefaults.standard`.
public final class AppDefaultsStore {

    /// UserDefaults keys. Centralised here to avoid string-typo bugs.
    public enum Keys {
        public static let defaultTheme = "cicero.defaults.theme"
        public static let defaultExportLocation = "cicero.defaults.exportLocation"
        public static let defaultFont = "cicero.defaults.font"
        public static let httpPort = "cicero.defaults.httpPort"
    }

    /// Documented fallback for an unset default theme.
    public static let fallbackTheme: String = "auto"

    /// Documented fallback for an unset default HTTP port.
    public static let fallbackHTTPPort: Int = 19847

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Default theme

    public var defaultTheme: String {
        get { defaults.string(forKey: Keys.defaultTheme) ?? Self.fallbackTheme }
        set { defaults.set(newValue, forKey: Keys.defaultTheme) }
    }

    // MARK: - Default export location

    /// Stored as a bookmark-free path string. Returns `nil` when unset.
    public var defaultExportLocation: URL? {
        get {
            guard let path = defaults.string(forKey: Keys.defaultExportLocation),
                  !path.isEmpty
            else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set {
            if let newValue {
                defaults.set(newValue.path, forKey: Keys.defaultExportLocation)
            } else {
                defaults.removeObject(forKey: Keys.defaultExportLocation)
            }
        }
    }

    // MARK: - Default font

    public var defaultFont: String {
        get { defaults.string(forKey: Keys.defaultFont) ?? CuratedFonts.defaultFont }
        set { defaults.set(newValue, forKey: Keys.defaultFont) }
    }

    // MARK: - HTTP port override

    /// Reads back the override or the documented `fallbackHTTPPort`.
    /// Writes silently no-op when the value is outside `AppDefaultsValidator`'s
    /// accepted range — this preserves the previous valid value.
    public var httpPort: Int {
        get {
            // `object(forKey:)` so we can distinguish "unset" from "stored 0".
            guard let raw = defaults.object(forKey: Keys.httpPort) as? Int else {
                return Self.fallbackHTTPPort
            }
            return AppDefaultsValidator.isValidPort(raw) ? raw : Self.fallbackHTTPPort
        }
        set {
            guard AppDefaultsValidator.isValidPort(newValue) else { return }
            defaults.set(newValue, forKey: Keys.httpPort)
        }
    }
}
