import SwiftUI

struct PresenterToolbar: View {
    @Binding var currentTool: PresenterTool
    let onClearDrawings: () -> Void
    let onExit: () -> Void

    @State private var isVisible = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 12) {
                    toolButton(
                        icon: "hand.point.up.left",
                        tool: .pointer,
                        label: "Pointer (P)",
                        accessibilityLabel: "Pointer tool",
                        accessibilityHint: "Toggles a virtual laser pointer that follows the cursor"
                    )
                    toolButton(
                        icon: "light.max",
                        tool: .spotlight,
                        label: "Spotlight (S)",
                        accessibilityLabel: "Spotlight tool",
                        accessibilityHint: "Toggles a spotlight that dims the slide except around the cursor"
                    )
                    toolButton(
                        icon: "pencil.tip",
                        tool: .drawing,
                        label: "Draw (D)",
                        accessibilityLabel: "Drawing tool",
                        accessibilityHint: "Toggles freehand drawing on top of the slide"
                    )

                    Divider()
                        .frame(height: 20)
                        .background(.white.opacity(0.3))

                    Button(action: onClearDrawings) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .accessibilityHidden(true)
                    }
                    .buttonStyle(.plain)
                    .help("Clear Drawings (C)")
                    .accessibilityLabel("Clear drawings")
                    .accessibilityHint("Removes all freehand drawings from the slide")

                    Button(action: onExit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .accessibilityHidden(true)
                    }
                    .buttonStyle(.plain)
                    .help("Exit Presentation")
                    .accessibilityLabel("Exit presentation")
                    .accessibilityHint("Closes the presenter window")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6), in: Capsule())
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Persistent hint pill — shows when toolbar is hidden
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .onTapGesture { showToolbar() }
                    .accessibilityLabel("Show presenter toolbar")
                    .accessibilityHint("Reveals the presenter tool controls")
                    .accessibilityAddTraits(.isButton)
            }

            Spacer()
        }
        .padding(.top, 16)
        .onAppear {
            scheduleHide()
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                showToolbar()
            case .ended:
                scheduleHide()
            }
        }
    }

    @ViewBuilder
    private func toolButton(
        icon: String,
        tool: PresenterTool,
        label: String,
        accessibilityLabel: String,
        accessibilityHint: String
    ) -> some View {
        let isActive = currentTool == tool
        Button {
            currentTool = isActive ? .none : tool
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isActive ? .yellow : .white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(isActive ? .white.opacity(0.15) : .clear, in: Circle())
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(isActive ? "On" : "Off")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private func showToolbar() {
        hideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = true
        }
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}
