import AppKit
import SwiftUI
import Shared

final class ScreenshotService {
    private let presentation: Presentation

    init(presentation: Presentation) {
        self.presentation = presentation
    }

    /// Must be called on the main thread (via DispatchQueue.main.sync from LocalServer)
    func renderSlideSync(_ slide: Slide, size: CGSize = CGSize(width: 1920, height: 1080)) -> Data? {
        MainActor.assumeIsolated {
            let view = ScreenshotSlideView(content: slide.content)
                .frame(width: size.width, height: size.height)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2.0

            guard let nsImage = renderer.nsImage else { return nil }
            guard let tiff = nsImage.tiffRepresentation else { return nil }
            guard let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
            return bitmap.representation(using: .png, properties: [:])
        }
    }

    func renderThumbnailSync(_ slide: Slide, size: CGSize = CGSize(width: 384, height: 216)) -> Data? {
        renderSlideSync(slide, size: size)
    }
}

/// Simplified view for screenshot rendering (avoids MarkdownUI complexity in ImageRenderer)
private struct ScreenshotSlideView: View {
    let content: String

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1))
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    lineView(line)
                }
            }
            .padding(60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var lines: [String] {
        content.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func lineView(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
            Text(String(trimmed.dropFirst(2)))
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
        } else if trimmed.hasPrefix("## ") {
            Text(String(trimmed.dropFirst(3)))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("\u{2022}")
                    .foregroundStyle(.white.opacity(0.7))
                Text(String(trimmed.dropFirst(2)))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .font(.system(size: 22))
        } else if trimmed.hasPrefix("```") {
            EmptyView()
        } else {
            Text(trimmed)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
