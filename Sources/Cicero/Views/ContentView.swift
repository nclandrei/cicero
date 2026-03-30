import SwiftUI

struct ContentView: View {
    @Environment(Presentation.self) private var presentation
    @State private var selectedTheme: AppTheme = .auto
    @State private var showOverview = false
    @State private var autoSaveTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HSplitView {
            SlideEditorView()
                .frame(minWidth: 300, idealWidth: 450)

            SlideView(slide: presentation.currentSlide, theme: effectiveTheme)
                .frame(minWidth: 400, idealWidth: 700)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(presentation.currentIndex)
                .animation(.easeInOut(duration: 0.3), value: presentation.currentIndex)
        }
        .toolbar {
            ToolbarView(
                selectedTheme: $selectedTheme,
                showOverview: $showOverview
            )
        }
        .sheet(isPresented: $showOverview) {
            SlideOverviewView(theme: effectiveTheme)
                .frame(minWidth: 800, minHeight: 500)
        }
        .navigationTitle(presentation.metadata.title ?? "Cicero")
        .onChange(of: presentation.isDirty) { _, isDirty in
            if isDirty {
                scheduleAutoSave()
            }
        }
    }

    private var effectiveTheme: SlideTheme {
        switch selectedTheme {
        case .auto: return SlideTheme.forColorScheme(colorScheme)
        case .dark: return .dark
        case .light: return .light
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
