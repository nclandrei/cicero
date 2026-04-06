import SwiftUI

enum PresenterTool: String, CaseIterable {
    case none, pointer, spotlight, drawing
}

struct DrawingStroke {
    var points: [CGPoint]
    let color: Color

    init(points: [CGPoint] = [], color: Color = .red) {
        self.points = points
        self.color = color
    }
}
