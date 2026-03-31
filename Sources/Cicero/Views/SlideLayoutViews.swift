import SwiftUI
import MarkdownUI
import Splash
import Shared

// MARK: - Title Layout

struct TitleLayoutView: View {
    let content: String
    let theme: SlideTheme

    var body: some View {
        VStack {
            Spacer()
            Markdown(content)
                .markdownTheme(theme.titleMarkdownTheme())
                .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Two-Column Layout

struct TwoColumnLayoutView: View {
    let content: String
    let theme: SlideTheme

    var body: some View {
        let parts = splitColumns(content)
        VStack(alignment: .leading, spacing: 0) {
            if let header = parts.header {
                Markdown(header)
                    .markdownTheme(theme.markdownTheme())
                    .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                    .padding(.horizontal, 60)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
            }

            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    Markdown(parts.left)
                        .markdownTheme(theme.markdownTheme())
                        .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                        .padding(parts.header != nil ? 30 : 60)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Rectangle()
                    .fill(theme.text.opacity(0.15))
                    .frame(width: 1)
                    .padding(.vertical, 20)

                ScrollView {
                    Markdown(parts.right)
                        .markdownTheme(theme.markdownTheme())
                        .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                        .padding(parts.header != nil ? 30 : 60)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct ColumnParts {
        let header: String?
        let left: String
        let right: String
    }

    private func splitColumns(_ text: String) -> ColumnParts {
        let segments = text.components(separatedBy: "|||")
        guard segments.count >= 2 else {
            // No ||| separator — put everything in left column
            return ColumnParts(header: nil, left: text, right: "")
        }
        if segments.count >= 3 {
            // header ||| left ||| right
            let header = segments[0].trimmingCharacters(in: .whitespacesAndNewlines)
            return ColumnParts(
                header: header.isEmpty ? nil : header,
                left: segments[1].trimmingCharacters(in: .whitespacesAndNewlines),
                right: segments[2].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        // left ||| right (no header)
        return ColumnParts(
            header: nil,
            left: segments[0].trimmingCharacters(in: .whitespacesAndNewlines),
            right: segments[1].trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Image Side Layout

struct ImageSideLayoutView: View {
    let content: String
    let imageURL: String?
    let imageOnLeft: Bool
    let theme: SlideTheme

    var body: some View {
        HStack(spacing: 0) {
            if imageOnLeft {
                imageSection
                textSection
            } else {
                textSection
                imageSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var imagePlaceholder: some View {
        ZStack {
            theme.codeBackground
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundStyle(theme.text.opacity(0.3))
        }
    }

    private var textSection: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(theme.markdownTheme())
                .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
