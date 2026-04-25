import Foundation

// MARK: - Responses

public struct SlideInfo: Codable, Sendable {
    public let index: Int
    public let title: String?
    public let content: String
    public let layout: String?
    public let imageURL: String?
    public let videoURL: String?
    public let embedURL: String?
    public let notes: String?

    public init(index: Int, title: String?, content: String, layout: String? = nil, imageURL: String? = nil, videoURL: String? = nil, embedURL: String? = nil, notes: String? = nil) {
        self.index = index
        self.title = title
        self.content = content
        self.layout = layout
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.embedURL = embedURL
        self.notes = notes
    }
}

public struct SlidesResponse: Codable, Sendable {
    public let count: Int
    public let slides: [SlideInfo]
    public let currentIndex: Int

    public init(count: Int, slides: [SlideInfo], currentIndex: Int) {
        self.count = count
        self.slides = slides
        self.currentIndex = currentIndex
    }
}

public struct StatusResponse: Codable, Sendable {
    public let currentSlide: Int
    public let totalSlides: Int
    public let presenting: Bool
    public let filePath: String?
    public let title: String?
    public let theme: String?
    public let author: String?
    public let font: String?
    public let transition: String?

    public init(currentSlide: Int, totalSlides: Int, presenting: Bool, filePath: String?, title: String?, theme: String? = nil, author: String? = nil, font: String? = nil, transition: String? = nil) {
        self.currentSlide = currentSlide
        self.totalSlides = totalSlides
        self.presenting = presenting
        self.filePath = filePath
        self.title = title
        self.theme = theme
        self.author = author
        self.font = font
        self.transition = transition
    }
}

public struct NavigateResponse: Codable, Sendable {
    public let currentIndex: Int
    public let totalSlides: Int

    public init(currentIndex: Int, totalSlides: Int) {
        self.currentIndex = currentIndex
        self.totalSlides = totalSlides
    }
}

public struct ScreenshotResponse: Codable, Sendable {
    public let base64PNG: String
    public let slideIndex: Int

    public init(base64PNG: String, slideIndex: Int) {
        self.base64PNG = base64PNG
        self.slideIndex = slideIndex
    }
}

public struct ThumbnailsResponse: Codable, Sendable {
    public let thumbnails: [ScreenshotResponse]

    public init(thumbnails: [ScreenshotResponse]) {
        self.thumbnails = thumbnails
    }
}

public struct PublishGistResponse: Codable, Sendable {
    public let gistId: String
    public let url: String

    public init(gistId: String, url: String) {
        self.gistId = gistId
        self.url = url
    }
}

public struct SuccessResponse: Codable, Sendable {
    public let success: Bool
    public let message: String?

    public init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
}

public struct UndoRedoResponse: Codable, Sendable {
    public let success: Bool
    public let content: String?

    public init(success: Bool, content: String? = nil) {
        self.success = success
        self.content = content
    }
}

public struct ExportPDFResponse: Codable, Sendable {
    public let base64PDF: String
    public let pageCount: Int

    public init(base64PDF: String, pageCount: Int) {
        self.base64PDF = base64PDF
        self.pageCount = pageCount
    }
}

public struct ExportHTMLResponse: Codable, Sendable {
    public let html: String
    public let slideCount: Int

    public init(html: String, slideCount: Int) {
        self.html = html
        self.slideCount = slideCount
    }
}

public struct AddImageRequest: Codable, Sendable {
    public let base64Data: String
    public let name: String?

    public init(base64Data: String, name: String? = nil) {
        self.base64Data = base64Data
        self.name = name
    }
}

public struct AddImageResponse: Codable, Sendable {
    public let relativePath: String
    public let markdownSnippet: String

    public init(relativePath: String, markdownSnippet: String) {
        self.relativePath = relativePath
        self.markdownSnippet = markdownSnippet
    }
}

public struct SetImageTransformRequest: Codable, Sendable {
    public let path: String
    public let x: Double?
    public let y: Double?
    public let width: Double?

    public init(path: String, x: Double? = nil, y: Double? = nil, width: Double? = nil) {
        self.path = path
        self.x = x
        self.y = y
        self.width = width
    }
}

public struct AuthStatusResponse: Codable, Sendable {
    public let authenticated: Bool
    public let username: String?

    public init(authenticated: Bool, username: String?) {
        self.authenticated = authenticated
        self.username = username
    }
}

public struct ErrorResponse: Codable, Sendable {
    public let error: String

    public init(_ message: String) {
        self.error = message
    }
}

// MARK: - Presenter Tool Models

public struct PresenterToolResponse: Codable, Sendable {
    public let activeTool: String
    public let available: [String]
    public let drawingStrokeCount: Int

    public init(activeTool: String, available: [String], drawingStrokeCount: Int) {
        self.activeTool = activeTool
        self.available = available
        self.drawingStrokeCount = drawingStrokeCount
    }
}

public struct SetPresenterToolRequest: Codable, Sendable {
    public let tool: String

    public init(tool: String) {
        self.tool = tool
    }
}

// MARK: - Timer Models

public struct TimerResponse: Codable, Sendable {
    public let running: Bool
    public let elapsedSeconds: Int
    public let wallClock: String

    public init(running: Bool, elapsedSeconds: Int, wallClock: String) {
        self.running = running
        self.elapsedSeconds = elapsedSeconds
        self.wallClock = wallClock
    }
}

// MARK: - Requests

public struct NavigateRequest: Codable, Sendable {
    public let action: String
    public let index: Int?

    public init(action: String, index: Int? = nil) {
        self.action = action
        self.index = index
    }
}

public struct UpdateSlideRequest: Codable, Sendable {
    public let content: String

    public init(content: String) {
        self.content = content
    }
}

public struct SetLayoutRequest: Codable, Sendable {
    public let layout: String?

    public init(layout: String? = nil) {
        self.layout = layout
    }
}

public struct SetSlideURLRequest: Codable, Sendable {
    public let url: String?

    public init(url: String? = nil) {
        self.url = url
    }
}

public struct AddSlideRequest: Codable, Sendable {
    public let content: String
    public let afterIndex: Int?

    public init(content: String, afterIndex: Int? = nil) {
        self.content = content
        self.afterIndex = afterIndex
    }
}

public struct OpenFileRequest: Codable, Sendable {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

public struct CreatePresentationRequest: Codable, Sendable {
    public let markdown: String

    public init(markdown: String) {
        self.markdown = markdown
    }
}

public struct ReorderRequest: Codable, Sendable {
    public let from: Int
    public let to: Int

    public init(from: Int, to: Int) {
        self.from = from
        self.to = to
    }
}

public struct PublishGistRequest: Codable, Sendable {
    public let isPublic: Bool

    public init(isPublic: Bool = false) {
        self.isPublic = isPublic
    }
}

// MARK: - Notes Models

public struct NotesResponse: Codable, Sendable {
    public let index: Int
    public let notes: String?

    public init(index: Int, notes: String?) {
        self.index = index
        self.notes = notes
    }
}

public struct SetNotesRequest: Codable, Sendable {
    public let notes: String?

    public init(notes: String? = nil) {
        self.notes = notes
    }
}

// MARK: - Search Models

public struct SearchRequest: Codable, Sendable {
    public let query: String

    public init(query: String) {
        self.query = query
    }
}

public struct SearchMatch: Codable, Sendable {
    public let index: Int
    public let title: String?
    public let excerpt: String

    public init(index: Int, title: String?, excerpt: String) {
        self.index = index
        self.title = title
        self.excerpt = excerpt
    }
}

public struct SearchResponse: Codable, Sendable {
    public let query: String
    public let matches: [SearchMatch]

    public init(query: String, matches: [SearchMatch]) {
        self.query = query
        self.matches = matches
    }
}

// MARK: - Theme Models

public struct ThemeListResponse: Codable, Sendable {
    public let themes: [ThemeDefinition]

    public init(themes: [ThemeDefinition]) {
        self.themes = themes
    }
}

public struct ThemeResponse: Codable, Sendable {
    public let current: String?
    public let definition: ThemeDefinition?

    public init(current: String?, definition: ThemeDefinition?) {
        self.current = current
        self.definition = definition
    }
}

public struct SetThemeRequest: Codable, Sendable {
    public let name: String
    public let background: String?
    public let text: String?
    public let heading: String?
    public let accent: String?
    public let codeBackground: String?
    public let codeText: String?

    public init(
        name: String,
        background: String? = nil,
        text: String? = nil,
        heading: String? = nil,
        accent: String? = nil,
        codeBackground: String? = nil,
        codeText: String? = nil
    ) {
        self.name = name
        self.background = background
        self.text = text
        self.heading = heading
        self.accent = accent
        self.codeBackground = codeBackground
        self.codeText = codeText
    }
}

// MARK: - Font Models

public struct FontResponse: Codable, Sendable {
    public let current: String?
    public let available: [String]

    public init(current: String?, available: [String]) {
        self.current = current
        self.available = available
    }
}

public struct SetFontRequest: Codable, Sendable {
    public let name: String?

    public init(name: String? = nil) {
        self.name = name
    }
}

// MARK: - Transition Models

public struct TransitionResponse: Codable, Sendable {
    public let current: String
    public let available: [String]

    public init(current: String, available: [String]) {
        self.current = current
        self.available = available
    }
}

public struct SetTransitionRequest: Codable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

// MARK: - Save Model

public struct SaveResponse: Codable, Sendable {
    public let success: Bool
    public let filePath: String?

    public init(success: Bool, filePath: String? = nil) {
        self.success = success
        self.filePath = filePath
    }
}

// MARK: - Markdown Model

public struct GetMarkdownResponse: Codable, Sendable {
    public let markdown: String
    public let filePath: String?
    public let isDirty: Bool

    public init(markdown: String, filePath: String? = nil, isDirty: Bool = false) {
        self.markdown = markdown
        self.filePath = filePath
        self.isDirty = isDirty
    }
}
