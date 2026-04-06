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
    @Binding var showSidebar: Bool
    @Binding var showNotes: Bool
    @Binding var toastMessage: String?
    @State private var isPublishing = false
    @State private var publishResult: String?
    @State private var isExportingPDF = false
    @State private var publishedURL: String?
    @State private var showFontPanel = false
    @State private var isAuthenticating = false
    @State private var authUserCode: String?
    @State private var authError: String?
    @State private var showAuthPopover = false

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
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showSidebar.toggle() } }) {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle sidebar")

            Button(action: { showNotes.toggle() }) {
                Image(systemName: "note.text")
            }
            .help("Toggle speaker notes")

            Button(action: { showOverview.toggle() }) {
                Image(systemName: "square.grid.2x2")
            }
            .help("Slide overview")

            // MARK: Appearance Menu
            Menu {
                // Mode section
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: { selectedTheme = theme }) {
                        HStack {
                            Text(theme.rawValue.capitalized)
                            if selectedTheme == theme {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                // Color theme section
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
                Button(action: { presentation.setTheme("auto") }) {
                    HStack {
                        Text("Auto (System)")
                        if presentation.metadata.theme == "auto" {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                // Font section
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
                    Button(action: { presentation.setFont(customFont) }) {
                        HStack {
                            Text(customFont)
                                .font(.custom(customFont, size: 14))
                            Image(systemName: "checkmark")
                        }
                    }
                }

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

                Button("Other...") {
                    showFontPanel = true
                    NSFontPanel.shared.orderFront(nil)
                }
            } label: {
                Image(systemName: "paintbrush")
            }
            .help("Appearance")
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

            // MARK: Share Menu
            Menu {
                Button(action: exportPDF) {
                    if isExportingPDF {
                        Label("Exporting PDF...", systemImage: "doc.richtext")
                    } else {
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                }
                .disabled(isExportingPDF)

                Button(action: exportHTML) {
                    Label("Export HTML", systemImage: "globe")
                }

                if let url = publishedURL {
                    Divider()

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url, forType: .string)
                        toastMessage = "URL copied to clipboard"
                    }) {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                }
            } label: {
                Label("Share Link", systemImage: "link")
            } primaryAction: {
                shareLink()
            }
            .disabled(isPublishing || isAuthenticating)
            .help("Share Link")
            .popover(isPresented: $showAuthPopover, arrowEdge: .bottom) {
                VStack(spacing: 12) {
                    if let code = authUserCode {
                        Text(code)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .textSelection(.enabled)
                        Text("Enter this code on GitHub")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ProgressView()
                            .controlSize(.small)
                    } else if let error = authError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            authError = nil
                            startInlineAuth()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                        Text("Connecting to GitHub...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(width: 240)
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

    private func shareLink() {
        guard let auth else { return }

        Task {
            let token = await auth.token
            if token != nil {
                await publishToGist(auth: auth)
            } else {
                await MainActor.run {
                    startInlineAuth()
                }
            }
        }
    }

    private func startInlineAuth() {
        guard let auth else { return }
        isAuthenticating = true
        authError = nil
        authUserCode = nil
        showAuthPopover = true

        Task {
            do {
                let deviceCode = try await auth.requestDeviceCode()

                await MainActor.run {
                    authUserCode = deviceCode.userCode
                }

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(deviceCode.userCode, forType: .string)

                if let url = URL(string: deviceCode.verificationURI) {
                    NSWorkspace.shared.open(url)
                }

                _ = try await auth.pollForToken(deviceCode: deviceCode)

                await MainActor.run {
                    authUserCode = nil
                    isAuthenticating = false
                    showAuthPopover = false
                }

                // Auto-publish after successful auth
                await publishToGist(auth: auth)
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                    authUserCode = nil
                    isAuthenticating = false
                }
            }
        }
    }

    private func publishToGist(auth: GitHubAuth) async {
        await MainActor.run {
            isPublishing = true
            publishResult = nil
        }

        let token = await auth.token
        guard let token else {
            await MainActor.run { isPublishing = false }
            return
        }

        let markdown = presentation.markdown
        let title = presentation.metadata.title ?? "Presentation"
        let existingGistId = presentation.metadata.gistId

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
                presentation.errorMessage = "Failed to publish: \(error.localizedDescription)"
                isPublishing = false
            }
        }
    }
}
