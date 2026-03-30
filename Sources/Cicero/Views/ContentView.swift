import SwiftUI

struct ContentView: View {
    @Environment(Presentation.self) private var presentation
    @State private var selectedTheme: AppTheme = .auto
    @State private var showOverview = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HSplitView {
            SlideEditorView()
                .frame(minWidth: 300, idealWidth: 450)

            SlideView(slide: presentation.currentSlide, theme: effectiveTheme)
                .frame(minWidth: 400, idealWidth: 700)
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
    }

    private var effectiveTheme: SlideTheme {
        switch selectedTheme {
        case .auto: return SlideTheme.forColorScheme(colorScheme)
        case .dark: return .dark
        case .light: return .light
        }
    }
}
