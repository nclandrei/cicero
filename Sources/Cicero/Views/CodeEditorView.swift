import AppKit
import SwiftUI

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    var onImageDrop: ((_ data: Data, _ name: String?) -> Void)?
    var onCursorLineChange: ((Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        let textView = DropInterceptingTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = font
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor

        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        textView.delegate = context.coordinator
        let coordinator = context.coordinator
        coordinator.baseFont = font
        textView.onImageDrop = { data, name in
            coordinator.parent.onImageDrop?(data, name)
        }

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        // Apply highlighting after every update
        context.coordinator.applyHighlighting()
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        weak var textView: NSTextView?
        var baseFont: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        private let highlighter = MarkdownHighlighter()
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            scheduleHighlighting()
            reportCursorLine(textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            reportCursorLine(textView)
        }

        private var lastReportedLine: Int = -1

        private func reportCursorLine(_ textView: NSTextView) {
            guard let onCursorLineChange = parent.onCursorLineChange else { return }
            let selected = textView.selectedRange()
            let nsString = textView.string as NSString
            let location = min(selected.location, nsString.length)
            let prefix = nsString.substring(with: NSRange(location: 0, length: location))
            let line = prefix.reduce(0) { $1 == "\n" ? $0 + 1 : $0 }
            if line != lastReportedLine {
                lastReportedLine = line
                onCursorLineChange(line)
            }
        }

        func scheduleHighlighting() {
            highlightWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyHighlighting()
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        }

        func applyHighlighting() {
            guard let textView, let storage = textView.textStorage, storage.length > 0 else { return }

            // Switch to rich text mode to enable attribute-based coloring
            if !textView.isRichText {
                textView.isRichText = true
                textView.usesFontPanel = false
                textView.usesRuler = false
                textView.isAutomaticLinkDetectionEnabled = false
            }

            highlighter.isDark = textView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            highlighter.baseFont = baseFont
            highlighter.highlight(in: textView)
        }
    }
}

class DropInterceptingTextView: NSTextView {
    var onImageDrop: ((_ data: Data, _ name: String?) -> Void)?

    private let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "webp", "heic"]

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if let coordinator = delegate as? CodeEditorView.Coordinator {
            coordinator.applyHighlighting()
        }
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] else {
            return super.performDragOperation(sender)
        }

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

        return super.performDragOperation(sender)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
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
