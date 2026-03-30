import SwiftUI

struct ToolbarView: ToolbarContent {
    @Environment(Presentation.self) private var presentation
    @Environment(\.openWindow) private var openWindow
    @Binding var selectedTheme: AppTheme
    @Binding var showOverview: Bool

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

            Button(action: {
                openWindow(id: "presenter")
            }) {
                Image(systemName: "play.fill")
            }
            .help("Start presentation")
        }
    }
}
