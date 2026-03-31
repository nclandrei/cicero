import SwiftUI
import MarkdownUI
import Splash
import Shared

struct SlideView: View {
    let slide: Slide?
    let theme: SlideTheme

    var body: some View {
        GeometryReader { geo in
            let size = slideSize(fitting: geo.size)
            ZStack {
                theme.background

                if let slide {
                    ScrollView {
                        Markdown(slide.content)
                            .markdownTheme(slideMarkdownTheme)
                            .markdownCodeSyntaxHighlighter(
                                .splash(theme: splashTheme)
                            )
                            .padding(60)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: size.width, height: size.height)
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

    private var splashTheme: Splash.Theme {
        theme.isDark ? .ciceroDark : .ciceroLight
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

    private var slideMarkdownTheme: MarkdownUI.Theme {
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
