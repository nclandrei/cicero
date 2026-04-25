import SwiftUI
import Shared

struct SpeakerNotesEditor: View {
    @Environment(Presentation.self) private var presentation
    @State private var notesText: String = ""
    @State private var lastSyncedIndex: Int = -1

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Speaker Notes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)

            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notesText)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .accessibilityLabel("Speaker notes")
                    .accessibilityHint("Notes shown only in the presenter window for the current slide")

                if notesText.isEmpty {
                    Text("Add speaker notes...")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .frame(minHeight: 60, idealHeight: 110, maxHeight: 300)
        .onAppear {
            syncFromSlide()
        }
        .onChange(of: presentation.currentIndex) { _, _ in
            syncFromSlide()
        }
        .onChange(of: presentation.currentSlide?.notes) { _, newNotes in
            // Sync if external change (e.g. editor modified the slide)
            if presentation.currentIndex == lastSyncedIndex {
                let incoming = newNotes ?? ""
                if incoming != notesText {
                    notesText = incoming
                }
            } else {
                syncFromSlide()
            }
        }
        .onChange(of: notesText) { _, newValue in
            writeNotesToSlide(newValue)
        }
    }

    private func syncFromSlide() {
        lastSyncedIndex = presentation.currentIndex
        notesText = presentation.currentSlide?.notes ?? ""
    }

    private func writeNotesToSlide(_ notes: String) {
        let idx = presentation.currentIndex
        guard idx >= 0 && idx < presentation.slides.count else { return }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentNotes = presentation.slides[idx].notes
        // Avoid no-op writes
        if trimmed.isEmpty && currentNotes == nil { return }
        if trimmed == currentNotes { return }
        presentation.updateNotes(at: idx, notes: trimmed.isEmpty ? nil : trimmed)
    }
}
