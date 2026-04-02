import Foundation
import Swifter
import Shared

final class LocalServer {
    private let server = HttpServer()
    private let presentation: Presentation
    private let screenshotService: ScreenshotService
    private let pdfExportService: PDFExportService
    private let auth: GitHubAuth?

    init(presentation: Presentation, auth: GitHubAuth? = nil) {
        self.presentation = presentation
        self.auth = auth
        self.screenshotService = ScreenshotService(presentation: presentation)
        self.pdfExportService = PDFExportService(screenshotService: screenshotService)
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
                    title: self.presentation.metadata.title,
                    theme: self.presentation.metadata.theme
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
                        SlideInfo(
                            index: $0.id,
                            title: $0.title,
                            content: $0.content,
                            layout: $0.layout == .default ? nil : $0.layout.rawValue,
                            imageURL: $0.imageURL
                        )
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
                return self.jsonResponse(SlideInfo(
                    index: index,
                    title: slide.title,
                    content: slide.content,
                    layout: slide.layout == .default ? nil : slide.layout.rawValue,
                    imageURL: slide.imageURL
                ))
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

        server.GET["/export/pdf"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let result = self.onMain { () -> ExportPDFResponse? in
                let slides = self.presentation.slides
                guard !slides.isEmpty else { return nil }
                guard let pdfData = self.pdfExportService.exportPDF(slides: slides) else { return nil }
                return ExportPDFResponse(
                    base64PDF: pdfData.base64EncodedString(),
                    pageCount: slides.count
                )
            }
            guard let result else { return self.jsonError("Failed to export PDF") }
            return self.jsonResponse(result)
        }

        server.POST["/images"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: AddImageRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            guard let imageData = Data(base64Encoded: body.base64Data) else {
                return self.jsonError("Invalid base64 image data")
            }
            let result = self.onMain { () -> AddImageResponse? in
                guard let store = self.presentation.imageStore else {
                    return nil
                }
                guard let relativePath = store.storeImage(imageData, suggestedName: body.name) else {
                    return nil
                }
                let alt = body.name ?? "image"
                let snippet = "![\(alt)](\(relativePath))"
                return AddImageResponse(relativePath: relativePath, markdownSnippet: snippet)
            }
            guard let result else {
                return self.jsonError("Failed to store image. Is a presentation file saved?")
            }
            return self.jsonResponse(result)
        }

        server.GET["/auth/status"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            guard let auth = self.auth else {
                return self.jsonResponse(AuthStatusResponse(authenticated: false, username: nil))
            }
            var authenticated = false
            var username: String?
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                authenticated = await auth.isAuthenticated
                username = await auth.username
                semaphore.signal()
            }
            semaphore.wait()
            return self.jsonResponse(AuthStatusResponse(authenticated: authenticated, username: username))
        }

        server.GET["/themes"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            return self.jsonResponse(ThemeListResponse(themes: ThemeRegistry.builtIn))
        }

        server.GET["/theme"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                ThemeResponse(
                    current: self.presentation.metadata.theme,
                    definition: self.presentation.resolvedTheme
                )
            }
            return self.jsonResponse(resp)
        }

        server.PUT["/theme"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: SetThemeRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            self.onMain {
                if body.name == "custom", let bg = body.background {
                    self.presentation.setCustomTheme(
                        background: bg,
                        text: body.text,
                        heading: body.heading,
                        accent: body.accent,
                        codeBackground: body.codeBackground,
                        codeText: body.codeText
                    )
                } else {
                    self.presentation.setTheme(body.name)
                }
            }
            let resp = self.onMain {
                ThemeResponse(
                    current: self.presentation.metadata.theme,
                    definition: self.presentation.resolvedTheme
                )
            }
            return self.jsonResponse(resp)
        }

        server.GET["/search"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let query = request.queryParams.first(where: { $0.0 == "q" })?.1,
                  !query.isEmpty
            else {
                return self.jsonError("Missing 'q' query parameter")
            }
            let decoded = query.removingPercentEncoding ?? query
            let matches = self.onMain { () -> [SearchMatch] in
                let lower = decoded.lowercased()
                return self.presentation.slides.compactMap { slide -> SearchMatch? in
                    let body = slide.body.lowercased()
                    let title = slide.title?.lowercased() ?? ""
                    guard body.contains(lower) || title.contains(lower) else { return nil }
                    let excerpt = Self.extractExcerpt(from: slide.body, query: decoded)
                    return SearchMatch(index: slide.id, title: slide.title, excerpt: excerpt)
                }
            }
            return self.jsonResponse(SearchResponse(query: decoded, matches: matches))
        }

        server.POST["/publish"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let body: PublishGistRequest? = self.decodeBody(request)
            let isPublic = body?.isPublic ?? false

            let markdown = self.onMain { self.presentation.markdown }
            let title = self.onMain { self.presentation.metadata.title ?? "Presentation" }
            let existingGistId = self.onMain { self.presentation.metadata.gistId }
            let filename = "\(title).md"

            // Get token from auth
            guard let auth = self.auth else {
                return self.jsonError("Not signed in to GitHub. Sign in via Settings (Cmd+,).", status: 401)
            }

            var token: String?
            let tokenSemaphore = DispatchSemaphore(value: 0)
            Task {
                token = await auth.token
                tokenSemaphore.signal()
            }
            tokenSemaphore.wait()

            guard let token else {
                return self.jsonError("Not signed in to GitHub. Sign in via Settings (Cmd+,).", status: 401)
            }

            // Run async gist publish synchronously for the HTTP handler
            var result: (gistId: String, url: String)?
            var error: Error?
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    result = try await GistService.shared.publish(
                        token: token,
                        filename: filename,
                        content: markdown,
                        description: title,
                        isPublic: isPublic,
                        existingGistId: existingGistId
                    )
                } catch let e {
                    error = e
                }
                semaphore.signal()
            }
            semaphore.wait()

            if let error {
                return self.jsonError(error.localizedDescription)
            }
            guard let result else {
                return self.jsonError("Unknown publish error")
            }

            // Store gist ID in metadata
            self.onMain {
                self.presentation.metadata.gistId = result.gistId
            }

            let ciceroURL = "https://cicero.nicolaeandrei.com/#/g/\(result.gistId)"
            return self.jsonResponse(PublishGistResponse(gistId: result.gistId, url: ciceroURL))
        }
    }

    // MARK: - Search helper

    private static func extractExcerpt(from body: String, query: String, radius: Int = 60) -> String {
        guard let range = body.range(of: query, options: .caseInsensitive) else {
            // Fallback: return first `radius` chars
            let end = body.index(body.startIndex, offsetBy: min(radius, body.count))
            return String(body[body.startIndex..<end])
        }
        let matchStart = body.distance(from: body.startIndex, to: range.lowerBound)
        let matchEnd = body.distance(from: body.startIndex, to: range.upperBound)
        let excerptStart = max(0, matchStart - radius)
        let excerptEnd = min(body.count, matchEnd + radius)
        let start = body.index(body.startIndex, offsetBy: excerptStart)
        let end = body.index(body.startIndex, offsetBy: excerptEnd)
        return String(body[start..<end]).replacingOccurrences(of: "\n", with: " ")
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
