import Testing
import Foundation
@testable import Shared

@Suite("ImageSizing")
struct ImageSizingTests {

    @Test("Image without explicit width should not exceed its natural size")
    func imageWithoutExplicitWidth() {
        let width = ImageSizing.constrainedWidth(explicitWidth: nil, naturalWidth: 200)
        #expect(
            width <= 200,
            "Expected max width ≤ 200 (natural size), got \(width)"
        )
    }

    @Test("Large image without explicit width caps at maxAllowedWidth")
    func largeImageCapsAtMax() {
        let width = ImageSizing.constrainedWidth(explicitWidth: nil, naturalWidth: 3000)
        #expect(
            width == ImageSizing.maxAllowedWidth,
            "Expected \(ImageSizing.maxAllowedWidth), got \(width)"
        )
    }

    @Test("Explicit width is preserved when within allowed range")
    func explicitWidthPreserved() {
        let width = ImageSizing.constrainedWidth(explicitWidth: 500, naturalWidth: 200)
        #expect(width == 500)
    }

    @Test("Explicit width below minimum is clamped")
    func explicitWidthBelowMin() {
        let width = ImageSizing.constrainedWidth(explicitWidth: 50, naturalWidth: 200)
        #expect(width == ImageSizing.minAllowedWidth)
    }

    @Test("Explicit width above maximum is clamped")
    func explicitWidthAboveMax() {
        let width = ImageSizing.constrainedWidth(explicitWidth: 2000, naturalWidth: 500)
        #expect(width == ImageSizing.maxAllowedWidth)
    }
}

@Suite("PositionedImageParser")
struct PositionedImageParserTests {

    @Test("Parses positioned image with all three fragment values")
    func parsesAllThreeValues() {
        let body = "Hello\n\n![logo](assets/a.png#w=400&x=280&y=170)\n\nworld"
        let refs = PositionedImageParser.parse(body)
        #expect(refs.count == 1)
        #expect(refs[0].url == "assets/a.png")
        #expect(refs[0].width == 400)
        #expect(refs[0].x == 280)
        #expect(refs[0].y == 170)
        #expect(refs[0].alt == "logo")
    }

    @Test("Image without x/y is not considered positioned")
    func skipsInlineImages() {
        let body = "![inline](assets/a.png)\n\n![sized](assets/b.png#w=400)"
        let refs = PositionedImageParser.parse(body)
        #expect(refs.isEmpty)
    }

    @Test("Multiple positioned images on one slide")
    func multipleImages() {
        let body = """
        ![a](a.png#w=200&x=10&y=20)
        ![b](b.png#w=300&x=100&y=200)
        """
        let refs = PositionedImageParser.parse(body)
        #expect(refs.count == 2)
        #expect(refs[0].url == "a.png")
        #expect(refs[1].url == "b.png")
    }

    @Test("Width defaults to 400 when omitted but x and y are present")
    func defaultsWidth() {
        let body = "![a](a.png#x=100&y=50)"
        let refs = PositionedImageParser.parse(body)
        #expect(refs.count == 1)
        #expect(refs[0].width == 400)
    }

    @Test("parseFragment extracts the path without fragment")
    func parseFragmentPath() {
        let parsed = PositionedImageParser.parseFragment("assets/a.png#w=400&x=10&y=20")
        #expect(parsed?.path == "assets/a.png")
        #expect(parsed?.width == 400)
        #expect(parsed?.x == 10)
        #expect(parsed?.y == 20)
    }

    @Test("parseFragment returns path only when no fragment")
    func parseFragmentNoFragment() {
        let parsed = PositionedImageParser.parseFragment("assets/a.png")
        #expect(parsed?.path == "assets/a.png")
        #expect(parsed?.width == nil)
        #expect(parsed?.x == nil)
        #expect(parsed?.y == nil)
    }
}
