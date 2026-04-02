import Testing
@testable import Shared

@Suite("FontValidator")
struct FontValidatorTests {

    @Test("System font is valid — Helvetica")
    func testSystemFontIsValid() {
        #expect(FontValidator.isSystemFont("Helvetica"))
    }

    @Test("System font is valid — Times New Roman")
    func testTimesNewRoman() {
        #expect(FontValidator.isSystemFont("Times New Roman"))
    }

    @Test("Monospaced font is valid — Menlo")
    func testMonospacedFontIsValid() {
        #expect(FontValidator.isSystemFont("Menlo"))
    }

    @Test("Nonexistent font is invalid")
    func testNonexistentFontIsInvalid() {
        #expect(!FontValidator.isSystemFont("FakeFont123"))
    }

    @Test("Empty string is invalid")
    func testEmptyStringIsInvalid() {
        let result = FontValidator.validate("")
        #expect(result == .empty)
    }

    @Test("Case-insensitive matching")
    func testCaseInsensitiveMatching() {
        #expect(FontValidator.isSystemFont("helvetica"))
        #expect(FontValidator.isSystemFont("HELVETICA"))
    }

    @Test("Available fonts list is not empty")
    func testAvailableFontsNotEmpty() {
        let families = FontValidator.availableFontFamilies()
        #expect(!families.isEmpty)
    }

    @Test("Validate returns valid for known font")
    func testValidateValid() {
        let result = FontValidator.validate("Helvetica")
        #expect(result == .valid)
    }

    @Test("Validate returns invalid with suggestion for close match")
    func testValidateWithSuggestion() {
        let result = FontValidator.validate("Helvetic")
        if case .invalid(let suggestion) = result {
            #expect(suggestion != nil)
        } else {
            Issue.record("Expected .invalid with suggestion")
        }
    }

    @Test("Validate returns invalid without suggestion for garbage")
    func testValidateNoSuggestion() {
        let result = FontValidator.validate("xyzzy123456garbage")
        #expect(result == .invalid(suggestion: nil))
    }
}
