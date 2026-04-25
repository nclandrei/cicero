import Foundation
import Shared

/// App-target singleton wrapping `AppDefaultsStore` against
/// `UserDefaults.standard`. Use this from SwiftUI views and the app
/// initialiser to read or write the user's persisted defaults.
///
/// The actual UserDefaults logic lives in `Shared.AppDefaultsStore` so it
/// can be unit-tested. This file is intentionally a thin adapter.
enum AppDefaults {

    /// Shared instance bound to the user's standard defaults database.
    static let store = AppDefaultsStore(defaults: .standard)

    // MARK: - Convenience accessors

    static var defaultTheme: String {
        get { store.defaultTheme }
        set { store.defaultTheme = newValue }
    }

    static var defaultExportLocation: URL? {
        get { store.defaultExportLocation }
        set { store.defaultExportLocation = newValue }
    }

    /// Resolves the saved export directory or falls back to `~/Documents`.
    static var resolvedExportLocation: URL {
        if let configured = store.defaultExportLocation {
            return configured
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents ?? URL(fileURLWithPath: NSHomeDirectory())
    }

    static var defaultFont: String {
        get { store.defaultFont }
        set { store.defaultFont = newValue }
    }

    static var httpPort: Int {
        get { store.httpPort }
        set { store.httpPort = newValue }
    }
}
