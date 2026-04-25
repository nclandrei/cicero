import Testing
import Foundation
@testable import Shared

@Suite("Blank presentation builder")
struct BlankPresentationTests {

    @Test("Blank with no metadata parses back to one slide")
    func blankNoMetadata() {
        let markdown = SlideParser.blankPresentation()
        let parsed = SlideParser.parse(markdown)
        #expect(parsed.metadata.title == nil)
        #expect(parsed.metadata.author == nil)
        #expect(parsed.slides.count == 1)
    }

    @Test("Blank with title and author preserved through round-trip")
    func blankWithMetadata() {
        let markdown = SlideParser.blankPresentation(title: "My Deck", author: "Andrei")
        let parsed = SlideParser.parse(markdown)
        #expect(parsed.metadata.title == "My Deck")
        #expect(parsed.metadata.author == "Andrei")
        #expect(parsed.slides.count == 1)
    }

    @Test("Blank with only title")
    func blankOnlyTitle() {
        let markdown = SlideParser.blankPresentation(title: "Untitled")
        let parsed = SlideParser.parse(markdown)
        #expect(parsed.metadata.title == "Untitled")
        #expect(parsed.metadata.author == nil)
        #expect(parsed.slides.count == 1)
    }

    @Test("NewPresentationRequest round-trips")
    func newRequestRoundTrip() throws {
        let req = NewPresentationRequest(title: "Hello", author: "Andrei")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(NewPresentationRequest.self, from: data)
        #expect(decoded.title == "Hello")
        #expect(decoded.author == "Andrei")
    }

    @Test("NewPresentationRequest decodes empty body")
    func newRequestEmpty() throws {
        let req = NewPresentationRequest()
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(NewPresentationRequest.self, from: data)
        #expect(decoded.title == nil)
        #expect(decoded.author == nil)
    }
}
