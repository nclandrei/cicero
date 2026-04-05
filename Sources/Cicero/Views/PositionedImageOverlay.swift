import AppKit
import SwiftUI
import Shared

/// Renders a single positioned image as an overlay on top of a slide.
///
/// Coordinates (`x`, `y`, `width`) are in the 960×540 reference space.
/// The view scales them to the actual slide size via `scale`.
///
/// The image can be dragged (updates `x`/`y`) and resized via corner handles
/// (updates `width`). On gesture end, `onTransformEnd` is called with the final
/// values in 960×540 space — write them back to the markdown fragment.
struct PositionedImageOverlay: View {
    let ref: PositionedImageRef
    let baseDirectory: URL?
    let scale: CGFloat
    let isInteractive: Bool
    let onTransformEnd: (String, CGFloat, CGFloat, CGFloat) -> Void

    @State private var nsImage: NSImage?
    @State private var currentX: CGFloat
    @State private var currentY: CGFloat
    @State private var currentWidth: CGFloat
    @State private var dragStartOrigin: CGPoint = .zero
    @State private var dragStartWidth: CGFloat = 0
    @State private var isHovering = false

    private let minWidth: CGFloat = 40
    private let maxWidth: CGFloat = 1600

    init(
        ref: PositionedImageRef,
        baseDirectory: URL?,
        scale: CGFloat,
        isInteractive: Bool,
        onTransformEnd: @escaping (String, CGFloat, CGFloat, CGFloat) -> Void
    ) {
        self.ref = ref
        self.baseDirectory = baseDirectory
        self.scale = scale
        self.isInteractive = isInteractive
        self.onTransformEnd = onTransformEnd
        _currentX = State(initialValue: ref.x)
        _currentY = State(initialValue: ref.y)
        _currentWidth = State(initialValue: ref.width)
    }

    var body: some View {
        Group {
            if let nsImage {
                let aspectRatio = nsImage.size.width > 0
                    ? nsImage.size.height / nsImage.size.width
                    : 1.0
                let displayWidth = currentWidth * scale
                let displayHeight = displayWidth * aspectRatio

                let bodyDrag = DragGesture()
                    .onChanged { value in
                        let dx = value.translation.width / scale
                        let dy = value.translation.height / scale
                        currentX = dragStartOrigin.x + dx
                        currentY = dragStartOrigin.y + dy
                    }
                    .onEnded { _ in
                        dragStartOrigin = CGPoint(x: currentX, y: currentY)
                        onTransformEnd(ref.url, currentX, currentY, currentWidth)
                    }

                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displayWidth, height: displayHeight)
                    .overlay {
                        if isInteractive && isHovering {
                            cornerHandles(width: displayWidth, height: displayHeight, aspectRatio: aspectRatio)
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                                .allowsHitTesting(false)
                        }
                    }
                    .position(
                        x: (currentX + currentWidth / 2) * scale,
                        y: (currentY + (currentWidth * aspectRatio) / 2) * scale
                    )
                    .gesture(isInteractive ? bodyDrag : nil)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .onAppear {
                        dragStartOrigin = CGPoint(x: currentX, y: currentY)
                        dragStartWidth = currentWidth
                    }
            }
        }
        .onAppear { loadImage() }
        .onChange(of: ref.x) { _, newValue in currentX = newValue; dragStartOrigin.x = newValue }
        .onChange(of: ref.y) { _, newValue in currentY = newValue; dragStartOrigin.y = newValue }
        .onChange(of: ref.width) { _, newValue in currentWidth = newValue; dragStartWidth = newValue }
    }

    @ViewBuilder
    private func cornerHandles(width: CGFloat, height: CGFloat, aspectRatio: CGFloat) -> some View {
        let handleSize: CGFloat = 12
        let positions: [UnitPoint] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        GeometryReader { _ in
            ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: handleSize, height: handleSize)
                    .shadow(radius: 2)
                    .position(x: pos.x * width, y: pos.y * height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Corners on the right edge grow with +dx, left edge grow with -dx.
                                let delta = (pos.x > 0.5)
                                    ? value.translation.width / scale
                                    : -value.translation.width / scale
                                let newWidth = max(minWidth, min(maxWidth, dragStartWidth + delta))
                                currentWidth = newWidth
                            }
                            .onEnded { _ in
                                dragStartWidth = currentWidth
                                onTransformEnd(ref.url, currentX, currentY, currentWidth)
                            }
                    )
            }
        }
        .allowsHitTesting(true)
    }

    private func loadImage() {
        let url: URL?
        if let baseDirectory {
            let fileURL = baseDirectory.appendingPathComponent(ref.url)
            url = FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
        } else if FileManager.default.fileExists(atPath: ref.url) {
            url = URL(fileURLWithPath: ref.url)
        } else {
            url = nil
        }
        if let url, let image = NSImage(contentsOf: url) {
            nsImage = image
        }
    }
}
