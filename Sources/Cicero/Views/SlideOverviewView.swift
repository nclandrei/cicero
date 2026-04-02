import SwiftUI
import UniformTypeIdentifiers
import Shared

struct SlideOverviewView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.dismiss) private var dismiss
    let theme: SlideTheme

    @State private var draggingIndex: Int?
    @State private var dropTargetIndex: Int?

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
                        slideCard(slide: slide, index: index)
                    }
                }
                .padding(20)
            }
        }
    }

    private func slideCard(slide: Slide, index: Int) -> some View {
        SlideThumbCard(
            slide: slide,
            index: index,
            isSelected: index == presentation.currentIndex,
            isDragTarget: dropTargetIndex == index,
            isDragging: draggingIndex == index,
            theme: theme
        ) {
            presentation.navigate(to: index)
            dismiss()
        }
        .onDrag {
            draggingIndex = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(of: [UTType.text], isTargeted: Binding(
            get: { dropTargetIndex == index },
            set: { targeted in dropTargetIndex = targeted ? index : nil }
        )) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { item, _ in
                guard let str = item as? String,
                      let sourceIndex = Int(str)
                else { return }
                DispatchQueue.main.async {
                    draggingIndex = nil
                    dropTargetIndex = nil
                    if sourceIndex != index {
                        presentation.moveSlide(from: sourceIndex, to: index)
                    }
                }
            }
            return true
        }
    }
}

private struct SlideThumbCard: View {
    let slide: Slide
    let index: Int
    let isSelected: Bool
    let isDragTarget: Bool
    let isDragging: Bool
    let theme: SlideTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
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
                        .stroke(
                            isDragTarget ? Color.accentColor :
                            isSelected ? Color.accentColor.opacity(0.6) : .clear,
                            lineWidth: isDragTarget ? 3 : 2
                        )
                )

                Text("Slide \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .opacity(isDragging ? 0.4 : 1.0)
        .scaleEffect(isDragTarget ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragTarget)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}
