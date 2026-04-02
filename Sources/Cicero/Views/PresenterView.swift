import SwiftUI
import Shared

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
                    fontFamily: presentation.metadata.font,
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

            // HUD overlay
            VStack {
                Spacer()
                HStack {
                    // Timer & clock — bottom left
                    HStack(spacing: 8) {
                        Text(TimeFormatting.elapsedTime(seconds: presentation.elapsedSeconds))
                        Text("·")
                        Text(presentation.wallClock)
                    }
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.35), in: Capsule())

                    Spacer()

                    // Slide counter — bottom right
                    Text("\(presentation.currentIndex + 1) / \(presentation.slides.count)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.35), in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            presentation.isPresenting = true
            presentation.startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApp.windows.first(where: { $0.title == "Presenter" || $0.identifier?.rawValue == "presenter" }) {
                    window.toggleFullScreen(nil)
                }
            }
        }
        .onDisappear {
            presentation.isPresenting = false
            presentation.stopTimer()
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
