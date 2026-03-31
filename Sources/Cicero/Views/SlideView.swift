import SwiftUI
import MarkdownUI
import Splash
import Shared

struct SlideView: View {
    let slide: Slide?
    let theme: SlideTheme
    var baseDirectory: URL? = nil
    var isInteractive: Bool = false
    var onImageResize: ((String, CGFloat) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let size = slideSize(fitting: geo.size)
            ZStack {
                theme.background

                if let slide {
                    slideContent(for: slide)
                } else {
                    Text("No Slides")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.2), radius: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func slideContent(for slide: Slide) -> some View {
        switch slide.layout {
        case .title:
            TitleLayoutView(content: slide.body, theme: theme, baseDirectory: baseDirectory, isInteractive: isInteractive, onImageResize: onImageResize)
        case .twoColumn:
            TwoColumnLayoutView(content: slide.body, theme: theme, baseDirectory: baseDirectory, isInteractive: isInteractive, onImageResize: onImageResize)
        case .imageLeft:
            ImageSideLayoutView(content: slide.body, imageURL: slide.imageURL, imageOnLeft: true, theme: theme, baseDirectory: baseDirectory, isInteractive: isInteractive, onImageResize: onImageResize)
        case .imageRight:
            ImageSideLayoutView(content: slide.body, imageURL: slide.imageURL, imageOnLeft: false, theme: theme, baseDirectory: baseDirectory, isInteractive: isInteractive, onImageResize: onImageResize)
        case .default:
            ScrollView {
                Markdown(slide.body)
                    .markdownTheme(theme.markdownTheme())
                    .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                    .markdownImageProvider(.cicero(
                        baseDirectory: baseDirectory,
                        isInteractive: isInteractive,
                        onResize: onImageResize
                    ))
                    .padding(60)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // Maintain 16:9 aspect ratio
    private func slideSize(fitting container: CGSize) -> CGSize {
        let ratio: CGFloat = 16.0 / 9.0
        let padding: CGFloat = 32
        let available = CGSize(
            width: container.width - padding,
            height: container.height - padding
        )
        if available.width / available.height > ratio {
            let h = available.height
            return CGSize(width: h * ratio, height: h)
        } else {
            let w = available.width
            return CGSize(width: w, height: w / ratio)
        }
    }
}
