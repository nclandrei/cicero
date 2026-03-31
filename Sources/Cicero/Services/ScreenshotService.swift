import AppKit
import SwiftUI
import MarkdownUI
import Splash
import Shared

final class ScreenshotService {
    private let presentation: Presentation

    init(presentation: Presentation) {
        self.presentation = presentation
    }

    /// Must be called on the main thread (via DispatchQueue.main.sync from LocalServer)
    func renderSlideSync(_ slide: Slide, size: CGSize = CGSize(width: 1920, height: 1080)) -> Data? {
        MainActor.assumeIsolated {
            renderViaHostingView(slide: slide, size: size)
        }
    }

    func renderThumbnailSync(_ slide: Slide, size: CGSize = CGSize(width: 384, height: 216)) -> Data? {
        MainActor.assumeIsolated {
            renderViaHostingView(slide: slide, size: size)
        }
    }

    /// Render using NSHostingView which fully supports MarkdownUI
    @MainActor
    private func renderViaHostingView(slide: Slide, size: CGSize) -> Data? {
        let baseDir = presentation.filePath?.deletingLastPathComponent()
        let view = ScreenshotSlideView(slide: slide, baseDirectory: baseDir)
            .frame(width: size.width, height: size.height)

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(origin: .zero, size: size)

        // Force layout
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        return bitmapRep.representation(using: .png, properties: [:])
    }
}

/// Uses MarkdownUI for proper rendering in screenshots
private struct ScreenshotSlideView: View {
    let slide: Slide
    let baseDirectory: URL?

    private let theme = SlideTheme.dark

    var body: some View {
        ZStack {
            theme.background
            slideContent
        }
    }

    @ViewBuilder
    private var slideContent: some View {
        switch slide.layout {
        case .title:
            TitleLayoutView(content: slide.body, theme: theme, baseDirectory: baseDirectory)
        case .twoColumn:
            TwoColumnLayoutView(content: slide.body, theme: theme, baseDirectory: baseDirectory)
        case .imageLeft:
            ImageSideLayoutView(content: slide.body, imageURL: slide.imageURL, imageOnLeft: true, theme: theme, baseDirectory: baseDirectory)
        case .imageRight:
            ImageSideLayoutView(content: slide.body, imageURL: slide.imageURL, imageOnLeft: false, theme: theme, baseDirectory: baseDirectory)
        case .default:
            ScrollView {
                Markdown(slide.body)
                    .markdownTheme(theme.markdownTheme())
                    .markdownCodeSyntaxHighlighter(.splash(theme: .ciceroDark))
                    .markdownImageProvider(.cicero(
                        baseDirectory: baseDirectory,
                        isInteractive: false
                    ))
                    .padding(60)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
