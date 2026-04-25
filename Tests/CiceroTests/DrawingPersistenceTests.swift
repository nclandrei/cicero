import Testing
import Foundation
@testable import Shared

// Tests that DrawingStroke (a Codable, Sendable mirror of the UI type)
// round-trips through JSON, and that SlideParser preserves a per-slide
// `drawings: <base64-json>` frontmatter line across parse/serialize.
//
// Design: drawings persist inline in the markdown via a single-line slide
// frontmatter entry `drawings: <base64-encoded JSON of [SlideDrawingStroke]>`,
// alongside layout/image/video/embed. SlideDrawingStroke uses a hex color
// string (since SwiftUI.Color is not Codable) and represents points as
// [Double, Double] arrays (since CGPoint is not Codable).

@Suite("Drawing persistence")
struct DrawingPersistenceTests {

    // MARK: - SlideDrawingStroke Codable

    @Test("SlideDrawingStroke round-trips through JSON")
    func strokeJSONRoundTrip() throws {
        let stroke = SlideDrawingStroke(
            points: [
                SlideDrawingPoint(x: 10, y: 20),
                SlideDrawingPoint(x: 30, y: 40),
                SlideDrawingPoint(x: 50, y: 60.5),
            ],
            color: "#ff0000"
        )
        let data = try JSONEncoder().encode(stroke)
        let decoded = try JSONDecoder().decode(SlideDrawingStroke.self, from: data)
        #expect(decoded.points.count == 3)
        #expect(decoded.points[0].x == 10)
        #expect(decoded.points[2].y == 60.5)
        #expect(decoded.color == "#ff0000")
    }

    @Test("Empty stroke array round-trips")
    func emptyArrayRoundTrip() throws {
        let strokes: [SlideDrawingStroke] = []
        let data = try JSONEncoder().encode(strokes)
        let decoded = try JSONDecoder().decode([SlideDrawingStroke].self, from: data)
        #expect(decoded.isEmpty)
    }

    @Test("Multiple strokes round-trip")
    func multipleStrokesRoundTrip() throws {
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 0, y: 0)], color: "#ff0000"),
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 100, y: 100)], color: "#0000ff"),
        ]
        let data = try JSONEncoder().encode(strokes)
        let decoded = try JSONDecoder().decode([SlideDrawingStroke].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].color == "#ff0000")
        #expect(decoded[1].color == "#0000ff")
    }

    // MARK: - SlideParser drawings frontmatter

    @Test("Slide parses drawings frontmatter line")
    func parsesDrawingsLine() {
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 1, y: 2)], color: "#ff0000")
        ]
        let json = try! JSONEncoder().encode(strokes)
        let b64 = json.base64EncodedString()
        let content = """
        drawings: \(b64)
        # Title
        Body content.
        """
        let slide = Slide(id: 0, content: content)
        #expect(slide.drawings != nil)
        #expect(slide.drawings?.count == 1)
        #expect(slide.drawings?[0].color == "#ff0000")
        #expect(slide.drawings?[0].points.first?.x == 1)
        // body should not include the drawings line
        #expect(!slide.body.contains("drawings:"))
    }

    @Test("Slide without drawings has nil drawings")
    func noDrawingsIsNil() {
        let slide = Slide(id: 0, content: "# Title\nbody")
        #expect(slide.drawings == nil)
    }

    @Test("Slide drawings co-exist with image/layout frontmatter")
    func drawingsWithOtherFrontmatter() {
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 5, y: 5)], color: "#00ff00")
        ]
        let json = try! JSONEncoder().encode(strokes)
        let b64 = json.base64EncodedString()
        let content = """
        layout: image-left
        image: foo.png
        drawings: \(b64)
        # Title
        body
        """
        let slide = Slide(id: 0, content: content)
        #expect(slide.layout == .imageLeft)
        #expect(slide.imageURL == "foo.png")
        #expect(slide.drawings?.count == 1)
        #expect(slide.drawings?[0].color == "#00ff00")
    }

    @Test("Drawings round-trip through full markdown parse/serialize")
    func drawingsRoundTripFullMarkdown() throws {
        let strokes = [
            SlideDrawingStroke(
                points: [SlideDrawingPoint(x: 0, y: 0), SlideDrawingPoint(x: 10, y: 10)],
                color: "#abcdef"
            )
        ]
        let json = try JSONEncoder().encode(strokes)
        let b64 = json.base64EncodedString()
        let markdown = """
        ---
        title: Deck
        ---
        # Slide 1
        ---
        drawings: \(b64)
        # Slide 2 with drawings
        body
        """
        let result = SlideParser.parse(markdown)
        #expect(result.slides.count == 2)
        #expect(result.slides[0].drawings == nil)
        #expect(result.slides[1].drawings?.count == 1)
        #expect(result.slides[1].drawings?[0].color == "#abcdef")
        #expect(result.slides[1].drawings?[0].points.count == 2)

        // Serialize and re-parse — drawings should still be there.
        let serialized = SlideParser.serialize(metadata: result.metadata, slides: result.slides)
        let reparsed = SlideParser.parse(serialized)
        #expect(reparsed.slides.count == 2)
        #expect(reparsed.slides[1].drawings?.count == 1)
        #expect(reparsed.slides[1].drawings?[0].color == "#abcdef")
        #expect(reparsed.slides[1].drawings?[0].points.first?.x == 0)
        #expect(reparsed.slides[1].drawings?[0].points.last?.x == 10)
    }

    @Test("Setting drawings on a slide updates content with frontmatter line")
    func setDrawingsUpdatesContent() throws {
        var slide = Slide(id: 0, content: "# Title\nbody")
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 1, y: 1)], color: "#ff0000")
        ]
        slide.setDrawings(strokes)
        #expect(slide.drawings?.count == 1)
        #expect(slide.content.contains("drawings: "))
        // Body should still parse correctly
        #expect(slide.body.contains("# Title"))
    }

    @Test("Setting drawings to nil removes the frontmatter line")
    func clearDrawingsRemovesLine() {
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 1, y: 1)], color: "#ff0000")
        ]
        let json = try! JSONEncoder().encode(strokes)
        let b64 = json.base64EncodedString()
        var slide = Slide(id: 0, content: "drawings: \(b64)\n# Title\nbody")
        #expect(slide.drawings != nil)
        slide.setDrawings(nil)
        #expect(slide.drawings == nil)
        #expect(!slide.content.contains("drawings:"))
        #expect(slide.body.contains("# Title"))
    }

    @Test("Empty drawings array clears the frontmatter line")
    func emptyDrawingsClears() {
        let strokes = [
            SlideDrawingStroke(points: [SlideDrawingPoint(x: 1, y: 1)], color: "#ff0000")
        ]
        let json = try! JSONEncoder().encode(strokes)
        let b64 = json.base64EncodedString()
        var slide = Slide(id: 0, content: "drawings: \(b64)\n# Title")
        slide.setDrawings([])
        #expect(slide.drawings == nil)
        #expect(!slide.content.contains("drawings:"))
    }

    @Test("Malformed drawings line yields nil drawings, body kept")
    func malformedDrawingsIgnored() {
        let slide = Slide(id: 0, content: "drawings: not-valid-base64-or-json\n# Title\nbody")
        #expect(slide.drawings == nil)
        // The malformed line is consumed as frontmatter (it matches `key: value`),
        // so it should not pollute the body.
        #expect(slide.body == "# Title\nbody")
    }
}
