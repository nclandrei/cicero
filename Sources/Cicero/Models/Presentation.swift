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

    var currentSlide: Slide? {
        guard currentIndex >= 0 && currentIndex < slides.count else { return nil }
        return slides[currentIndex]
    }

    var resolvedTheme: ThemeDefinition? {
        metadata.resolveTheme()
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

    /// Stores an image and returns the markdown snippet to insert
    func addImage(_ data: Data, name: String? = nil) -> String? {
        guard let store = imageStore,
              let path = store.storeImage(data, suggestedName: name)
        else { return nil }
        let alt = name ?? "image"
        return "![\(alt)](\(path))"
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
