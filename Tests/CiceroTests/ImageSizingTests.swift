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
