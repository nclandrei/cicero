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
                    theme: self.presentation.metadata.theme,
                    author: self.presentation.metadata.author,
                    font: self.presentation.metadata.font,
                    transition: (self.presentation.metadata.transition ?? .none).rawValue
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
                            imageURL: $0.imageURL,
                            videoURL: $0.videoURL,
                            embedURL: $0.embedURL,
                            notes: $0.notes
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
                    imageURL: slide.imageURL,
                    videoURL: slide.videoURL,
                    embedURL: slide.embedURL,
                    notes: slide.notes
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

        server.PUT["/slides/:index/image-transform"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index"),
                  let body: SetImageTransformRequest = self.decodeBody(request)
            else {
                return self.jsonError("Invalid request")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                let content = self.presentation.slides[index].content

                // Find current image fragment values (if any) for this path.
                let escaped = NSRegularExpression.escapedPattern(for: body.path)
                let pattern = "\\]\\(\(escaped)(#[^)]*)?\\)"
                guard let regex = try? NSRegularExpression(pattern: pattern) else {
                    return self.jsonError("Failed to build regex")
                }
                let nsContent = content as NSString
                let range = NSRange(location: 0, length: nsContent.length)
                let matches = regex.matches(in: content, range: range)
                guard let match = matches.first else {
                    return self.jsonError("Image '\(body.path)' not found on slide \(index)", status: 404)
                }

                // Parse existing fragment for defaults when fields are omitted.
                var existingWidth: Double = 400
                var existingX: Double = 280
                var existingY: Double = 170
                if match.numberOfRanges > 1, match.range(at: 1).location != NSNotFound {
                    let fragmentWithHash = nsContent.substring(with: match.range(at: 1))
                    let fragment = fragmentWithHash.hasPrefix("#")
                        ? String(fragmentWithHash.dropFirst())
                        : fragmentWithHash
                    for param in fragment.split(separator: "&") {
                        let parts = param.split(separator: "=", maxSplits: 1)
                        guard parts.count == 2, let value = Double(parts[1]) else { continue }
                        switch parts[0] {
                        case "w": existingWidth = value
                        case "x": existingX = value
                        case "y": existingY = value
                        default: break
                        }
                    }
                }

                let finalWidth = body.width ?? existingWidth
                let finalX = body.x ?? existingX
                let finalY = body.y ?? existingY

                let replacement = "](\(body.path)#w=\(Int(finalWidth))&x=\(Int(finalX))&y=\(Int(finalY)))"
                let newContent = regex.stringByReplacingMatches(
                    in: content, range: range, withTemplate: replacement
                )
                self.presentation.updateSlide(at: index, content: newContent)
                return self.jsonResponse(SuccessResponse(
                    success: true,
                    message: "Image transform updated on slide \(index)"
                ))
            }
        }

        // MARK: - Per-slide metadata setters

        server.PUT["/slides/:index/layout"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            let body: SetLayoutRequest? = self.decodeBody(request)
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                if let layoutValue = body?.layout, !layoutValue.isEmpty {
                    guard SlideLayout(rawValue: layoutValue) != nil else {
                        return self.jsonError("Unknown layout '\(layoutValue)'. Valid: default, title, two-column, image-left, image-right, video, embed", status: 400)
                    }
                }
                let oldContent = self.presentation.slides[index].content
                let newContent = SlideParser.setSlideMetadataField(oldContent, key: "layout", value: body?.layout)
                self.presentation.updateSlide(at: index, content: newContent)
                let slide = self.presentation.slides[index]
                return self.jsonResponse(SlideInfo(
                    index: index,
                    title: slide.title,
                    content: slide.content,
                    layout: slide.layout == .default ? nil : slide.layout.rawValue,
                    imageURL: slide.imageURL,
                    videoURL: slide.videoURL,
                    embedURL: slide.embedURL,
                    notes: slide.notes
                ))
            }
        }

        server.PUT["/slides/:index/image"] = { [weak self] request in
            self?.handleSlideURLUpdate(request: request, key: "image") ?? .internalServerError
        }
        server.PUT["/slides/:index/video"] = { [weak self] request in
            self?.handleSlideURLUpdate(request: request, key: "video") ?? .internalServerError
        }
        server.PUT["/slides/:index/embed"] = { [weak self] request in
            self?.handleSlideURLUpdate(request: request, key: "embed") ?? .internalServerError
        }

        // MARK: - Speaker Notes

        server.GET["/slides/:index/notes"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                let notes = self.presentation.slides[index].notes
                return self.jsonResponse(NotesResponse(index: index, notes: notes))
            }
        }

        server.PUT["/slides/:index/notes"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            let body: SetNotesRequest? = self.decodeBody(request)
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                self.presentation.updateNotes(at: index, notes: body?.notes)
                let notes = self.presentation.slides[index].notes
                return self.jsonResponse(NotesResponse(index: index, notes: notes))
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

        server.POST["/slides/:index/duplicate"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let index = self.pathInt(request, ":index") else {
                return self.jsonError("Invalid slide index")
            }
            return self.onMain {
                guard index >= 0 && index < self.presentation.slides.count else {
                    return self.jsonError("Slide index out of range", status: 404)
                }
                self.presentation.duplicateSlide(at: index)
                return self.jsonResponse(SuccessResponse(success: true, message: "Slide \(index + 1) duplicated"))
            }
        }

        server.POST["/slides/reorder"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: ReorderRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body. Expected {\"from\": Int, \"to\": Int}")
            }
            return self.onMain {
                let count = self.presentation.slides.count
                guard body.from >= 0 && body.from < count else {
                    return self.jsonError("'from' index out of range", status: 400)
                }
                guard body.to >= 0 && body.to < count else {
                    return self.jsonError("'to' index out of range", status: 400)
                }
                self.presentation.moveSlide(from: body.from, to: body.to)
                return self.jsonResponse(SuccessResponse(success: true, message: "Moved slide from \(body.from) to \(body.to)"))
            }
        }

        server.GET["/current"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain { () -> CurrentSlideResponse in
                let idx = self.presentation.currentIndex
                let total = self.presentation.slides.count
                guard idx >= 0 && idx < total else {
                    return CurrentSlideResponse(currentIndex: idx, totalSlides: total, slide: nil)
                }
                let s = self.presentation.slides[idx]
                let info = SlideInfo(
                    index: idx,
                    title: s.title,
                    content: s.content,
                    layout: s.layout == .default ? nil : s.layout.rawValue,
                    imageURL: s.imageURL,
                    videoURL: s.videoURL,
                    embedURL: s.embedURL,
                    notes: s.notes
                )
                return CurrentSlideResponse(currentIndex: idx, totalSlides: total, slide: info)
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

        server.GET["/screenshot"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let savePath = request.queryParams.first(where: { $0.0 == "save_path" })?.1.removingPercentEncoding
            return self.renderScreenshot(index: nil, savePath: savePath)
        }

        server.GET["/screenshot/:index"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let index = self.pathInt(request, ":index")
            let savePath = request.queryParams.first(where: { $0.0 == "save_path" })?.1.removingPercentEncoding
            return self.renderScreenshot(index: index, savePath: savePath)
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

        // MARK: - Presenter Tools

        server.GET["/presenter/tool"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                PresenterToolResponse(
                    activeTool: self.presentation.activeTool,
                    available: ["none", "pointer", "spotlight", "drawing"],
                    drawingStrokeCount: self.presentation.drawingStrokes.count
                )
            }
            return self.jsonResponse(resp)
        }

        server.PUT["/presenter/tool"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: SetPresenterToolRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body. Expected {\"tool\": \"none|pointer|spotlight|drawing\"}")
            }
            let valid = ["none", "pointer", "spotlight", "drawing"]
            guard valid.contains(body.tool) else {
                return self.jsonError("Unknown tool '\(body.tool)'. Valid: \(valid.joined(separator: ", "))")
            }
            self.onMain {
                self.presentation.setPresenterTool(body.tool)
            }
            let resp = self.onMain {
                PresenterToolResponse(
                    activeTool: self.presentation.activeTool,
                    available: valid,
                    drawingStrokeCount: self.presentation.drawingStrokes.count
                )
            }
            return self.jsonResponse(resp)
        }

        server.POST["/presenter/clear-drawings"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            self.onMain { self.presentation.clearDrawings() }
            return self.jsonResponse(SuccessResponse(success: true, message: "Drawings cleared"))
        }

        // MARK: - Timer

        server.GET["/timer"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                TimerResponse(
                    running: self.presentation.isTimerRunning,
                    elapsedSeconds: self.presentation.elapsedSeconds,
                    wallClock: self.presentation.wallClock
                )
            }
            return self.jsonResponse(resp)
        }

        server.POST["/timer/start"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            self.onMain { self.presentation.startTimer() }
            let resp = self.onMain {
                TimerResponse(
                    running: self.presentation.isTimerRunning,
                    elapsedSeconds: self.presentation.elapsedSeconds,
                    wallClock: self.presentation.wallClock
                )
            }
            return self.jsonResponse(resp)
        }

        server.POST["/timer/stop"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            self.onMain { self.presentation.stopTimer() }
            let resp = self.onMain {
                TimerResponse(
                    running: self.presentation.isTimerRunning,
                    elapsedSeconds: self.presentation.elapsedSeconds,
                    wallClock: self.presentation.wallClock
                )
            }
            return self.jsonResponse(resp)
        }

        server.POST["/undo"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let result = self.onMain { () -> UndoRedoResponse in
                if self.presentation.undoEdit() {
                    return UndoRedoResponse(success: true, content: self.presentation.markdown)
                }
                return UndoRedoResponse(success: false, content: nil)
            }
            return self.jsonResponse(result)
        }

        server.POST["/redo"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let result = self.onMain { () -> UndoRedoResponse in
                if self.presentation.redoEdit() {
                    return UndoRedoResponse(success: true, content: self.presentation.markdown)
                }
                return UndoRedoResponse(success: false, content: nil)
            }
            return self.jsonResponse(result)
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

        server.GET["/export/html"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let result = self.onMain { () -> ExportHTMLResponse? in
                let slides = self.presentation.slides
                guard !slides.isEmpty else { return nil }
                let html = HTMLExportService.exportHTML(
                    metadata: self.presentation.metadata,
                    slides: slides,
                    theme: self.presentation.resolvedTheme
                )
                return ExportHTMLResponse(html: html, slideCount: slides.count)
            }
            guard let result else { return self.jsonError("Failed to export HTML") }
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
                let snippet = "![\(alt)](\(relativePath)#w=400&x=280&y=170)"
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

        // MARK: - Font

        server.GET["/font"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                FontResponse(
                    current: self.presentation.metadata.font,
                    available: CiceroFonts.curated
                )
            }
            return self.jsonResponse(resp)
        }

        server.PUT["/font"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let body: SetFontRequest? = self.decodeBody(request)
            self.onMain {
                self.presentation.setFont(body?.name)
            }
            let resp = self.onMain {
                FontResponse(
                    current: self.presentation.metadata.font,
                    available: CiceroFonts.curated
                )
            }
            return self.jsonResponse(resp)
        }

        // MARK: - Transition

        server.GET["/transition"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                TransitionResponse(
                    current: (self.presentation.metadata.transition ?? .none).rawValue,
                    available: PresentationTransition.allCases.map(\.rawValue)
                )
            }
            return self.jsonResponse(resp)
        }

        server.PUT["/transition"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: SetTransitionRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body. Expected {\"name\": \"fade|slide|push|none\"}")
            }
            guard let transition = PresentationTransition(rawValue: body.name) else {
                let valid = PresentationTransition.allCases.map(\.rawValue).joined(separator: ", ")
                return self.jsonError("Unknown transition '\(body.name)'. Valid: \(valid)")
            }
            self.onMain {
                self.presentation.metadata.transition = transition
                // Rebuild markdown to persist transition in frontmatter
                let markdown = SlideParser.serialize(metadata: self.presentation.metadata, slides: self.presentation.slides)
                self.presentation.markdown = markdown
                self.presentation.isDirty = true
            }
            let resp = self.onMain {
                TransitionResponse(
                    current: (self.presentation.metadata.transition ?? .none).rawValue,
                    available: PresentationTransition.allCases.map(\.rawValue)
                )
            }
            return self.jsonResponse(resp)
        }

        // MARK: - Metadata

        server.PUT["/metadata"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: SetMetadataRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body")
            }
            // Validate provided fields up-front so we don't half-apply.
            if let theme = body.theme, !MetadataValidator.isValidTheme(theme) {
                let valid = ThemeRegistry.builtIn.map(\.name) + ["auto", "custom"]
                return self.jsonError("Unknown theme '\(theme)'. Valid: \(valid.joined(separator: ", "))", status: 400)
            }
            if let font = body.font, !font.isEmpty, !MetadataValidator.isValidFont(font) {
                return self.jsonError("Unknown font '\(font)'. Valid: \(CiceroFonts.curated.joined(separator: ", "))", status: 400)
            }
            var transitionEnum: PresentationTransition? = nil
            if let t = body.transition {
                guard let parsed = PresentationTransition(rawValue: t) else {
                    let valid = PresentationTransition.allCases.map(\.rawValue).joined(separator: ", ")
                    return self.jsonError("Unknown transition '\(t)'. Valid: \(valid)", status: 400)
                }
                transitionEnum = parsed
            }
            self.onMain {
                self.presentation.updateMetadata(
                    title: body.title,
                    author: body.author,
                    theme: body.theme,
                    font: body.font,
                    transition: transitionEnum
                )
            }
            let resp = self.onMain {
                MetadataResponse(
                    title: self.presentation.metadata.title,
                    author: self.presentation.metadata.author,
                    theme: self.presentation.metadata.theme,
                    font: self.presentation.metadata.font,
                    transition: (self.presentation.metadata.transition ?? .none).rawValue
                )
            }
            return self.jsonResponse(resp)
        }

        // MARK: - Save

        server.POST["/save_as"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard let body: SaveAsRequest = self.decodeBody(request) else {
                return self.jsonError("Invalid request body. Expected {\"path\": \"/abs/path.md\"}")
            }
            switch SaveAsPathValidator.validate(body.path) {
            case .valid:
                break
            case .empty:
                return self.jsonError("Path is empty")
            case .notAbsolute:
                return self.jsonError("Path must be absolute (start with '/')")
            case .parentNotCreatable(let reason):
                return self.jsonError(reason)
            }
            do {
                let savedPath = try self.onMain { () -> String in
                    let url = URL(fileURLWithPath: body.path)
                    try self.presentation.saveAs(url: url)
                    return url.path
                }
                return self.jsonResponse(SaveResponse(success: true, filePath: savedPath))
            } catch {
                return self.jsonError("Failed to save: \(error.localizedDescription)")
            }
        }

        server.POST["/save"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            do {
                let filePath = try self.onMain { () -> String? in
                    try self.presentation.save()
                    return self.presentation.filePath?.path
                }
                return self.jsonResponse(SaveResponse(success: true, filePath: filePath))
            } catch {
                return self.jsonError("Failed to save: \(error.localizedDescription)")
            }
        }

        // MARK: - Raw Markdown

        server.GET["/markdown"] = { [weak self] _ in
            guard let self else { return .internalServerError }
            let resp = self.onMain {
                GetMarkdownResponse(
                    markdown: self.presentation.markdown,
                    filePath: self.presentation.filePath?.path,
                    isDirty: self.presentation.isDirty
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

    private func handleSlideURLUpdate(request: HttpRequest, key: String) -> HttpResponse {
        guard let index = self.pathInt(request, ":index") else {
            return self.jsonError("Invalid slide index")
        }
        let body: SetSlideURLRequest? = self.decodeBody(request)
        return self.onMain {
            guard index >= 0 && index < self.presentation.slides.count else {
                return self.jsonError("Slide index out of range", status: 404)
            }
            let oldContent = self.presentation.slides[index].content
            let newContent = SlideParser.setSlideMetadataField(oldContent, key: key, value: body?.url)
            self.presentation.updateSlide(at: index, content: newContent)
            let slide = self.presentation.slides[index]
            return self.jsonResponse(SlideInfo(
                index: index,
                title: slide.title,
                content: slide.content,
                layout: slide.layout == .default ? nil : slide.layout.rawValue,
                imageURL: slide.imageURL,
                videoURL: slide.videoURL,
                embedURL: slide.embedURL,
                notes: slide.notes
            ))
        }
    }

    private func renderScreenshot(index: Int?, savePath: String? = nil) -> HttpResponse {
        let result = onMain { () -> (ScreenshotResponse, Data)? in
            let slideIndex = index ?? self.presentation.currentIndex
            guard slideIndex >= 0 && slideIndex < self.presentation.slides.count else { return nil }
            let slide = self.presentation.slides[slideIndex]
            guard let pngData = self.screenshotService.renderSlideSync(slide) else { return nil }
            let resp = ScreenshotResponse(
                base64PNG: pngData.base64EncodedString(),
                slideIndex: slideIndex
            )
            return (resp, pngData)
        }
        guard let result else { return jsonError("Failed to render screenshot") }
        if let savePath, !savePath.isEmpty {
            let url = URL(fileURLWithPath: savePath)
            try? result.1.write(to: url)
        }
        return jsonResponse(result.0)
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
    static let toggleSidebar = Notification.Name("cicero.toggleSidebar")
    static let toggleNotes = Notification.Name("cicero.toggleNotes")
}
