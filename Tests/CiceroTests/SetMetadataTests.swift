import Testing
@testable import Shared

@Suite("Metadata setter helpers")
struct SetMetadataTests {

    @Test("Curated font list is non-empty and includes expected families")
    func curatedFonts() {
        let fonts = CiceroFonts.curated
        #expect(!fonts.isEmpty)
        #expect(fonts.contains("Georgia"))
        #expect(fonts.contains("SF Pro Display"))
    }

    @Test("Theme name validation accepts built-in names")
    func validThemeNames() {
        for theme in ThemeRegistry.builtIn {
            #expect(MetadataValidator.isValidTheme(theme.name))
        }
        #expect(MetadataValidator.isValidTheme("auto"))
        #expect(MetadataValidator.isValidTheme("custom"))
    }

    @Test("Theme name validation rejects unknown")
    func invalidThemeNames() {
        #expect(!MetadataValidator.isValidTheme("nonsense"))
        #expect(!MetadataValidator.isValidTheme(""))
    }

    @Test("Font validation accepts curated names")
    func validFontNames() {
        for f in CiceroFonts.curated {
            #expect(MetadataValidator.isValidFont(f))
        }
    }

    @Test("Font validation rejects garbage")
    func invalidFontNames() {
        #expect(!MetadataValidator.isValidFont("Comic Sans Of Doom 9999"))
    }

    @Test("Transition validation accepts none/fade/slide/push")
    func validTransitions() {
        for t in PresentationTransition.allCases {
            #expect(MetadataValidator.isValidTransition(t.rawValue))
        }
    }

    @Test("Transition validation rejects unknown")
    func invalidTransitions() {
        #expect(!MetadataValidator.isValidTransition("zoom"))
        #expect(!MetadataValidator.isValidTransition(""))
    }
}
