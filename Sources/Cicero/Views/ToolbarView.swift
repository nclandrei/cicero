import SwiftUI

struct ToolbarView: ToolbarContent {
    @Environment(Presentation.self) private var presentation
    @Environment(\.openWindow) private var openWindow
    @Environment(\.gitHubAuth) private var auth
    @Binding var selectedTheme: AppTheme
    @Binding var showOverview: Bool
    @State private var isPublishing = false
    @State private var publishResult: String?
    @State private var isExportingPDF = false
    @State private var showSignInAlert = false
    @State private var publishedURL: String?

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

            Button(action: exportPDF) {
                if isExportingPDF {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "doc.richtext")
                }
            }
            .disabled(isExportingPDF)
            .help("Export PDF")

            if let url = publishedURL {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                    publishResult = "URL copied"
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .help(url)
            }

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
            .alert("Sign in Required", isPresented: $showSignInAlert) {
                Button("OK") {}
            } message: {
                Text("Sign in to GitHub first via Settings (Cmd+,).")
            }

            Button(action: {
                openWindow(id: "presenter")
            }) {
                Image(systemName: "play.fill")
            }
            .help("Start presentation")
        }
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        isExportingPDF = true
        let service = PDFExportService(
            screenshotService: ScreenshotService(presentation: presentation)
        )
        if let pdfData = service.exportPDF(slides: presentation.slides) {
            try? pdfData.write(to: url)
        }
        isExportingPDF = false
    }

    private func publishGist() {
        guard let auth else {
            showSignInAlert = true
            return
        }

        isPublishing = true
        publishResult = nil
        let markdown = presentation.markdown
        let title = presentation.metadata.title ?? "Presentation"
        let existingGistId = presentation.metadata.gistId

        Task {
            let token = await auth.token
            guard let token else {
                await MainActor.run {
                    showSignInAlert = true
                    isPublishing = false
                }
                return
            }

            do {
                let result = try await GistService.shared.publish(
                    token: token,
                    filename: "\(title).md",
                    content: markdown,
                    description: title,
                    isPublic: false,
                    existingGistId: existingGistId
                )
                let ciceroURL = "https://cicero.nicolaeandrei.com/#/g/\(result.gistId)"
                await MainActor.run {
                    presentation.metadata.gistId = result.gistId
                    publishResult = ciceroURL
                    publishedURL = ciceroURL
                    isPublishing = false

                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(ciceroURL, forType: .string)
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
