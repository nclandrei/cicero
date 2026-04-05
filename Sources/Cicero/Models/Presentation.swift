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
    var elapsedSeconds: Int = 0
    var wallClock: String = TimeFormatting.wallClock()
    private var timer: Timer?

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

    // MARK: - Timer

    func startTimer() {
        elapsedSeconds = 0
        wallClock = TimeFormatting.wallClock()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            self.wallClock = TimeFormatting.wallClock()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
    }

    // MARK: - Private

    private func reindexSlides() {
        slides = slides.enumerated().map { index, slide in
            Slide(id: index, content: slide.content, body: slide.body, layout: slide.layout, imageURL: slide.imageURL)
        }
    }

    private func rebuildMarkdown() {
        markdown = SlideParser.serialize(metadata: metadata, slides: slides)
        isDirty = true
    }
}
