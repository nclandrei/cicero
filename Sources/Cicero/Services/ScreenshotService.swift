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
        let view = ScreenshotSlideView(content: slide.content)
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
    let content: String

    private let theme = SlideTheme.dark

    var body: some View {
        ZStack {
            theme.background
            ScrollView {
                Markdown(content)
                    .markdownTheme(markdownTheme)
                    .markdownCodeSyntaxHighlighter(.splash(theme: .ciceroDark))
                    .padding(60)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var markdownTheme: MarkdownUI.Theme {
        .gitHub
            .text {
                ForegroundColor(theme.text)
                FontSize(22)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(44)
                        FontWeight(.bold)
                        ForegroundColor(theme.heading)
                    }
                    .markdownMargin(top: 0, bottom: 24)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(34)
                        FontWeight(.semibold)
                        ForegroundColor(theme.heading)
                    }
                    .markdownMargin(top: 0, bottom: 16)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(28)
                        FontWeight(.medium)
                        ForegroundColor(theme.heading)
                    }
                    .markdownMargin(top: 0, bottom: 12)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(16)
                        ForegroundColor(theme.codeText)
                    }
                    .padding(16)
                    .background(theme.codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 16, bottom: 16)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(18)
                ForegroundColor(theme.accent)
            }
            .strong {
                FontWeight(.bold)
            }
            .link {
                ForegroundColor(theme.accent)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: 4, bottom: 4)
            }
    }
}
