import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(Presentation.self) private var presentation
    @State private var selectedTheme: AppTheme = .auto
    @State private var showOverview = false
    @State private var toastMessage: String?
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var checkpointTask: Task<Void, Never>?
    @State private var previewDropTargeted = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HSplitView {
            SlideEditorView()
                .frame(minWidth: 300, idealWidth: 450)

            SlideView(
                slide: presentation.currentSlide,
                theme: effectiveTheme,
                fontFamily: presentation.metadata.font,
                baseDirectory: presentation.filePath?.deletingLastPathComponent(),
                isInteractive: true,
                onImageResize: { sourcePath, newWidth in
                    handleImageResize(sourcePath: sourcePath, newWidth: newWidth)
                }
            )
                .frame(minWidth: 400, idealWidth: 700)
                .onDrop(of: [.image, .fileURL], isTargeted: $previewDropTargeted) { providers in
                    handleImageDrop(providers)
                    return true
                }
                .overlay {
                    if previewDropTargeted {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .background(Color.accentColor.opacity(0.1))
                            .allowsHitTesting(false)
                    }
                }
        }
        .toolbar {
            ToolbarView(
                selectedTheme: $selectedTheme,
                showOverview: $showOverview,
                toastMessage: $toastMessage
            )
        }
        .sheet(isPresented: $showOverview) {
            SlideOverviewView(theme: effectiveTheme)
                .frame(minWidth: 800, minHeight: 500)
        }
        .navigationTitle(presentation.metadata.title ?? "Cicero")
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                Text(message)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation(.easeOut(duration: 0.3)) {
                                toastMessage = nil
                            }
                        }
                    }
            }
        }
        .animation(.spring(duration: 0.4), value: toastMessage)
        .onChange(of: presentation.isDirty) { _, isDirty in
            if isDirty {
                scheduleAutoSave()
            }
        }
        .onChange(of: presentation.markdown) { oldValue, _ in
            scheduleCheckpoint(oldValue)
        }
    }

    private var effectiveTheme: SlideTheme {
        if let resolved = presentation.resolvedTheme {
            return SlideTheme(definition: resolved)
        }
        switch selectedTheme {
        case .auto: return SlideTheme.forColorScheme(colorScheme)
        case .dark: return .dark
        case .light: return .light
        }
    }

    private func handleImageResize(sourcePath: String, newWidth: CGFloat) {
        let idx = presentation.currentIndex
        guard idx >= 0 && idx < presentation.slides.count else { return }
        let content = presentation.slides[idx].content
        let width = Int(newWidth)

        // Find the image reference and update/add width fragment
        // Match pattern: (sourcePath) or (sourcePath#w=NNN)
        let escaped = NSRegularExpression.escapedPattern(for: sourcePath)
        let pattern = "\\]\\(\(escaped)(#w=\\d+)?\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let nsContent = content as NSString
        let range = NSRange(location: 0, length: nsContent.length)
        let newContent = regex.stringByReplacingMatches(
            in: content,
            range: range,
            withTemplate: "](\(sourcePath)#w=\(width))"
        )
        if newContent != content {
            presentation.updateSlide(at: idx, content: newContent)
        }
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
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
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
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
        ensureFileIsSaved {
            guard let snippet = presentation.addImage(data, name: name) else { return }
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
            try? presentation.save()
            action()
        }
    }

    private func scheduleCheckpoint(_ text: String) {
        checkpointTask?.cancel()
        checkpointTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            presentation.editHistory.checkpoint(text)
        }
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            if presentation.filePath != nil {
                try? presentation.save()
            }
        }
    }
}
