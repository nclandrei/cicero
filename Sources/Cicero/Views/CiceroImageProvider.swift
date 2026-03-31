import AppKit
import SwiftUI
import MarkdownUI

/// Custom MarkdownUI image provider that resolves local `assets/` paths and supports width metadata.
///
/// Width is encoded in the URL fragment: `![alt](assets/img.png#w=400)`
/// In interactive mode, images show resize handles on hover.
struct CiceroImageProvider: ImageProvider {
    let baseDirectory: URL?
    let isInteractive: Bool
    let onResize: ((String, CGFloat) -> Void)?

    func makeImage(url: URL?) -> some View {
        CiceroImageView(
            url: url,
            baseDirectory: baseDirectory,
            isInteractive: isInteractive,
            onResize: onResize
        )
    }
}

extension ImageProvider where Self == CiceroImageProvider {
    static func cicero(
        baseDirectory: URL?,
        isInteractive: Bool = false,
        onResize: ((String, CGFloat) -> Void)? = nil
    ) -> CiceroImageProvider {
        CiceroImageProvider(
            baseDirectory: baseDirectory,
            isInteractive: isInteractive,
            onResize: onResize
        )
    }
}

// MARK: - CiceroImageView

private struct CiceroImageView: View {
    let url: URL?
    let baseDirectory: URL?
    let isInteractive: Bool
    let onResize: ((String, CGFloat) -> Void)?

    @State private var nsImage: NSImage?
    @State private var initialWidth: CGFloat?
    @State private var sourcePath: String = ""

    var body: some View {
        Group {
            if let nsImage {
                if isInteractive, let onResize {
                    ResizableImageView(
                        image: nsImage,
                        initialWidth: initialWidth,
                        onResizeEnd: { newWidth in
                            onResize(sourcePath, newWidth)
                        }
                    )
                } else {
                    let img = Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    if let initialWidth {
                        img.frame(width: initialWidth)
                    } else {
                        img.frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Fallback for remote URLs
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxWidth: initialWidth ?? .infinity)
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        guard let url else { return }

        // Parse width from fragment (#w=400)
        if let fragment = url.fragment {
            for param in fragment.split(separator: "&") {
                let parts = param.split(separator: "=", maxSplits: 1)
                if parts.count == 2 && parts[0] == "w", let w = Double(parts[1]) {
                    initialWidth = CGFloat(w)
                }
            }
        }

        // Build source path (without fragment) for resize callback
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.fragment = nil
        let cleanPath = components?.url?.path ?? url.path

        // Try to resolve as local file
        let resolvedURL: URL?
        if url.scheme == nil || url.scheme == "file" {
            if let baseDirectory {
                // Relative path like "assets/img.png"
                let relativePath = url.relativePath.isEmpty ? url.path : url.relativePath
                let fileURL = baseDirectory.appendingPathComponent(relativePath)
                resolvedURL = FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
                sourcePath = relativePath
            } else {
                resolvedURL = FileManager.default.fileExists(atPath: cleanPath) ? URL(fileURLWithPath: cleanPath) : nil
                sourcePath = cleanPath
            }
        } else {
            resolvedURL = nil
            sourcePath = url.absoluteString
        }

        if let resolvedURL, let image = NSImage(contentsOf: resolvedURL) {
            nsImage = image
        }
    }
}

// MARK: - ResizableImageView

/// Displays an image with corner drag handles for interactive resizing.
struct ResizableImageView: View {
    let image: NSImage
    let initialWidth: CGFloat?
    let onResizeEnd: (CGFloat) -> Void

    @State private var currentWidth: CGFloat = 400
    @State private var isHovering = false
    @State private var dragStartWidth: CGFloat = 0

    private let minWidth: CGFloat = 100
    private let maxWidth: CGFloat = 1600

    var body: some View {
        let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1.0

        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: currentWidth, height: currentWidth * aspectRatio)
            .overlay {
                if isHovering {
                    // Corner drag handles
                    GeometryReader { geo in
                        let handleSize: CGFloat = 12
                        let positions: [UnitPoint] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]

                        ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: handleSize, height: handleSize)
                                .shadow(radius: 2)
                                .position(
                                    x: pos.x * geo.size.width,
                                    y: pos.y * geo.size.height
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let delta = (pos.x > 0.5)
                                                ? value.translation.width
                                                : -value.translation.width
                                            let newWidth = max(minWidth, min(maxWidth, dragStartWidth + delta))
                                            currentWidth = newWidth
                                        }
                                        .onEnded { _ in
                                            dragStartWidth = currentWidth
                                            onResizeEnd(currentWidth)
                                        }
                                )
                                .onAppear { dragStartWidth = currentWidth }
                        }
                    }
                    .allowsHitTesting(true)

                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
            .onHover { isHovering = $0 }
            .onAppear {
                currentWidth = initialWidth ?? min(image.size.width, maxWidth)
                dragStartWidth = currentWidth
            }
    }
}
