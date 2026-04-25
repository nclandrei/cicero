import SwiftUI
import Shared

struct PresenterView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissWindow) private var dismissWindow
    @FocusState private var isFocused: Bool

    /// Bridge between the SwiftUI `PresenterTool` enum and the model's
    /// String-typed `activeTool`. MCP `set_presenter_tool` mutates
    /// `presentation.activeTool`; reading through this binding is what
    /// keeps the overlay in sync with remote tool changes.
    private var currentTool: Binding<PresenterTool> {
        Binding(
            get: { PresenterTool(rawValue: presentation.activeTool) ?? .none },
            set: { presentation.setPresenterTool($0.rawValue) }
        )
    }

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
            if currentTool.wrappedValue == .none {
                HStack(spacing: 0) {
                    // Left half — previous
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { navigate { presentation.previous() } }
                        .accessibilityLabel("Previous slide")
                        .accessibilityHint("Tap the left half of the slide to go back")
                        .accessibilityAddTraits(.isButton)

                    // Right half — next
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { navigate { presentation.next() } }
                        .accessibilityLabel("Next slide")
                        .accessibilityHint("Tap the right half of the slide to advance")
                        .accessibilityAddTraits(.isButton)
                }
            }

            // Presenter tools overlay
            if currentTool.wrappedValue != .none {
                PresenterToolsOverlay(
                    tool: currentTool.wrappedValue,
                    strokes: drawingStrokesBinding
                )
            }

            // Presenter toolbar (auto-hides)
            PresenterToolbar(
                currentTool: currentTool,
                onClearDrawings: { presentation.clearDrawings() },
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
                            .accessibilityHidden(true)
                        Text(presentation.wallClock)
                    }
                    .font(.system(size: 14))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Elapsed \(TimeFormatting.elapsedTime(seconds: presentation.elapsedSeconds)), clock \(presentation.wallClock)")

                    Spacer()

                    // Slide counter — bottom right
                    Text("\(presentation.currentIndex + 1) / \(presentation.slides.count)")
                        .font(.system(size: 14))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())
                        .accessibilityLabel("Slide \(presentation.currentIndex + 1) of \(presentation.slides.count)")
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
            if currentTool.wrappedValue != .none {
                currentTool.wrappedValue = .none
                return .handled
            }
            presentation.isPresenting = false
            dismissWindow(id: "presenter")
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "p")) { _ in
            currentTool.wrappedValue = currentTool.wrappedValue == .pointer ? .none : .pointer
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "s")) { _ in
            currentTool.wrappedValue = currentTool.wrappedValue == .spotlight ? .none : .spotlight
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "d")) { _ in
            currentTool.wrappedValue = currentTool.wrappedValue == .drawing ? .none : .drawing
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "c")) { _ in
            presentation.clearDrawings()
            return .handled
        }
    }

    /// Bridge between the view's `DrawingStroke` (with color) and the model's
    /// `drawingStrokes: [[CGPoint]]` (raw points only). Reading reconstructs
    /// strokes with the default red color; writing extracts the points.
    /// MCP `clear_drawings` zeros `presentation.drawingStrokes`, which causes
    /// this binding to read as empty and clear the visible drawings.
    private var drawingStrokesBinding: Binding<[DrawingStroke]> {
        Binding(
            get: {
                presentation.drawingStrokes.map { DrawingStroke(points: $0) }
            },
            set: { newStrokes in
                presentation.drawingStrokes = newStrokes.map { $0.points }
            }
        )
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
