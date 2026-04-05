import Shared
import SwiftUI
import UniformTypeIdentifiers

struct SlideEditorView: View {
    @Environment(Presentation.self) private var presentation
    @State private var dropTargeted = false

    var body: some View {
        @Bindable var presentation = presentation

        VStack(spacing: 0) {
            // Slide indicator
            HStack {
                Text("Markdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if presentation.isDirty {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .help("Unsaved changes")
                }
                Text("\(presentation.slides.count) slides")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            CodeEditorView(
                text: Binding(
                    get: { presentation.markdown },
                    set: { presentation.updateFromEditor($0) }
                ),
                onImageDrop: { data, name in
                    insertImage(data: data, name: name)
                },
                onCursorLineChange: { line in
                    let idx = SlideParser.slideIndex(forLine: line, in: presentation.markdown)
                    if idx != presentation.currentIndex {
                        presentation.navigate(to: idx)
                    }
                }
            )
            .overlay {
                if dropTargeted {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .background(Color.accentColor.opacity(0.1))
                        .allowsHitTesting(false)
                }
            }
        }
        .onPasteCommand(of: [.image, .png, .jpeg, .tiff]) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            // Try loading as file URL first (for Finder drags)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          let imageData = try? Data(contentsOf: url)
                    else { return }
                    let name = url.deletingPathExtension().lastPathComponent
                    DispatchQueue.main.async {
                        insertImage(data: imageData, name: name)
                    }
                }
            }
            // Try loading as image data
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data else { return }
                    DispatchQueue.main.async {
                        insertImage(data: data, name: nil)
                    }
                }
            }
        }
    }

    private func insertImage(data: Data, name: String?) {
        ensureFileIsSaved { [presentation] in
            guard let snippet = presentation.addImage(data, name: name) else {
                presentation.errorMessage = "Failed to save image. Check that the assets folder is writable."
                return
            }
            let currentIdx = presentation.currentIndex
            guard currentIdx >= 0 && currentIdx < presentation.slides.count else { return }
            let currentContent = presentation.slides[currentIdx].content
            presentation.updateSlide(at: currentIdx, content: currentContent + "\n\n" + snippet)
        }
    }

    private func ensureFileIsSaved(then action: @escaping () -> Void) {
        if presentation.filePath != nil {
            action()
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".md"
        if panel.runModal() == .OK, let url = panel.url {
            presentation.filePath = url
            do {
                try presentation.save()
            } catch {
                presentation.errorMessage = "Failed to save file: \(error.localizedDescription)"
                return
            }
            action()
        }
    }
}
