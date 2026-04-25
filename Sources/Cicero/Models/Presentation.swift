import Foundation
import Observation
import Shared

@Observable
final class Presentation {
    var markdown: String = ""
    var metadata: PresentationMetadata = PresentationMetadata()
    var slides: [Slide] = []
    var currentIndex: Int = 0
    var filePath: URL? {
        didSet {
            if let filePath {
                imageStore = ImageStore(baseURL: filePath)
            }
        }
    }
    var isPresenting: Bool = false
    var isDirty: Bool = false
    var imageStore: ImageStore?
    var errorMessage: String?
    let editHistory = EditHistory()

    // MARK: - Presenter Timer
    private var timerState = PresentationTimerState()
    var wallClock: String = TimeFormatting.wallClock()
    private var timer: Timer?

    var elapsedSeconds: Int { timerState.elapsedSeconds }

    var isTimerRunning: Bool { timerState.isRunning }

    var timerLifecycle: PresentationTimerLifecycle { timerState.state }

    var currentSlide: Slide? {
        guard currentIndex >= 0 && currentIndex < slides.count else { return nil }
        return slides[currentIndex]
    }

    var resolvedTheme: ThemeDefinition? {
        metadata.resolveTheme()
    }

    func setFont(_ name: String?) {
        metadata.font = name
        rebuildMarkdown()
    }

    func setTheme(_ name: String) {
        metadata.theme = name
        if name != "custom" {
            metadata.themeBackground = nil
            metadata.themeText = nil
            metadata.themeHeading = nil
            metadata.themeAccent = nil
            metadata.themeCodeBackground = nil
            metadata.themeCodeText = nil
        }
        rebuildMarkdown()
    }

    func setCustomTheme(
        background: String,
        text: String? = nil,
        heading: String? = nil,
        accent: String? = nil,
        codeBackground: String? = nil,
        codeText: String? = nil
    ) {
        metadata.theme = "custom"
        metadata.themeBackground = background
        metadata.themeText = text
        metadata.themeHeading = heading
        metadata.themeAccent = accent
        metadata.themeCodeBackground = codeBackground
        metadata.themeCodeText = codeText
        rebuildMarkdown()
    }

    init() {
        loadSamplePresentation()
    }

    func loadMarkdown(_ content: String) {
        let result = SlideParser.parse(content)
        markdown = content
        metadata = result.metadata
        slides = result.slides
        currentIndex = min(currentIndex, max(0, slides.count - 1))
        isDirty = false
    }

    func updateFromEditor(_ content: String) {
        markdown = content
        let result = SlideParser.parse(content)
        metadata = result.metadata
        slides = result.slides
        currentIndex = min(currentIndex, max(0, slides.count - 1))
        isDirty = true
    }

    // MARK: - Undo/Redo

    func undoEdit() -> Bool {
        guard let previous = editHistory.undo(currentText: markdown) else { return false }
        let result = SlideParser.parse(previous)
        markdown = previous
        metadata = result.metadata
        slides = result.slides
        currentIndex = min(currentIndex, max(0, slides.count - 1))
        isDirty = true
        return true
    }

    func redoEdit() -> Bool {
        guard let next = editHistory.redo(currentText: markdown) else { return false }
        let result = SlideParser.parse(next)
        markdown = next
        metadata = result.metadata
        slides = result.slides
        currentIndex = min(currentIndex, max(0, slides.count - 1))
        isDirty = true
        return true
    }

    func navigate(to index: Int) {
        guard index >= 0 && index < slides.count else { return }
        currentIndex = index
    }

    func next() { navigate(to: currentIndex + 1) }
    func previous() { navigate(to: currentIndex - 1) }

    func updateSlide(at index: Int, content: String) {
        guard index >= 0 && index < slides.count else { return }
        slides[index] = Slide(id: index, content: content)
        rebuildMarkdown()
    }

    func duplicateSlide(at index: Int) {
        guard index >= 0 && index < slides.count else { return }
        let original = slides[index]
        slides.insert(Slide(id: index + 1, content: original.content), at: index + 1)
        reindexSlides()
        currentIndex = index + 1
        rebuildMarkdown()
    }

    /// Update the speaker notes for a slide. Inserts, updates, or removes the
    /// `<!-- notes ... -->` block in the slide's raw content.
    func updateNotes(at index: Int, notes: String?) {
        guard index >= 0 && index < slides.count else { return }
        let slide = slides[index]
        let (bodyWithoutNotes, _) = SlideParser.extractNotes(slide.content)
        var newContent = bodyWithoutNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newContent += "\n\n<!-- notes\n\(notes)\n-->"
        }
        updateSlide(at: index, content: newContent)
    }

    /// Convenience accessor for the current slide's speaker notes.
    func notesForCurrentSlide() -> String? {
        currentSlide?.notes
    }

    func addSlide(content: String, after index: Int? = nil) {
        let insertAt = (index ?? slides.count - 1) + 1
        slides.insert(Slide(id: insertAt, content: content), at: min(insertAt, slides.count))
        reindexSlides()
        rebuildMarkdown()
    }

    func moveSlide(from source: Int, to destination: Int) {
        guard source >= 0 && source < slides.count,
              destination >= 0 && destination < slides.count,
              source != destination
        else { return }
        let slide = slides.remove(at: source)
        slides.insert(slide, at: destination)
        reindexSlides()
        if currentIndex == source {
            currentIndex = destination
        } else if source < currentIndex && destination >= currentIndex {
            currentIndex -= 1
        } else if source > currentIndex && destination <= currentIndex {
            currentIndex += 1
        }
        rebuildMarkdown()
    }

    func removeSlide(at index: Int) {
        guard index >= 0 && index < slides.count, slides.count > 1 else { return }
        slides.remove(at: index)
        reindexSlides()
        if currentIndex >= slides.count {
            currentIndex = slides.count - 1
        }
        rebuildMarkdown()
    }

    func save() throws {
        guard let path = filePath else { return }
        try markdown.write(to: path, atomically: true, encoding: .utf8)
        isDirty = false
    }

    func loadFile(_ url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        filePath = url
        loadMarkdown(content)
    }

    func loadSamplePresentation() {
        let sample = """
        ---
        title: Welcome to Cicero
        theme: auto
        author: Andrei Nicolae
        ---

        layout: title
        # Welcome to Cicero

        AI-native presentations in markdown

        ---

        ## Key Features

        - **Markdown-first** slides
        - AI agent control via **MCP**
        - **GitHub Gist** publishing
        - Live preview editing

        ```swift
        let cicero = Presentation("slides.md")
        cicero.present()
        ```

        ---

        ## Getting Started

        1. Write your slides in markdown
        2. Separate slides with `---`
        3. Use the editor or let AI create content
        4. Present with a single click

        ---

        ## Thank You

        Questions?
        """
        loadMarkdown(sample)
    }

    /// Stores an image and returns the markdown snippet to insert.
    /// Default fragment positions the image as a small draggable overlay
    /// roughly centered on a 960×540 slide.
    func addImage(_ data: Data, name: String? = nil) -> String? {
        guard let store = imageStore,
              let path = store.storeImage(data, suggestedName: name)
        else { return nil }
        let alt = name ?? "image"
        return "![\(alt)](\(path)#w=400&x=280&y=170)"
    }

    // MARK: - Presenter Tools
    var activeTool: String = "none"  // Use String to avoid importing SwiftUI enum
    var drawingStrokes: [[CGPoint]] = []

    func setPresenterTool(_ tool: String) {
        let valid = ["none", "pointer", "spotlight", "drawing"]
        guard valid.contains(tool) else { return }
        activeTool = tool
    }

    func clearDrawings() {
        drawingStrokes = []
    }

    // MARK: - Timer

    /// Start the timer fresh. Resets elapsed seconds to 0 and runs.
    /// Idempotent across all states — calling startTimer always starts fresh.
    func startTimer() {
        timerState.start()
        wallClock = TimeFormatting.wallClock()
        scheduleTimer()
    }

    /// Pause the running timer, preserving elapsed seconds. No-op if not running.
    /// Use resumeTimer() to continue accumulating from the paused elapsed value.
    func pauseTimer() {
        guard timerState.isRunning else { return }
        timerState.pause()
        timer?.invalidate()
        timer = nil
    }

    /// Resume the timer from a paused state, continuing to accumulate from the
    /// current elapsed seconds. No-op if not paused.
    func resumeTimer() {
        guard timerState.state == .paused else { return }
        timerState.resume()
        wallClock = TimeFormatting.wallClock()
        scheduleTimer()
    }

    /// Reset the timer fully — invalidates the running source and zeroes elapsed.
    /// Equivalent to stopTimer() but named for clarity at call sites.
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerState.reset()
    }

    /// Stop the timer. Existing semantics preserved: zeroes elapsed and goes idle.
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState.stop()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timerState.tick()
            self.wallClock = TimeFormatting.wallClock()
        }
    }

    // MARK: - Private

    private func reindexSlides() {
        slides.reindex()
    }

    private func rebuildMarkdown() {
        markdown = SlideParser.serialize(metadata: metadata, slides: slides)
        isDirty = true
    }
}
