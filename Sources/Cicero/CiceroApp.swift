import SwiftUI
import Shared
import Sparkle

@main
struct CiceroApp: App {
    @State private var presentation = Presentation()
    @State private var localServer: LocalServer?
    @State private var fileWatcher: FileWatcher?
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    // Auto-update
    @StateObject private var updater = UpdaterController()

    // MCP installer
    @StateObject private var mcpInstaller = MCPInstaller()

    // Auth state
    @State private var auth = GitHubAuth(clientId: "Ov23liDEDmYLwzNebYiR")
    @State private var isAuthenticated = false
    @State private var githubUsername: String?
    @State private var isAuthenticating = false
    @State private var authUserCode: String?
    @State private var authError: String?

    init() {
        // Show dock icon and make windows interactive (required for SwiftPM executables)
        NSApplication.shared.setActivationPolicy(.regular)

        // Set app icon — try app bundle first (distributed .app), fall back to SwiftPM resource bundle (swift run)
        let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            ?? Bundle.module.url(forResource: "AppIcon", withExtension: "icns")
        if let iconURL, let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        // Single window — prevents cmd+N from spawning duplicates
        Window("Cicero", id: "main") {
            ContentView()
                .environment(presentation)
                .environment(\.gitHubAuth, auth)
                .task {
                    if localServer == nil {
                        localServer = LocalServer(presentation: presentation, auth: auth)
                        localServer?.start()
                    }
                    // Restore session on launch
                    await auth.restoreSession()
                    isAuthenticated = await auth.isAuthenticated
                    githubUsername = await auth.username

                    // Bring to front on launch
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: .startPresentation)) { _ in
                    openWindow(id: "presenter")
                }
                .onReceive(NotificationCenter.default.publisher(for: .stopPresentation)) { _ in
                    dismissWindow(id: "presenter")
                }
        }
        .defaultSize(width: 1200, height: 700)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    _ = presentation.undoEdit()
                }
                .keyboardShortcut("z")
                .disabled(!presentation.editHistory.canUndo)

                Button("Redo") {
                    _ = presentation.redoEdit()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!presentation.editHistory.canRedo)
            }

            // Remove the default "New Window" command
            CommandGroup(replacing: .newItem) {
                Button("New Presentation") {
                    presentation.loadSamplePresentation()
                }
                .keyboardShortcut("n")

                Button("Open...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.init(filenameExtension: "md")!]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try presentation.loadFile(url)
                            fileWatcher = FileWatcher(path: url.path) {
                                DispatchQueue.main.async { [presentation] in
                                    guard let data = try? String(contentsOf: url, encoding: .utf8) else { return }
                                    presentation.loadMarkdown(data)
                                }
                            }
                        } catch {
                            presentation.errorMessage = "Failed to open file: \(error.localizedDescription)"
                        }
                    }
                }
                .keyboardShortcut("o")

                Divider()

                Button("Export PDF...") {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".pdf"
                    panel.directoryURL = AppDefaults.resolvedExportLocation
                    if panel.runModal() == .OK, let url = panel.url {
                        let service = PDFExportService(
                            screenshotService: ScreenshotService(presentation: presentation)
                        )
                        guard let pdfData = service.exportPDF(slides: presentation.slides) else {
                            presentation.errorMessage = "Failed to generate PDF."
                            return
                        }
                        do {
                            try pdfData.write(to: url)
                        } catch {
                            presentation.errorMessage = "Failed to save PDF: \(error.localizedDescription)"
                        }
                    }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Export HTML...") {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.html]
                    panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".html"
                    panel.directoryURL = AppDefaults.resolvedExportLocation
                    if panel.runModal() == .OK, let url = panel.url {
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
                }
                .keyboardShortcut("e", modifiers: [.command, .option])

                Divider()

                Button("Save") {
                    do {
                        if presentation.filePath != nil {
                            try presentation.save()
                        } else {
                            let panel = NSSavePanel()
                            panel.allowedContentTypes = [.init(filenameExtension: "md")!]
                            panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".md"
                            if panel.runModal() == .OK, let url = panel.url {
                                presentation.filePath = url
                                try presentation.save()
                            }
                        }
                    } catch {
                        presentation.errorMessage = "Failed to save file: \(error.localizedDescription)"
                    }
                }
                .keyboardShortcut("s")
            }
        }

        .commands {
            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Button("Toggle Speaker Notes") {
                    NotificationCenter.default.post(name: .toggleNotes, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .option])
            }
        }

        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
            }
        }

        Settings {
            SettingsView(
                isAuthenticated: $isAuthenticated,
                githubUsername: $githubUsername,
                isAuthenticating: $isAuthenticating,
                authUserCode: $authUserCode,
                authError: $authError,
                onSignIn: { startSignIn() },
                onSignOut: { signOut() },
                updater: updater,
                mcpInstaller: mcpInstaller
            )
        }

        Window("Presenter", id: "presenter") {
            PresenterView()
                .environment(presentation)
        }
        .windowStyle(.hiddenTitleBar)
    }

    // MARK: - Auth Actions

    private func startSignIn() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authError = nil
        authUserCode = nil

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
                    isAuthenticated = true
                    authUserCode = nil
                    isAuthenticating = false
                }
                githubUsername = await auth.username
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                    authUserCode = nil
                    isAuthenticating = false
                }
            }
        }
    }

    private func signOut() {
        Task {
            await auth.signOut()
            await MainActor.run {
                isAuthenticated = false
                githubUsername = nil
            }
        }
    }
}

// Environment key for passing GitHubAuth to views
private struct GitHubAuthKey: EnvironmentKey {
    static let defaultValue: GitHubAuth? = nil
}

extension EnvironmentValues {
    var gitHubAuth: GitHubAuth? {
        get { self[GitHubAuthKey.self] }
        set { self[GitHubAuthKey.self] = newValue }
    }
}
