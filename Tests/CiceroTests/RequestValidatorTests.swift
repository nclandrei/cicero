import Testing
@testable import Shared

@Suite("RequestValidator")
struct RequestValidatorTests {

    // MARK: - validateSlideIndex

    @Test("Slide index 0 is valid in non-empty deck")
    func slideIndexZeroValid() {
        #expect(RequestValidator.validateSlideIndex(0, slideCount: 3) == nil)
    }

    @Test("Last slide index is valid")
    func slideIndexLastValid() {
        #expect(RequestValidator.validateSlideIndex(2, slideCount: 3) == nil)
    }

    @Test("Negative slide index is invalid")
    func slideIndexNegativeInvalid() {
        let err = RequestValidator.validateSlideIndex(-1, slideCount: 3)
        #expect(err != nil)
        #expect(err!.contains("out of range"))
    }

    @Test("Slide index >= count is invalid")
    func slideIndexTooLargeInvalid() {
        let err = RequestValidator.validateSlideIndex(3, slideCount: 3)
        #expect(err != nil)
    }

    @Test("Empty deck rejects any index")
    func slideIndexEmptyDeck() {
        #expect(RequestValidator.validateSlideIndex(0, slideCount: 0) != nil)
    }

    // MARK: - validateAfterIndex

    @Test("Nil afterIndex is always valid (append)")
    func afterIndexNilValid() {
        #expect(RequestValidator.validateAfterIndex(nil, slideCount: 0) == nil)
        #expect(RequestValidator.validateAfterIndex(nil, slideCount: 5) == nil)
    }

    @Test("afterIndex -1 inserts at very front, valid")
    func afterIndexMinusOneValid() {
        #expect(RequestValidator.validateAfterIndex(-1, slideCount: 5) == nil)
    }

    @Test("afterIndex 0..count-1 valid")
    func afterIndexRangeValid() {
        #expect(RequestValidator.validateAfterIndex(0, slideCount: 3) == nil)
        #expect(RequestValidator.validateAfterIndex(2, slideCount: 3) == nil)
    }

    @Test("afterIndex == count is invalid (use nil to append)")
    func afterIndexEqualsCountInvalid() {
        let err = RequestValidator.validateAfterIndex(3, slideCount: 3)
        #expect(err != nil)
    }

    @Test("afterIndex < -1 is invalid")
    func afterIndexTooNegativeInvalid() {
        let err = RequestValidator.validateAfterIndex(-2, slideCount: 3)
        #expect(err != nil)
    }

    // MARK: - validateCuratedFont

    @Test("Nil font name is valid (system default)")
    func curatedFontNilValid() {
        #expect(RequestValidator.validateCuratedFont(nil, curated: CuratedFonts.all) == nil)
    }

    @Test("Empty font name is valid (system default)")
    func curatedFontEmptyValid() {
        #expect(RequestValidator.validateCuratedFont("", curated: CuratedFonts.all) == nil)
        #expect(RequestValidator.validateCuratedFont("   ", curated: CuratedFonts.all) == nil)
    }

    @Test("Curated font name is valid")
    func curatedFontKnownValid() {
        #expect(RequestValidator.validateCuratedFont("Helvetica Neue", curated: CuratedFonts.all) == nil)
        #expect(RequestValidator.validateCuratedFont("Menlo", curated: CuratedFonts.all) == nil)
    }

    @Test("Unknown font name is rejected")
    func curatedFontUnknownInvalid() {
        let err = RequestValidator.validateCuratedFont("Comic Sans", curated: CuratedFonts.all)
        #expect(err != nil)
        #expect(err!.contains("Comic Sans"))
    }

    @Test("Curated list is non-empty")
    func curatedListPopulated() {
        #expect(!CuratedFonts.all.isEmpty)
        #expect(CuratedFonts.all.contains("SF Pro Display"))
    }
}
