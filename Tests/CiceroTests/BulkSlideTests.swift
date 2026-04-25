import Testing
import Foundation
@testable import Shared

@Suite("Bulk slide operations")
struct BulkSlideTests {

    @Test("BulkSetSlidesRequest round-trips through JSON")
    func bulkRequestRoundTrip() throws {
        let req = BulkSetSlidesRequest(updates: [
            BulkSlideUpdate(index: 0, content: "# A"),
            BulkSlideUpdate(index: 2, content: "# B"),
        ])
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(BulkSetSlidesRequest.self, from: data)
        #expect(decoded.updates.count == 2)
        #expect(decoded.updates[0].index == 0)
        #expect(decoded.updates[0].content == "# A")
        #expect(decoded.updates[1].index == 2)
    }

    @Test("BulkSetSlidesResponse encodes counts")
    func bulkResponse() throws {
        let resp = BulkSetSlidesResponse(updatedCount: 3, totalSlides: 5)
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(BulkSetSlidesResponse.self, from: data)
        #expect(decoded.updatedCount == 3)
        #expect(decoded.totalSlides == 5)
    }

    @Test("Validator accepts all-in-range indices")
    func validatorAccepts() {
        let req = BulkSetSlidesRequest(updates: [
            BulkSlideUpdate(index: 0, content: "a"),
            BulkSlideUpdate(index: 2, content: "b"),
        ])
        #expect(RequestValidator.validateBulk(req, slideCount: 3) == nil)
    }

    @Test("Validator rejects out-of-range index")
    func validatorRejectsOutOfRange() {
        let req = BulkSetSlidesRequest(updates: [
            BulkSlideUpdate(index: 0, content: "a"),
            BulkSlideUpdate(index: 5, content: "b"),
        ])
        let err = RequestValidator.validateBulk(req, slideCount: 3)
        #expect(err != nil)
        #expect(err?.contains("5") == true)
    }

    @Test("Validator rejects negative index")
    func validatorRejectsNegative() {
        let req = BulkSetSlidesRequest(updates: [
            BulkSlideUpdate(index: -1, content: "a"),
        ])
        #expect(RequestValidator.validateBulk(req, slideCount: 3) != nil)
    }

    @Test("Validator rejects empty updates")
    func validatorRejectsEmpty() {
        let req = BulkSetSlidesRequest(updates: [])
        #expect(RequestValidator.validateBulk(req, slideCount: 3) != nil)
    }

    @Test("firstOutOfRange returns nil for empty input")
    func firstOutOfRangeEmpty() {
        #expect(RequestValidator.firstOutOfRange([], count: 5) == nil)
    }

    @Test("firstOutOfRange returns first bad index")
    func firstOutOfRangeFirst() {
        #expect(RequestValidator.firstOutOfRange([0, 1, 99, 100], count: 5) == 99)
    }
}
