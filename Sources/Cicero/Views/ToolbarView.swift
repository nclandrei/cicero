import SwiftUI
import AppKit
import Shared

// MARK: - FontPanelBridge

/// An invisible NSView that becomes first responder to receive `changeFont(_:)` callbacks
/// from the system font panel, bridging them into SwiftUI.
struct FontPanelBridge: NSViewRepresentable {
    var onFontSelected: (String) -> Void

    func makeNSView(context: Context) -> FontPanelResponder {
        let view = FontPanelResponder()
        view.onFontSelected = onFontSelected
        // Become first responder after being added to the window so NSFontPanel routes to us
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: FontPanelResponder, context: Context) {
        nsView.onFontSelected = onFontSelected
    }

    class FontPanelResponder: NSView, NSFontChanging {
        var onFontSelected: ((String) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        func changeFont(_ sender: NSFontManager?) {
            guard let manager = sender else { return }
            let newFont = manager.convert(NSFont.systemFont(ofSize: 14))
            let familyName = newFont.familyName ?? newFont.fontName
            onFontSelected?(familyName)
        }

        func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
            [.face, .collection, .size]
        }
    }
}

// MARK: - ToolbarView

private let curatedFonts = [
    "SF Pro Display",
    "Helvetica Neue",
    "Georgia",
    "Palatino",
    "Courier New",
    "Menlo",
    "SF Mono",
]

struct ToolbarView: ToolbarContent {
    @Environment(Presentation.self) private var presentation
    @Environment(\.openWindow) private var openWindow
    @Environment(\.gitHubAuth) private var auth
    @Binding var selectedTheme: AppTheme
    @Binding var showOverview: Bool
    @Binding var toastMessage: String?
    @State private var isPublishing = false
    @State private var publishResult: String?
    @State private var isExportingPDF = false
    @State private var showSignInAlert = false
    @State private var publishedURL: String?
    @State private var showFontPanel = false

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

        ToolbarItemGroup {
            Button(action: { _ = presentation.undoEdit() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!presentation.editHistory.canUndo)
            .help("Undo (Cmd+Z)")

            Button(action: { _ = presentation.redoEdit() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!presentation.editHistory.canRedo)
            .help("Redo (Cmd+Shift+Z)")
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
                Button(action: { presentation.setFont(nil) }) {
                    HStack {
                        Text("System Default")
                        if presentation.metadata.font == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                if let customFont = presentation.metadata.font,
                   !curatedFonts.contains(customFont) {
                    Divider()
                    Button(action: { presentation.setFont(customFont) }) {
                        HStack {
                            Text(customFont)
                                .font(.custom(customFont, size: 14))
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()
                ForEach(curatedFonts, id: \.self) { fontName in
                    Button(action: { presentation.setFont(fontName) }) {
                        HStack {
                            Text(fontName)
                                .font(.custom(fontName, size: 14))
                            if presentation.metadata.font == fontName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()
                Button("Other...") {
                    showFontPanel = true
                    NSFontPanel.shared.orderFront(nil)
                }
            } label: {
                Image(systemName: "textformat")
            }
            .help("Slide font")
            .background {
                if showFontPanel {
                    FontPanelBridge { familyName in
                        presentation.setFont(familyName)
                    }
                    .frame(width: 0, height: 0)
                    .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                        if notification.object as? NSWindow == NSFontPanel.shared {
                            showFontPanel = false
                        }
                    }
                }
            }

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

            Button(action: exportHTML) {
                Image(systemName: "globe")
            }
            .help("Export HTML")

            if let url = publishedURL {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                    toastMessage = "URL copied to clipboard"
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
        guard let pdfData = service.exportPDF(slides: presentation.slides) else {
            presentation.errorMessage = "Failed to generate PDF."
            isExportingPDF = false
            return
        }
        do {
            try pdfData.write(to: url)
        } catch {
            presentation.errorMessage = "Failed to save PDF: \(error.localizedDescription)"
        }
        isExportingPDF = false
    }

    private func exportHTML() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".html"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let html = HTMLExportService.exportHTML(
            metadata: presentation.metadata,
            slides: presentation.slides,
            theme: presentation.resolvedTheme
        )
        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentation.errorMessage = "Failed to save HTML: \(error.localizedDescription)"
        }
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
                    toastMessage = "URL copied to clipboard"
                }
            } catch {
                await MainActor.run {
                    presentation.errorMessage = "Failed to publish gist: \(error.localizedDescription)"
                    isPublishing = false
                }
            }
        }
    }
}
