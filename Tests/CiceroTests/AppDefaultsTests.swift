import Foundation
import Testing
@testable import Shared

// Tests for the user-configurable application defaults wrapper.
//
// The wrapper persists four user preferences:
//   1. Default theme (string, one of ThemeRegistry.builtIn names plus "auto")
//   2. Default export location (file URL or path)
//   3. Default font (string, ideally from CuratedFonts.all)
//   4. HTTP port override (Int, validated 1024-65535)
//
// We test the Shared `AppDefaultsStore` directly (UserDefaults-injected) plus
// pure validation helpers in `AppDefaultsValidator`.
@Suite("AppDefaults")
struct AppDefaultsTests {

    /// Returns a freshly-created in-memory UserDefaults instance.
    private func makeIsolatedDefaults() -> UserDefaults {
        let suite = "AppDefaultsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // MARK: - Default theme

    @Test("Unset default theme reads as `auto`")
    func defaultThemeUnsetReturnsAuto() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        #expect(store.defaultTheme == "auto")
    }

    @Test("Default theme write/read round-trips")
    func defaultThemeRoundTrip() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        store.defaultTheme = "dracula"
        #expect(store.defaultTheme == "dracula")
        store.defaultTheme = "ocean"
        #expect(store.defaultTheme == "ocean")
    }

    // MARK: - Default export location

    @Test("Unset default export location returns nil")
    func defaultExportLocationUnsetIsNil() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        #expect(store.defaultExportLocation == nil)
    }

    @Test("Default export location write/read round-trips")
    func defaultExportLocationRoundTrip() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        let url = URL(fileURLWithPath: "/tmp/cicero-exports", isDirectory: true)
        store.defaultExportLocation = url
        #expect(store.defaultExportLocation?.path == url.path)
    }

    @Test("Default export location can be cleared by writing nil")
    func defaultExportLocationClear() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        store.defaultExportLocation = URL(fileURLWithPath: "/tmp/cicero-exports", isDirectory: true)
        store.defaultExportLocation = nil
        #expect(store.defaultExportLocation == nil)
    }

    // MARK: - Default font

    @Test("Unset default font reads as `SF Pro Display`")
    func defaultFontUnsetReturnsSFPro() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        #expect(store.defaultFont == "SF Pro Display")
    }

    @Test("Default font write/read round-trips")
    func defaultFontRoundTrip() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        store.defaultFont = "Georgia"
        #expect(store.defaultFont == "Georgia")
    }

    // MARK: - HTTP port override

    @Test("Unset HTTP port falls back to 19847")
    func httpPortUnsetIsDefault() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        #expect(store.httpPort == 19847)
    }

    @Test("HTTP port write/read round-trips")
    func httpPortRoundTrip() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        store.httpPort = 25000
        #expect(store.httpPort == 25000)
    }

    @Test("Setting an invalid HTTP port leaves the previous value")
    func httpPortRejectsInvalid() {
        let store = AppDefaultsStore(defaults: makeIsolatedDefaults())
        store.httpPort = 25000
        store.httpPort = 80     // below range
        #expect(store.httpPort == 25000)
        store.httpPort = 70000  // above range
        #expect(store.httpPort == 25000)
    }

    // MARK: - Validator

    @Test("Port 19847 is valid")
    func portValidatorAcceptsDefault() {
        #expect(AppDefaultsValidator.isValidPort(19847))
    }

    @Test("Port 1024 is valid (lower bound)")
    func portValidatorAcceptsLowerBound() {
        #expect(AppDefaultsValidator.isValidPort(1024))
    }

    @Test("Port 65535 is valid (upper bound)")
    func portValidatorAcceptsUpperBound() {
        #expect(AppDefaultsValidator.isValidPort(65535))
    }

    @Test("Port 1023 is rejected (below range)")
    func portValidatorRejectsBelowRange() {
        #expect(!AppDefaultsValidator.isValidPort(1023))
    }

    @Test("Port 65536 is rejected (above range)")
    func portValidatorRejectsAboveRange() {
        #expect(!AppDefaultsValidator.isValidPort(65536))
    }

    @Test("Negative port is rejected")
    func portValidatorRejectsNegative() {
        #expect(!AppDefaultsValidator.isValidPort(-1))
    }

    // MARK: - Curated fonts

    @Test("Curated fonts list is non-empty and contains SF Pro Display")
    func curatedFontsContainsDefault() {
        #expect(!CuratedFonts.all.isEmpty)
        #expect(CuratedFonts.all.contains("SF Pro Display"))
    }

    // MARK: - Theme options

    @Test("Theme options include `auto` and all built-in theme names")
    func themeOptionsIncludeAutoAndBuiltIns() {
        let options = AppDefaultsValidator.themeOptions()
        #expect(options.first == "auto")
        for theme in ThemeRegistry.builtIn {
            #expect(options.contains(theme.name))
        }
    }
}
