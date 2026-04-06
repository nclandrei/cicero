import Testing
import Foundation
import SwiftUI
@testable import Shared

// Test PresenterTool enum and DrawingStroke logic.
// These types live in the Cicero target which can't be imported in tests,
// so we duplicate the pure-data definitions here for validation.

private enum PresenterTool: String, CaseIterable {
    case none, pointer, spotlight, drawing
}

private struct DrawingStroke {
    var points: [CGPoint]
    let color: String

    init(points: [CGPoint] = [], color: String = "red") {
        self.points = points
        self.color = color
    }
}

@Suite("Presenter Tools")
struct PresenterToolTests {

    @Test("PresenterTool has four cases")
    func toolCaseCount() {
        #expect(PresenterTool.allCases.count == 4)
    }

    @Test("PresenterTool raw values match expected strings")
    func toolRawValues() {
        #expect(PresenterTool.none.rawValue == "none")
        #expect(PresenterTool.pointer.rawValue == "pointer")
        #expect(PresenterTool.spotlight.rawValue == "spotlight")
        #expect(PresenterTool.drawing.rawValue == "drawing")
    }

    @Test("PresenterTool can be initialized from raw value")
    func toolFromRaw() {
        #expect(PresenterTool(rawValue: "pointer") == .pointer)
        #expect(PresenterTool(rawValue: "invalid") == nil)
    }

    @Test("DrawingStroke collects points")
    func strokePointCollection() {
        var stroke = DrawingStroke()
        #expect(stroke.points.isEmpty)

        stroke.points.append(CGPoint(x: 10, y: 20))
        stroke.points.append(CGPoint(x: 30, y: 40))
        stroke.points.append(CGPoint(x: 50, y: 60))

        #expect(stroke.points.count == 3)
        #expect(stroke.points[0] == CGPoint(x: 10, y: 20))
        #expect(stroke.points[2] == CGPoint(x: 50, y: 60))
    }

    @Test("DrawingStroke default color is red")
    func strokeDefaultColor() {
        let stroke = DrawingStroke()
        #expect(stroke.color == "red")
    }

    @Test("DrawingStroke accepts custom color")
    func strokeCustomColor() {
        let stroke = DrawingStroke(color: "blue")
        #expect(stroke.color == "blue")
    }

    @Test("DrawingStroke preserves point order")
    func strokePointOrder() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 0, y: 100),
        ]
        let stroke = DrawingStroke(points: points)
        #expect(stroke.points == points)
    }

    @Test("Multiple strokes remain independent")
    func multipleStrokes() {
        var stroke1 = DrawingStroke(color: "red")
        var stroke2 = DrawingStroke(color: "blue")

        stroke1.points.append(CGPoint(x: 1, y: 1))
        stroke2.points.append(CGPoint(x: 2, y: 2))
        stroke2.points.append(CGPoint(x: 3, y: 3))

        #expect(stroke1.points.count == 1)
        #expect(stroke2.points.count == 2)
    }
}
