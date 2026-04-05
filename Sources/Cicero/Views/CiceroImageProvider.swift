import AppKit
import SwiftUI
import MarkdownUI
import Shared

/// Video file extensions detected for inline `![video](path)` syntax.
private let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "webm", "avi"]

/// Custom MarkdownUI image provider that resolves local `assets/` paths and supports width metadata.
///
/// Width is encoded in the URL fragment: `![alt](assets/img.png#w=400)`
/// In interactive mode, images show resize handles on hover.
///
/// Also handles inline video and web embeds:
/// - `![video](assets/demo.mp4)` — detected by file extension → InlineVideoPlayerView
/// - `![embed](https://example.com)` — "embed" alt text → InlineWebEmbedView
struct CiceroImageProvider: ImageProvider {
    let baseDirectory: URL?
    let isInteractive: Bool
    let onResize: ((String, CGFloat) -> Void)?

    func makeImage(url: URL?) -> some View {
        CiceroImageRouter(
            url: url,
            baseDirectory: baseDirectory,
            isInteractive: isInteractive,
            onResize: onResize
        )
    }
}

/// Routes markdown image URLs to the appropriate view: video player, web embed, or image.
private struct CiceroImageRouter: View {
    let url: URL?
    let baseDirectory: URL?
    let isInteractive: Bool
    let onResize: ((String, CGFloat) -> Void)?

    var body: some View {
        if let url, isVideoURL(url) {
            InlineVideoPlayerView(url: url, baseDirectory: baseDirectory)
        } else if let url, isEmbedURL(url) {
            InlineWebEmbedView(url: url)
        } else if let url, isPositionedURL(url) {
            // Rendered separately as an overlay; suppress inline rendering.
            EmptyView()
        } else {
            CiceroImageView(
                url: url,
                baseDirectory: baseDirectory,
                isInteractive: isInteractive,
                onResize: onResize
            )
        }
    }

    private func isPositionedURL(_ url: URL) -> Bool {
        guard let fragment = url.fragment else { return false }
        var hasX = false
        var hasY = false
        for param in fragment.split(separator: "&") {
            let parts = param.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            if parts[0] == "x", Double(parts[1]) != nil { hasX = true }
            if parts[0] == "y", Double(parts[1]) != nil { hasY = true }
        }
        return hasX && hasY
    }

    private func isVideoURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    private func isEmbedURL(_ url: URL) -> Bool {
        // MarkdownUI passes the alt text via the fragment as #embed
        if let fragment = url.fragment, fragment.contains("embed") {
            return true
        }
        return false
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
                    let maxW = ImageSizing.constrainedWidth(
                        explicitWidth: initialWidth,
                        naturalWidth: nsImage.size.width
                    )
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: maxW)
                }
            } else {
                // Fallback for remote URLs
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxWidth: initialWidth ?? 800)
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

/// Displays an image with corner drag handles and a width editor for interactive resizing.
struct ResizableImageView: View {
    let image: NSImage
    let initialWidth: CGFloat?
    let onResizeEnd: (CGFloat) -> Void

    @State private var currentWidth: CGFloat = 400
    @State private var isHovering = false
    @State private var dragStartWidth: CGFloat = 0
    @State private var isEditingWidth = false
    @State private var widthText = ""

    private let minWidth: CGFloat = 100
    private let maxWidth: CGFloat = 1600

    private struct Preset: Identifiable {
        let id: String
        let label: String
        let width: CGFloat
    }

    private let presets: [Preset] = [
        Preset(id: "s", label: "S", width: 200),
        Preset(id: "m", label: "M", width: 400),
        Preset(id: "l", label: "L", width: 800),
        Preset(id: "xl", label: "XL", width: 1200),
    ]

    var body: some View {
        let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1.0

        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: currentWidth, height: currentWidth * aspectRatio)
            .overlay {
                if isHovering || isEditingWidth {
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
            .overlay(alignment: .bottom) {
                if isHovering || isEditingWidth {
                    widthBar
                        .offset(y: 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .onHover { hovering in
                if !hovering && !isEditingWidth {
                    isHovering = false
                } else {
                    isHovering = hovering
                }
            }
            .onAppear {
                currentWidth = initialWidth ?? min(image.size.width, maxWidth)
                dragStartWidth = currentWidth
            }
    }

    private var widthBar: some View {
        HStack(spacing: 6) {
            ForEach(presets) { preset in
                Button {
                    applyWidth(preset.width)
                } label: {
                    Text(preset.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            abs(currentWidth - preset.width) < 10 ? Color.white : Color.secondary
                        )
                        .frame(width: 24, height: 20)
                        .background(
                            abs(currentWidth - preset.width) < 10
                                ? Color.accentColor
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .frame(height: 14)

            if isEditingWidth {
                TextField("", text: $widthText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .onSubmit { commitWidthEdit() }
                    .onExitCommand { cancelWidthEdit() }

                Text("px")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    widthText = "\(Int(currentWidth))"
                    isEditingWidth = true
                } label: {
                    Text("\(Int(currentWidth))px")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private func applyWidth(_ width: CGFloat) {
        let clamped = max(minWidth, min(maxWidth, width))
        currentWidth = clamped
        dragStartWidth = clamped
        isEditingWidth = false
        onResizeEnd(clamped)
    }

    private func commitWidthEdit() {
        if let value = Double(widthText) {
            applyWidth(CGFloat(value))
        } else {
            isEditingWidth = false
        }
    }

    private func cancelWidthEdit() {
        isEditingWidth = false
    }
}
