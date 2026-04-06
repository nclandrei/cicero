import SwiftUI

struct PresenterToolsOverlay: View {
    let tool: PresenterTool
    @Binding var strokes: [DrawingStroke]
    @State private var mouseLocation: CGPoint? = nil
    @State private var currentStroke: DrawingStroke? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tracking area for mouse
                MouseTrackingView(
                    onMove: { location in
                        mouseLocation = location
                    },
                    onDragStart: { location in
                        if tool == .drawing {
                            currentStroke = DrawingStroke(points: [location])
                        }
                    },
                    onDragMove: { location in
                        if tool == .drawing {
                            currentStroke?.points.append(location)
                        }
                    },
                    onDragEnd: {
                        if tool == .drawing, let stroke = currentStroke, stroke.points.count >= 2 {
                            strokes.append(stroke)
                        }
                        currentStroke = nil
                    }
                )

                // Pointer
                if tool == .pointer, let loc = mouseLocation {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .shadow(color: .red.opacity(0.6), radius: 8)
                        .position(loc)
                        .allowsHitTesting(false)
                }

                // Spotlight
                if tool == .spotlight, let loc = mouseLocation {
                    SpotlightMask(center: loc, radius: 150, size: geo.size)
                        .allowsHitTesting(false)
                }

                // Drawing strokes (completed)
                ForEach(Array(strokes.enumerated()), id: \.offset) { _, stroke in
                    StrokePath(points: stroke.points)
                        .stroke(stroke.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .allowsHitTesting(false)
                }

                // Current drawing stroke (in progress)
                if let stroke = currentStroke {
                    StrokePath(points: stroke.points)
                        .stroke(stroke.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Spotlight mask

private struct SpotlightMask: View {
    let center: CGPoint
    let radius: CGFloat
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            // Fill with dark overlay
            let fullRect = CGRect(origin: .zero, size: canvasSize)
            context.fill(Path(fullRect), with: .color(.black.opacity(0.7)))

            // Cut out the spotlight circle using blendMode
            let spotlightRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.blendMode = .destinationOut
            context.fill(Path(ellipseIn: spotlightRect), with: .color(.white))
        }
        .compositingGroup()
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Stroke path

private struct StrokePath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

// MARK: - Mouse tracking NSView wrapper

private struct MouseTrackingView: NSViewRepresentable {
    let onMove: (CGPoint) -> Void
    let onDragStart: (CGPoint) -> Void
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMove = onMove
        view.onDragStart = onDragStart
        view.onDragMove = onDragMove
        view.onDragEnd = onDragEnd
        return view
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMove = onMove
        nsView.onDragStart = onDragStart
        nsView.onDragMove = onDragMove
        nsView.onDragEnd = onDragEnd
    }
}

class MouseTrackingNSView: NSView {
    var onMove: ((CGPoint) -> Void)?
    var onDragStart: ((CGPoint) -> Void)?
    var onDragMove: ((CGPoint) -> Void)?
    var onDragEnd: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let flipped = CGPoint(x: loc.x, y: bounds.height - loc.y)
        onMove?(flipped)
    }

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let flipped = CGPoint(x: loc.x, y: bounds.height - loc.y)
        onDragStart?(flipped)
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let flipped = CGPoint(x: loc.x, y: bounds.height - loc.y)
        onDragMove?(flipped)
    }

    override func mouseUp(with event: NSEvent) {
        onDragEnd?()
    }

    override var acceptsFirstResponder: Bool { true }
}
