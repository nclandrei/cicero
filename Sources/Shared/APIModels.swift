import Foundation

// MARK: - Responses

public struct SlideInfo: Codable, Sendable {
    public let index: Int
    public let title: String?
    public let content: String
    public let layout: String?
    public let imageURL: String?

    public init(index: Int, title: String?, content: String, layout: String? = nil, imageURL: String? = nil) {
        self.index = index
        self.title = title
        self.content = content
        self.layout = layout
        self.imageURL = imageURL
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

    public init(currentSlide: Int, totalSlides: Int, presenting: Bool, filePath: String?, title: String?) {
        self.currentSlide = currentSlide
        self.totalSlides = totalSlides
        self.presenting = presenting
        self.filePath = filePath
        self.title = title
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

public struct ErrorResponse: Codable, Sendable {
    public let error: String

    public init(_ message: String) {
        self.error = message
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

public struct PublishGistRequest: Codable, Sendable {
    public let isPublic: Bool

    public init(isPublic: Bool = false) {
        self.isPublic = isPublic
    }
}
