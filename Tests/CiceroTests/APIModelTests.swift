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
}
