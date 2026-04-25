import Testing
import Foundation
@testable import Shared

@Suite("API Models")
struct APIModelTests {

    @Test("StatusResponse encodes theme field")
    func statusResponseTheme() throws {
        let resp = StatusResponse(
            currentSlide: 0, totalSlides: 5, presenting: false,
            filePath: nil, title: "Test", theme: "ocean"
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
        #expect(decoded.theme == "ocean")
    }

    @Test("StatusResponse backward compat without theme")
    func statusResponseNoTheme() throws {
        let resp = StatusResponse(
            currentSlide: 0, totalSlides: 3, presenting: true,
            filePath: "/test.md", title: "T"
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
        #expect(decoded.theme == nil)
    }

    @Test("ThemeListResponse encoding")
    func themeListResponse() throws {
        let resp = ThemeListResponse(themes: [ThemeRegistry.dark, ThemeRegistry.light])
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(ThemeListResponse.self, from: data)
        #expect(decoded.themes.count == 2)
        #expect(decoded.themes[0].name == "dark")
    }

    @Test("ThemeResponse encoding")
    func themeResponse() throws {
        let resp = ThemeResponse(current: "ocean", definition: ThemeRegistry.ocean)
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(ThemeResponse.self, from: data)
        #expect(decoded.current == "ocean")
        #expect(decoded.definition?.name == "ocean")
    }

    @Test("SetThemeRequest encoding")
    func setThemeRequest() throws {
        let req = SetThemeRequest(name: "custom", background: "#000000", text: "#ffffff")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetThemeRequest.self, from: data)
        #expect(decoded.name == "custom")
        #expect(decoded.background == "#000000")
        #expect(decoded.text == "#ffffff")
        #expect(decoded.heading == nil)
    }

    @Test("SetThemeRequest with named theme only")
    func setThemeRequestNamed() throws {
        let req = SetThemeRequest(name: "dracula")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetThemeRequest.self, from: data)
        #expect(decoded.name == "dracula")
        #expect(decoded.background == nil)
    }

    @Test("SlideInfo with video and embed URLs")
    func slideInfoWithVideoEmbed() throws {
        let info = SlideInfo(
            index: 0,
            title: "Demo",
            content: "layout: video\nvideo: assets/demo.mp4\n# Demo",
            layout: "video",
            imageURL: nil,
            videoURL: "assets/demo.mp4",
            embedURL: nil
        )
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(SlideInfo.self, from: data)
        #expect(decoded.videoURL == "assets/demo.mp4")
        #expect(decoded.embedURL == nil)
        #expect(decoded.layout == "video")

        // Also test embed
        let embedInfo = SlideInfo(
            index: 1,
            title: "Web",
            content: "layout: embed\nembed: https://example.com",
            layout: "embed",
            imageURL: nil,
            videoURL: nil,
            embedURL: "https://example.com"
        )
        let embedData = try JSONEncoder().encode(embedInfo)
        let embedDecoded = try JSONDecoder().decode(SlideInfo.self, from: embedData)
        #expect(embedDecoded.embedURL == "https://example.com")
        #expect(embedDecoded.videoURL == nil)
    }

    // MARK: - Font Models

    @Test("FontResponse encodes/decodes with font name")
    func fontResponseWithName() throws {
        let resp = FontResponse(current: "Georgia", available: ["Georgia", "Helvetica", "Times New Roman"])
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(FontResponse.self, from: data)
        #expect(decoded.current == "Georgia")
        #expect(decoded.available.count == 3)
        #expect(decoded.available.contains("Helvetica"))
    }

    @Test("FontResponse encodes/decodes with nil current")
    func fontResponseNilCurrent() throws {
        let resp = FontResponse(current: nil, available: ["Arial", "Verdana"])
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(FontResponse.self, from: data)
        #expect(decoded.current == nil)
        #expect(decoded.available.count == 2)
    }

    @Test("SetFontRequest encodes/decodes with name")
    func setFontRequestWithName() throws {
        let req = SetFontRequest(name: "Menlo")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetFontRequest.self, from: data)
        #expect(decoded.name == "Menlo")
    }

    @Test("SetFontRequest encodes/decodes without name")
    func setFontRequestNoName() throws {
        let req = SetFontRequest()
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetFontRequest.self, from: data)
        #expect(decoded.name == nil)
    }

    // MARK: - Transition Models

    @Test("TransitionResponse encodes/decodes")
    func transitionResponse() throws {
        let resp = TransitionResponse(current: "fade", available: ["none", "fade", "slide", "push"])
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(TransitionResponse.self, from: data)
        #expect(decoded.current == "fade")
        #expect(decoded.available.count == 4)
        #expect(decoded.available.contains("none"))
        #expect(decoded.available.contains("slide"))
    }

    @Test("SetTransitionRequest encodes/decodes")
    func setTransitionRequest() throws {
        let req = SetTransitionRequest(name: "push")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetTransitionRequest.self, from: data)
        #expect(decoded.name == "push")
    }

    // MARK: - Save Model

    @Test("SaveResponse encodes/decodes success case")
    func saveResponseSuccess() throws {
        let resp = SaveResponse(success: true, filePath: "/tmp/presentation.md")
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(SaveResponse.self, from: data)
        #expect(decoded.success == true)
        #expect(decoded.filePath == "/tmp/presentation.md")
    }

    @Test("SaveResponse encodes/decodes failure case")
    func saveResponseFailure() throws {
        let resp = SaveResponse(success: false)
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(SaveResponse.self, from: data)
        #expect(decoded.success == false)
        #expect(decoded.filePath == nil)
    }

    @Test("SaveResponse outcome is .saved when success with path")
    func saveOutcomeSaved() {
        let resp = SaveResponse(success: true, filePath: "/tmp/deck.md")
        #expect(resp.outcome == .saved(path: "/tmp/deck.md"))
    }

    @Test("SaveResponse outcome is .noPath when success but path is nil")
    func saveOutcomeSuccessButNilPath() {
        // Today's behavior: presentation.save() with no filePath returns
        // success=true / filePath=nil. The MCP layer must surface this as
        // an error so agents don't think the deck got persisted.
        let resp = SaveResponse(success: true, filePath: nil)
        #expect(resp.outcome == .noPath)
    }

    @Test("SaveResponse outcome is .noPath when success but path is empty")
    func saveOutcomeSuccessButEmptyPath() {
        let resp = SaveResponse(success: true, filePath: "")
        #expect(resp.outcome == .noPath)
    }

    @Test("SaveResponse outcome is .noPath when success false")
    func saveOutcomeFailure() {
        let resp = SaveResponse(success: false, filePath: nil)
        #expect(resp.outcome == .noPath)
    }

    // MARK: - Export PDF Model

    @Test("ExportPDFResponse encodes/decodes round-trip")
    func exportPDFResponseRoundTrip() throws {
        let pdfBytes = Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34])
        let resp = ExportPDFResponse(
            base64PDF: pdfBytes.base64EncodedString(),
            pageCount: 3
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(ExportPDFResponse.self, from: data)
        #expect(decoded.pageCount == 3)
        // The MCP export_pdf handler decodes the base64 string back to bytes
        // and writes them to disk when output_path is set. Confirm the
        // round-trip is lossless so the on-disk bytes match the originals.
        let recovered = Data(base64Encoded: decoded.base64PDF)
        #expect(recovered == pdfBytes)
    }

    @Test("ExportPDFResponse rejects malformed base64")
    func exportPDFResponseBadBase64() {
        // The MCP handler must defend against an unexpected non-base64
        // payload by returning an error rather than crashing.
        let resp = ExportPDFResponse(base64PDF: "not base64!@#$", pageCount: 1)
        #expect(Data(base64Encoded: resp.base64PDF) == nil)
    }

    // MARK: - Markdown Model

    @Test("GetMarkdownResponse encodes/decodes with all fields")
    func getMarkdownResponse() throws {
        let resp = GetMarkdownResponse(
            markdown: "# Title\n\nContent here",
            filePath: "/tmp/deck.md",
            isDirty: true
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(GetMarkdownResponse.self, from: data)
        #expect(decoded.markdown == "# Title\n\nContent here")
        #expect(decoded.filePath == "/tmp/deck.md")
        #expect(decoded.isDirty == true)
    }

    @Test("GetMarkdownResponse defaults")
    func getMarkdownResponseDefaults() throws {
        let resp = GetMarkdownResponse(markdown: "# Slide")
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(GetMarkdownResponse.self, from: data)
        #expect(decoded.markdown == "# Slide")
        #expect(decoded.filePath == nil)
        #expect(decoded.isDirty == false)
    }

    // MARK: - StatusResponse with new fields

    @Test("StatusResponse with author, font, transition fields")
    func statusResponseAllFields() throws {
        let resp = StatusResponse(
            currentSlide: 2, totalSlides: 10, presenting: true,
            filePath: "/tmp/test.md", title: "My Deck",
            theme: "dark", author: "Test Author",
            font: "Georgia", transition: "fade"
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
        #expect(decoded.author == "Test Author")
        #expect(decoded.font == "Georgia")
        #expect(decoded.transition == "fade")
        #expect(decoded.theme == "dark")
    }

    @Test("StatusResponse backward compat: new fields nil when not provided")
    func statusResponseNewFieldsNil() throws {
        let resp = StatusResponse(
            currentSlide: 0, totalSlides: 1, presenting: false,
            filePath: nil, title: "Minimal"
        )
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
        #expect(decoded.author == nil)
        #expect(decoded.font == nil)
        #expect(decoded.transition == nil)
        #expect(decoded.theme == nil)
    }
}
