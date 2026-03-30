import SwiftUI

struct SlideEditorView: View {
    @Environment(Presentation.self) private var presentation

    var body: some View {
        @Bindable var presentation = presentation

        VStack(spacing: 0) {
            // Slide indicator
            HStack {
                Text("Markdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if presentation.isDirty {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .help("Unsaved changes")
                }
                Text("\(presentation.slides.count) slides")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            TextEditor(text: Binding(
                get: { presentation.markdown },
                set: { presentation.updateFromEditor($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.visible)
        }
    }
}
