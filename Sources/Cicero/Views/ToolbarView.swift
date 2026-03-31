import SwiftUI
import Shared

struct ToolbarView: ToolbarContent {
    @Environment(Presentation.self) private var presentation
    @Environment(\.openWindow) private var openWindow
    @Binding var selectedTheme: AppTheme
    @Binding var showOverview: Bool
    @State private var isPublishing = false
    @State private var publishResult: String?

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: { presentation.previous() }) {
                Image(systemName: "chevron.left")
            }
            .disabled(presentation.currentIndex <= 0)
            .help("Previous slide")

            Text("\(presentation.currentIndex + 1) / \(presentation.slides.count)")
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 50)

            Button(action: { presentation.next() }) {
                Image(systemName: "chevron.right")
            }
            .disabled(presentation.currentIndex >= presentation.slides.count - 1)
            .help("Next slide")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { showOverview.toggle() }) {
                Image(systemName: "square.grid.2x2")
            }
            .help("Slide overview")

            Picker("Theme", selection: $selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue.capitalized).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            Menu {
                ForEach(ThemeRegistry.builtIn, id: \.name) { theme in
                    Button(action: { presentation.setTheme(theme.name) }) {
                        HStack {
                            Text(theme.name.capitalized)
                            if presentation.metadata.theme == theme.name {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Divider()
                Button("Auto (System)") {
                    presentation.setTheme("auto")
                }
            } label: {
                Image(systemName: "paintpalette")
            }
            .help("Slide theme")

            Button(action: publishGist) {
                if isPublishing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.doc")
                }
            }
            .disabled(isPublishing)
            .help(publishResult ?? "Publish to GitHub Gist")

            Button(action: {
                openWindow(id: "presenter")
            }) {
                Image(systemName: "play.fill")
            }
            .help("Start presentation")
        }
    }

    private func publishGist() {
        isPublishing = true
        publishResult = nil
        let markdown = presentation.markdown
        let title = presentation.metadata.title ?? "Presentation"
        let existingGistId = presentation.metadata.gistId

        Task {
            do {
                let result = try await GistService.shared.publish(
                    filename: "\(title).md",
                    content: markdown,
                    description: title,
                    isPublic: false,
                    existingGistId: existingGistId
                )
                await MainActor.run {
                    presentation.metadata.gistId = result.gistId
                    publishResult = "Published: \(result.url)"
                    isPublishing = false
                }
            } catch {
                await MainActor.run {
                    publishResult = error.localizedDescription
                    isPublishing = false
                }
            }
        }
    }
}
