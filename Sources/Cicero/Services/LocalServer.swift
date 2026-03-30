import Foundation
import Swifter
import Shared

final class LocalServer {
    private let server = HttpServer()
    private let presentation: Presentation
    private let screenshotService: ScreenshotService

    init(presentation: Presentation) {
        self.presentation = presentation
        self.screenshotService = ScreenshotService(presentation: presentation)
        setupRoutes()
    }

    func start() {
        do {
            try server.start(CiceroConstants.httpPort, forceIPv4: true)
            print("[Cicero] HTTP server listening on port \(CiceroConstants.httpPort)")
        } catch {
            print("[Cicero] Failed to start HTTP server: \(error)")
        }
    }

    func stop() {
        server.stop()
    }

    // MARK: - Routes

    private func setupRoutes() {
        server.GET["/status"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                StatusResponse(
                    currentSlide: self.presentation.currentIndex,
                    totalSlides: self.presentation.slides.count,
                    presenting: self.presentation.isPresenting,
                    filePath: self.presentation.filePath?.path,
                    title: self.presentation.metadata.title
                )
            }
            return self.jsonResponse(resp)
        }

        server.GET["/slides"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                SlidesResponse(
                    count: self.presentation.slides.count,
                    slides: self.presentation.slides.map {
                        SlideInfo(index: $0.id, title: $0.title, content: $0.content)
                    },
                    currentIndex: self.presentation.currentIndex
                )
            }
            return self.jsonResponse(resp)
        }

        server.GET["/slides/:index"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                let slide = self.presentation.slides[index]
                return self.jsonResponse(SlideInfo(index: index, title: slide.title, content: slide.content))
            }
        }

        server.PUT["/slides/:index"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index"),
                  let body: UpdateSlideRequest = self.decodeBody(request)
            else {
                return self.jsonError("Invalid request")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                self.presentation.updateSlide(at: index, content: body.content)
                return self.jsonResponse(SuccessResponse(success: true))
            }
        }

        server.POST["/slides"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: AddSlideRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            self.onMain {
                self.presentation.addSlide(content: body.content, after: body.afterIndex)
            }
            return self.jsonResponse(SuccessResponse(success: true, message: "Slide added"))
        }

        server.DELETE["/slides/:index"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                self.presentation.removeSlide(at: index)
                return self.jsonResponse(SuccessResponse(success: true))
            }
        }

        server.GET["/current"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                NavigateResponse(
                    currentIndex: self.presentation.currentIndex,
                    totalSlides: self.presentation.slides.count
                )
            }
            return self.jsonResponse(resp)
        }

        server.POST["/navigate"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: NavigateRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            let resp = self.onMain { () -> NavigateResponse in
                switch body.action {
                case "next": self.presentation.next()
                case "prev": self.presentation.previous()
                case "goto":
                    if let idx = body.index { self.presentation.navigate(to: idx) }
                default: break
                }
                return NavigateResponse(
                    currentIndex: self.presentation.currentIndex,
                    totalSlides: self.presentation.slides.count
                )
            }
            return self.jsonResponse(resp)
        }

        server.GET["/screenshot"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            return self.renderScreenshot(index: nil)
        }

        server.GET["/screenshot/:index"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let index = self.pathInt(request, ":index")
            return self.renderScreenshot(index: index)
        }

        server.GET["/thumbnails"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let thumbs = self.onMain { () -> [ScreenshotResponse] in
                self.presentation.slides.compactMap { slide in
                    guard let data = self.screenshotService.renderThumbnailSync(slide) else { return nil }
                    return ScreenshotResponse(
                        base64PNG: data.base64EncodedString(),
                        slideIndex: slide.id
                    )
                }
            }
            return self.jsonResponse(ThumbnailsResponse(thumbnails: thumbs))
        }

        server.POST["/presentation/start"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            self.onMain { self.presentation.isPresenting = true }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .startPresentation, object: nil)
            }
            return self.jsonResponse(SuccessResponse(success: true))
        }

        server.POST["/presentation/stop"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            self.onMain { self.presentation.isPresenting = false }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .stopPresentation, object: nil)
            }
            return self.jsonResponse(SuccessResponse(success: true))
        }

        server.POST["/open"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: OpenFileRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            let url = URL(fileURLWithPath: body.path)
            do {
                try self.onMain { try self.presentation.loadFile(url) }
                return self.jsonResponse(SuccessResponse(success: true, message: "Opened \(body.path)"))
            } catch {
                return self.jsonError("Failed to open file: \(error.localizedDescription)")
            }
        }

        server.POST["/create"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: CreatePresentationRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            self.onMain { self.presentation.loadMarkdown(body.markdown) }
            return self.jsonResponse(SuccessResponse(success: true, message: "Presentation created"))
        }
    }

    // MARK: - Helpers

    private func renderScreenshot(index: Int?) -> HttpResponse {
        let result = onMain { () -> ScreenshotResponse? in
            let slideIndex = index ?? self.presentation.currentIndex
            guard slideIndex >= 0 && slideIndex < self.presentation.slides.count else { return nil }
            let slide = self.presentation.slides[slideIndex]
            guard let pngData = self.screenshotService.renderSlideSync(slide) else { return nil }
            return ScreenshotResponse(
                base64PNG: pngData.base64EncodedString(),
                slideIndex: slideIndex
            )
        }
        guard let result else { return jsonError("Failed to render screenshot") }
        return jsonResponse(result)
    }

    @discardableResult
    private func onMain<T>(_ block: @escaping () throws -> T) rethrows -> T {
        if Thread.isMainThread { return try block() }
        return try DispatchQueue.main.sync { try block() }
    }

    private func pathInt(_ request: HttpRequest, _ param: String) -> Int? {
        request.params[param].flatMap(Int.init)
    }

    private func decodeBody<T: Decodable>(_ request: HttpRequest) -> T? {
        try? JSONDecoder().decode(T.self, from: Data(request.body))
    }

    private func jsonResponse<T: Encodable>(_ value: T) -> HttpResponse {
        guard let data = try? JSONEncoder().encode(value) else {
            return .internalServerError
        }
        return .raw(200, "OK", ["Content-Type": "application/json"]) { writer in
            try writer.write([UInt8](data))
        }
    }

    private func jsonError(_ message: String, status: Int = 400) -> HttpResponse {
        guard let data = try? JSONEncoder().encode(ErrorResponse(message)) else {
            return .internalServerError
        }
        return .raw(status, "Error", ["Content-Type": "application/json"]) { writer in
            try writer.write([UInt8](data))
        }
    }
}

extension Notification.Name {
    static let startPresentation = Notification.Name("cicero.startPresentation")
    static let stopPresentation = Notification.Name("cicero.stopPresentation")
}
