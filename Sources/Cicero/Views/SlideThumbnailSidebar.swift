import SwiftUI
import UniformTypeIdentifiers
import Shared

struct SlideThumbnailSidebar: View {
    @Environment(Presentation.self) private var presentation
    let theme: SlideTheme

    @State private var draggingIndex: Int?
    @State private var dropTargetIndex: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(presentation.slides.enumerated()), id: \.element.id) { index, slide in
                        sidebarThumbnail(slide: slide, index: index)
                            .id(index)
                    }
                }
                .padding(8)
            }
            .onChange(of: presentation.currentIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(width: 180)
    }

    private func sidebarThumbnail(slide: Slide, index: Int) -> some View {
        let isSelected = index == presentation.currentIndex
        let isDragTarget = dropTargetIndex == index
        let isDragging = draggingIndex == index

        return VStack(alignment: .leading, spacing: 4) {
            ZStack {
                theme.background
                VStack(alignment: .leading, spacing: 2) {
                    if let title = slide.title {
                        Text(title)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.heading)
                            .lineLimit(2)
                    }
                    Text(slide.content.prefix(120))
                        .font(.system(size: 7))
                        .foregroundStyle(theme.text.opacity(0.7))
                        .lineLimit(4)
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isDragTarget ? Color.accentColor :
                        isSelected ? Color.accentColor : .secondary.opacity(0.3),
                        lineWidth: isDragTarget ? 3 : isSelected ? 2.5 : 0.5
                    )
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4)

            Text("\(index + 1)")
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            presentation.navigate(to: index)
        }
        .contextMenu {
            Button("Add Slide After") {
                presentation.addSlide(content: "\n", after: index)
            }
            Button("Duplicate Slide") {
                presentation.duplicateSlide(at: index)
            }
            Divider()
            Button("Delete Slide", role: .destructive) {
                presentation.removeSlide(at: index)
            }
            .disabled(presentation.slides.count <= 1)
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
        .opacity(isDragging ? 0.4 : 1.0)
        .scaleEffect(isDragTarget ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragTarget)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}
