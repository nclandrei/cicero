import SwiftUI

struct PresenterView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let slide = presentation.currentSlide {
                SlideView(
                    slide: slide,
                    theme: presenterTheme,
                    baseDirectory: presentation.filePath?.deletingLastPathComponent()
                )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(presentation.currentIndex)
            }

            // Navigation overlay
            HStack(spacing: 0) {
                // Left half — previous
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { presentation.previous() } }

                // Right half — next
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { presentation.next() } }
            }

            // Slide counter
            VStack {
                Spacer()
                Text("\(presentation.currentIndex + 1) / \(presentation.slides.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            presentation.isPresenting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApp.windows.first(where: { $0.title == "Presenter" || $0.identifier?.rawValue == "presenter" }) {
                    window.toggleFullScreen(nil)
                }
            }
        }
        .onDisappear {
            presentation.isPresenting = false
        }
        .onKeyPress(.leftArrow) {
            withAnimation(.easeInOut(duration: 0.3)) { presentation.previous() }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            withAnimation(.easeInOut(duration: 0.3)) { presentation.next() }
            return .handled
        }
        .onKeyPress(.space) {
            withAnimation(.easeInOut(duration: 0.3)) { presentation.next() }
            return .handled
        }
        .onKeyPress(.escape) {
            presentation.isPresenting = false
            dismissWindow(id: "presenter")
            return .handled
        }
    }

    private var presenterTheme: SlideTheme {
        if let resolved = presentation.resolvedTheme {
            return SlideTheme(definition: resolved)
        }
        return .dark
    }
}
