import Testing
import Foundation
@testable import Shared

@Suite("ThemeDefinition & Registry")
struct ThemeTests {

    @Test("Parse valid hex color")
    func parseHex() {
        let rgb = ThemeDefinition.parseHex("#ff8040")
        #expect(rgb != nil)
        #expect(rgb!.r == 1.0)
        #expect(abs(rgb!.g - 0.502) < 0.01)
        #expect(abs(rgb!.b - 0.251) < 0.01)
    }

    @Test("Parse hex without hash prefix")
    func parseHexNoHash() {
        let rgb = ThemeDefinition.parseHex("00ff00")
        #expect(rgb != nil)
        #expect(rgb!.r == 0.0)
        #expect(rgb!.g == 1.0)
        #expect(rgb!.b == 0.0)
    }

    @Test("Parse invalid hex returns nil")
    func parseHexInvalid() {
        #expect(ThemeDefinition.parseHex("xyz") == nil)
        #expect(ThemeDefinition.parseHex("#12") == nil)
        #expect(ThemeDefinition.parseHex("") == nil)
    }

    @Test("isDark for dark backgrounds")
    func isDarkBackground() {
        let dark = ThemeDefinition(
            name: "test", background: "#000000",
            text: "#fff", heading: "#fff", accent: "#fff",
            codeBackground: "#000", codeText: "#fff"
        )
        #expect(dark.isDark == true)
    }

    @Test("isDark for light backgrounds")
    func isLightBackground() {
        let light = ThemeDefinition(
            name: "test", background: "#ffffff",
            text: "#000", heading: "#000", accent: "#000",
            codeBackground: "#fff", codeText: "#000"
        )
        #expect(light.isDark == false)
    }

    @Test("Registry has 10 built-in themes")
    func registryCount() {
        #expect(ThemeRegistry.builtIn.count == 10)
    }

    @Test("Registry find by name")
    func registryFind() {
        #expect(ThemeRegistry.find("ocean") != nil)
        #expect(ThemeRegistry.find("ocean")?.name == "ocean")
        #expect(ThemeRegistry.find("nonexistent") == nil)
    }

    @Test("All built-in theme names are unique")
    func uniqueNames() {
        let names = ThemeRegistry.builtIn.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test("resolveTheme returns built-in theme")
    func resolveBuiltIn() {
        let meta = PresentationMetadata(theme: "nord")
        let resolved = meta.resolveTheme()
        #expect(resolved != nil)
        #expect(resolved?.name == "nord")
    }

    @Test("resolveTheme returns nil for auto")
    func resolveAuto() {
        let meta = PresentationMetadata(theme: "auto")
        #expect(meta.resolveTheme() == nil)
    }

    @Test("resolveTheme returns nil for nil theme")
    func resolveNil() {
        let meta = PresentationMetadata()
        #expect(meta.resolveTheme() == nil)
    }

    @Test("resolveTheme builds custom theme from fields")
    func resolveCustom() {
        let meta = PresentationMetadata(
            theme: "custom",
            themeBackground: "#112233",
            themeText: "#aabbcc",
            themeHeading: "#ddeeff"
        )
        let resolved = meta.resolveTheme()
        #expect(resolved != nil)
        #expect(resolved?.name == "custom")
        #expect(resolved?.background == "#112233")
        #expect(resolved?.text == "#aabbcc")
        #expect(resolved?.heading == "#ddeeff")
    }

    @Test("resolveTheme custom without background returns nil")
    func resolveCustomNoBackground() {
        let meta = PresentationMetadata(theme: "custom", themeText: "#ffffff")
        #expect(meta.resolveTheme() == nil)
    }

    @Test("ThemeDefinition codable round-trip")
    func codableRoundTrip() throws {
        let original = ThemeRegistry.dracula
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeDefinition.self, from: data)
        #expect(decoded == original)
    }
}
