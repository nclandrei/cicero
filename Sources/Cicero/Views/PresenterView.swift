import SwiftUI
import Shared

struct PresenterView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissWindow) private var dismissWindow
    @FocusState private var isFocused: Bool

    @State private var currentTool: PresenterTool = .none
    @State private var drawingStrokes: [DrawingStroke] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let slide = presentation.currentSlide {
                SlideView(
                    slide: slide,
                    theme: presenterTheme,
                    fontFamily: presentation.metadata.font,
                    baseDirectory: presentation.filePath?.deletingLastPathComponent(),
                    isPresenting: true
                )
                    .transition(slideTransition)
                    .id(presentation.currentIndex)
            }

            // Navigation overlay — only active when no tool is selected
            if currentTool == .none {
                HStack(spacing: 0) {
                    // Left half — previous
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { navigate { presentation.previous() } }

                    // Right half — next
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { navigate { presentation.next() } }
                }
            }

            // Presenter tools overlay
            if currentTool != .none {
                PresenterToolsOverlay(
                    tool: currentTool,
                    strokes: $drawingStrokes
                )
            }

            // Presenter toolbar (auto-hides)
            PresenterToolbar(
                currentTool: $currentTool,
                onClearDrawings: { drawingStrokes.removeAll() },
                onExit: {
                    presentation.isPresenting = false
                    dismissWindow(id: "presenter")
                }
            )

            // HUD overlay
            VStack {
                Spacer()

                // Speaker notes
                if let notes = presentation.notesForCurrentSlide() {
                    Text(notes)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 700)
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                HStack {
                    // Timer & clock — bottom left
                    HStack(spacing: 8) {
                        Text(TimeFormatting.elapsedTime(seconds: presentation.elapsedSeconds))
                        Text("·")
                        Text(presentation.wallClock)
                    }
                    .font(.system(size: 14))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())

                    Spacer()

                    // Slide counter — bottom right
                    Text("\(presentation.currentIndex + 1) / \(presentation.slides.count)")
                        .font(.system(size: 14))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .allowsHitTesting(false)
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            presentation.isPresenting = true
            presentation.startTimer()
            isFocused = true
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
            navigate { presentation.previous() }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigate { presentation.next() }
            return .handled
        }
        .onKeyPress(.space) {
            navigate { presentation.next() }
            return .handled
        }
        .onKeyPress(.escape) {
            if currentTool != .none {
                currentTool = .none
                return .handled
            }
            presentation.isPresenting = false
            dismissWindow(id: "presenter")
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "p")) { _ in
            currentTool = currentTool == .pointer ? .none : .pointer
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "s")) { _ in
            currentTool = currentTool == .spotlight ? .none : .spotlight
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "d")) { _ in
            currentTool = currentTool == .drawing ? .none : .drawing
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "c")) { _ in
            drawingStrokes.removeAll()
            return .handled
        }
    }

    private var presenterTheme: SlideTheme {
        if let resolved = presentation.resolvedTheme {
            return SlideTheme(definition: resolved)
        }
        return .dark
    }

    private var effectiveTransition: PresentationTransition {
        presentation.metadata.transition ?? .none
    }

    private var slideTransition: AnyTransition {
        switch effectiveTransition {
        case .none:
            return .identity
        case .fade:
            return .opacity
        case .slide:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .push:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    private func navigate(_ action: () -> Void) {
        switch effectiveTransition {
        case .none:
            action()
        case .fade:
            withAnimation(.easeInOut(duration: 0.25)) { action() }
        case .slide, .push:
            withAnimation(.easeInOut(duration: 0.3)) { action() }
        }
    }
}
