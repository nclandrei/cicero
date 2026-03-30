import SwiftUI

@main
struct CiceroApp: App {
    @State private var presentation = Presentation()
    @State private var localServer: LocalServer?
    @State private var fileWatcher: FileWatcher?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(presentation)
                .task {
                    if localServer == nil {
                        localServer = LocalServer(presentation: presentation)
                        localServer?.start()
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 700)
        .commands {
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
                            print("Failed to open file: \(error)")
                        }
                    }
                }
                .keyboardShortcut("o")

                Divider()

                Button("Save") {
                    if presentation.filePath != nil {
                        try? presentation.save()
                    } else {
                        let panel = NSSavePanel()
                        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
                        panel.nameFieldStringValue = (presentation.metadata.title ?? "Presentation") + ".md"
                        if panel.runModal() == .OK, let url = panel.url {
                            presentation.filePath = url
                            try? presentation.save()
                        }
                    }
                }
                .keyboardShortcut("s")
            }
        }

        Window("Presenter", id: "presenter") {
            PresenterView()
                .environment(presentation)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
