import SwiftUI
import Shared

/// Second-screen "speaker view" — shows the current slide, a next-slide preview,
/// speaker notes, timers, and a progress bar. Distinct from `PresenterView`
/// (which is the audience-facing window).
struct PresenterDisplayView: View {
    @Environment(Presentation.self) private var presentation
    @Environment(\.dismissWindow) private var dismissWindow
    @FocusState private var isFocused: Bool

    var body: some View {
        let state = PresenterDisplayState.make(
            slides: presentation.slides,
            currentIndex: presentation.currentIndex,
            elapsedSeconds: presentation.elapsedSeconds,
            wallClock: presentation.wallClock
        )

        VStack(spacing: 0) {
            header(state: state)
            GeometryReader { geo in
                HStack(spacing: 16) {
                    currentSlidePanel
                        .frame(maxWidth: .infinity)
                    sidePanel(state: state, height: geo.size.height)
                        .frame(width: max(260, geo.size.width * 0.32))
                }
                .padding(16)
            }
            notesPanel(state: state)
            footer(state: state)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            positionOnMainScreen()
        }
        .onKeyPress(.leftArrow) { presentation.previous(); return .handled }
        .onKeyPress(.rightArrow) { presentation.next(); return .handled }
        .onKeyPress(.space) { presentation.next(); return .handled }
        .onKeyPress(.escape) {
            dismissWindow(id: "presenter-display")
            return .handled
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func header(state: PresenterDisplayState) -> some View {
        HStack {
            Text("Presenter Display")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(state.slideCounter)
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var currentSlidePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CURRENT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            SlideView(
                slide: presentation.currentSlide,
                theme: displayTheme,
                fontFamily: presentation.metadata.font,
                baseDirectory: presentation.filePath?.deletingLastPathComponent(),
                isPresenting: true
            )
        }
    }

    @ViewBuilder
    private func sidePanel(state: PresenterDisplayState, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            if state.hasNextSlide, let next = nextSlide {
                SlideView(
                    slide: next,
                    theme: displayTheme,
                    fontFamily: presentation.metadata.font,
                    baseDirectory: presentation.filePath?.deletingLastPathComponent(),
                    isPresenting: true
                )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        Text(state.isLastSlide ? "End of presentation" : "—")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    )
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func notesPanel(state: PresenterDisplayState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            ScrollView {
                Text(state.notes ?? "No notes for this slide.")
                    .font(.system(size: 18))
                    .lineSpacing(4)
                    .foregroundStyle(state.notes == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private func footer(state: PresenterDisplayState) -> some View {
        VStack(spacing: 6) {
            ProgressView(value: state.progressFraction)
                .progressViewStyle(.linear)
            HStack(spacing: 16) {
                Label(state.elapsedTimeFormatted, systemImage: "timer")
                Label(state.wallClock, systemImage: "clock")
                Spacer()
                Text(state.slideCounter)
            }
            .font(.system(size: 13, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private var nextSlide: Slide? {
        let next = presentation.currentIndex + 1
        guard next >= 0 && next < presentation.slides.count else { return nil }
        return presentation.slides[next]
    }

    private var displayTheme: SlideTheme {
        if let resolved = presentation.resolvedTheme {
            return SlideTheme(definition: resolved)
        }
        return .dark
    }

    /// Place the display window on the same screen as the main editor so the
    /// audience window (which moves to the external screen) stays dedicated.
    private func positionOnMainScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "presenter-display" }) else { return }
            let mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" })
            let targetScreen = mainWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first
            guard let screen = targetScreen else { return }
            let visible = screen.visibleFrame
            let w = min(1400, visible.width - 80)
            let h = min(900, visible.height - 80)
            let x = visible.origin.x + (visible.width - w) / 2
            let y = visible.origin.y + (visible.height - h) / 2
            window.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        }
    }
}
