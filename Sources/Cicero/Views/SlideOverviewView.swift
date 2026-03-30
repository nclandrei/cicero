import SwiftUI
import Shared

struct SlideOverviewView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.dismiss) private var dismiss
    let theme: SlideTheme

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 20)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Slide Overview")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(presentation.slides.enumerated()), id: \.element.id) { index, slide in
                        SlideThumbCard(
                            slide: slide,
                            index: index,
                            isSelected: index == presentation.currentIndex,
                            theme: theme
                        ) {
                            presentation.navigate(to: index)
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

private struct SlideThumbCard: View {
    let slide: Slide
    let index: Int
    let isSelected: Bool
    let theme: SlideTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Mini slide preview
                ZStack {
                    theme.background
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = slide.title {
                            Text(title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.heading)
                        }
                        Text(slide.content.prefix(200))
                            .font(.system(size: 9))
                            .foregroundStyle(theme.text.opacity(0.7))
                            .lineLimit(6)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                )

                Text("Slide \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
