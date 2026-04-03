import AppKit
import SwiftUI

/// A custom NSViewRepresentable wrapping NSTextView that intercepts image file drops
/// instead of letting NSTextView insert the raw file path as text.
struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    var onImageDrop: ((_ data: Data, _ name: String?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = DropInterceptingTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor

        // Make text view resize with scroll view
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        textView.delegate = context.coordinator
        let coordinator = context.coordinator
        textView.onImageDrop = { data, name in
            coordinator.parent.onImageDrop?(data, name)
        }

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Avoid feedback loop: only update if text actually differs
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        weak var textView: NSTextView?
        private var isUpdating = false

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            isUpdating = false
        }
    }
}

/// NSTextView subclass that intercepts image file drops and delegates them
/// to our handler instead of inserting the file path as text.
class DropInterceptingTextView: NSTextView {
    var onImageDrop: ((_ data: Data, _ name: String?) -> Void)?

    private let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "webp", "heic"]

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] else {
            // Not a file drop — let NSTextView handle it (e.g. text drag)
            return super.performDragOperation(sender)
        }

        // Check if any dropped file is an image
        let imageFiles = pasteboard.filter { path in
            let ext = (path as NSString).pathExtension.lowercased()
            return imageExtensions.contains(ext)
        }

        if !imageFiles.isEmpty {
            for path in imageFiles {
                let url = URL(fileURLWithPath: path)
                guard let data = try? Data(contentsOf: url) else { continue }
                let name = url.deletingPathExtension().lastPathComponent
                onImageDrop?(data, name)
            }
            return true
        }

        // Not an image file — fall back to default behavior
        return super.performDragOperation(sender)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        // Check if this is an image file drag
        if let files = sender.draggingPasteboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] {
            let hasImage = files.contains { path in
                let ext = (path as NSString).pathExtension.lowercased()
                return imageExtensions.contains(ext)
            }
            if hasImage {
                return .copy
            }
        }
        return super.draggingEntered(sender)
    }
}
