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

    /// On-disk modification time observed at the most recent successful
    /// save or load. Used by `save()` to detect that another process
    /// changed the file out from under us before we overwrite it.
    /// `nil` means we never observed the file (fresh save_as flow).
    private(set) var lastSavedMtime: Date?

    // MARK: - Presenter Timer
    private var timerState = PresentationTimerState()
    var wallClock: String = TimeFormatting.wallClock()
    private var timer: Timer?

    var elapsedSeconds: Int { timerState.elapsedSeconds }

    var isTimerRunning: Bool { timerState.isRunning }

    var timerLifecycle: PresentationTimerLifecycle { timerState.state }

    // MARK: - Autosave
    let autosave = AutosaveScheduler(debounceInterval: 2.0)
    private var autosaveWorkItem: DispatchWorkItem?

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

    /// Update multiple top-level metadata fields at once. Each parameter is optional;
    /// nil means "leave alone". Persisted by re-serializing the markdown frontmatter.
    func updateMetadata(
        title: String? = nil,
        author: String? = nil,
        theme: String? = nil,
        font: String? = nil,
        transition: PresentationTransition? = nil
    ) {
        if let title { metadata.title = title.isEmpty ? nil : title }
        if let author { metadata.author = author.isEmpty ? nil : author }
        if let theme {
            metadata.theme = theme
            if theme != "custom" {
                metadata.themeBackground = nil
                metadata.themeText = nil
                metadata.themeHeading = nil
                metadata.themeAccent = nil
                metadata.themeCodeBackground = nil
                metadata.themeCodeText = nil
            }
        }
        if let font { metadata.font = font.isEmpty ? nil : font }
        if let transition { metadata.transition = transition }
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
        autosave.cancel()
        autosaveWorkItem?.cancel()
        autosaveWorkItem = nil
    }

    func updateFromEditor(_ content: String) {
        markdown = content
        let result = SlideParser.parse(content)
        metadata = result.metadata
        slides = result.slides
        currentIndex = min(currentIndex, max(0, slides.count - 1))
        isDirty = true
        scheduleAutosave()
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
        scheduleAutosave()
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
        scheduleAutosave()
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

    /// Apply multiple slide content updates atomically. Caller must ensure all indices
    /// are valid; out-of-range entries are ignored. Rebuilds markdown once at the end.
    @discardableResult
    func bulkUpdateSlides(_ updates: [BulkSlideUpdate]) -> Int {
        var applied = 0
        for update in updates {
            guard update.index >= 0 && update.index < slides.count else { continue }
            slides[update.index] = Slide(id: update.index, content: update.content)
            applied += 1
        }
        if applied > 0 {
            rebuildMarkdown()
        }
        return applied
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

    /// Persist the in-memory markdown to `filePath`. Throws
    /// `PresentationSaveError.noFilePath` when no path is set, and
    /// `PresentationSaveError.externalConflict` when the file on disk has
    /// been modified by another process since we last touched it. Pass
    /// `force: true` to skip the conflict check (the manual "Save"
    /// command does this after asking the user).
    func save(force: Bool = false) throws {
        guard let path = filePath else {
            throw PresentationSaveError.noFilePath
        }
        if !force {
            let onDisk = Self.modificationDate(of: path)
            if SaveConflictPolicy.shouldRejectSave(lastKnown: lastSavedMtime, currentOnDisk: onDisk) {
                throw PresentationSaveError.externalConflict(path: path.path)
            }
        }
        try markdown.write(to: path, atomically: true, encoding: .utf8)
        lastSavedMtime = Self.modificationDate(of: path)
        isDirty = false
        autosave.cancel()
        autosaveWorkItem?.cancel()
        autosaveWorkItem = nil
    }

    /// Save the current markdown to a new path, creating intermediate directories
    /// as needed. Updates `filePath` so subsequent `save()` calls write there.
    func saveAs(url: URL) throws {
        let parent = url.deletingLastPathComponent()
        let fm = FileManager.default
        if !fm.fileExists(atPath: parent.path) {
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        filePath = url
        lastSavedMtime = Self.modificationDate(of: url)
        isDirty = false
    }

    func loadFile(_ url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        filePath = url
        lastSavedMtime = Self.modificationDate(of: url)
        loadMarkdown(content)
    }

    /// Read the file's modification time without throwing. Returns nil
    /// when the file is missing or the attribute is unavailable.
    private static func modificationDate(of url: URL) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attrs?[.modificationDate] as? Date
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
        applyUserDefaults()
    }

    /// Applies the user's saved default theme/font to the freshly loaded
    /// presentation. Called from `loadSamplePresentation()` and any other
    /// new-blank-presentation path. Doesn't touch presentations loaded
    /// from disk — those already carry their own metadata.
    private func applyUserDefaults() {
        let userTheme = AppDefaults.defaultTheme
        if userTheme != "auto" && userTheme != metadata.theme {
            setTheme(userTheme)
        }
        let userFont = AppDefaults.defaultFont
        if userFont != metadata.font {
            setFont(userFont)
        }
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
        // Also clear persisted per-slide drawings on the current slide.
        if currentIndex >= 0 && currentIndex < slides.count {
            setSlideDrawings(at: currentIndex, strokes: nil)
        }
    }

    // MARK: - Per-slide drawing persistence

    /// Read persisted drawings for a slide. Nil if the slide has none or
    /// if the index is out of bounds.
    func slideDrawings(at index: Int) -> [SlideDrawingStroke]? {
        guard index >= 0 && index < slides.count else { return nil }
        return slides[index].drawings
    }

    /// Persist drawings for a slide into its markdown content via the
    /// `drawings: <base64-json>` frontmatter line. Passing nil or an empty
    /// array removes the line. Triggers a markdown rebuild so the on-disk
    /// markdown stays in sync.
    func setSlideDrawings(at index: Int, strokes: [SlideDrawingStroke]?) {
        guard index >= 0 && index < slides.count else { return }
        slides[index].setDrawings(strokes)
        rebuildMarkdown()
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
        scheduleAutosave()
    }

    // MARK: - Autosave wiring

    private func scheduleAutosave() {
        guard filePath != nil else { return }
        autosave.contentChanged(at: Date())
        guard let due = autosave.pendingSaveDueAt else { return }
        autosaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.fireAutosave()
        }
        autosaveWorkItem = work
        let delay = max(0, due.timeIntervalSinceNow)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func fireAutosave() {
        do {
            try autosave.tick(at: Date()) { [weak self] in
                try self?.save()
            }
        } catch PresentationSaveError.noFilePath {
            // The deck was closed between scheduling and firing. Nothing to
            // surface — the autosave is a no-op by design when there's no
            // file path, and this is the expected race, not a failure.
            return
        } catch {
            errorMessage = "Autosave failed: \(error.localizedDescription)"
        }
    }
}
