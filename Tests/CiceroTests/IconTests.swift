import AppKit
import Testing

@Suite("AppIcon")
struct IconTests {

    /// macOS icons must have ~10% transparent margin on each side so they appear
    /// the same size as other dock icons. Apple's grid places the squircle content
    /// at ~824×824 inside a 1024×1024 canvas ⇒ each margin ≥ 5%.
    @Test("Icon has sufficient transparent margins for macOS dock")
    func iconHasProperMargins() throws {
        let url = try #require(Bundle.module.url(forResource: "AppIcon", withExtension: "icns"))
        let image = try #require(NSImage(contentsOf: url))

        // Get the largest representation (should be 1024x1024)
        let targetSize = NSSize(width: 1024, height: 1024)
        image.size = targetSize

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1024,
            pixelsHigh: 1024,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: targetSize))
        NSGraphicsContext.restoreGraphicsState()

        let width = rep.pixelsWide
        let height = rep.pixelsHigh

        // Find bounding box of non-transparent content
        var minX = width, minY = height, maxX = 0, maxY = 0
        let step = 2
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                guard let color = rep.colorAt(x: x, y: y) else { continue }
                var a: CGFloat = 0
                color.getRed(nil, green: nil, blue: nil, alpha: &a)
                if a > 0.01 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        let leftMargin = Double(minX) / Double(width) * 100
        let topMargin = Double(minY) / Double(height) * 100
        let rightMargin = Double(width - 1 - maxX) / Double(width) * 100
        let bottomMargin = Double(height - 1 - maxY) / Double(height) * 100

        // Apple's icon grid: content ≈ 824/1024 ≈ 80.5%, margin ≈ 9.8% each side.
        // We require at least 5% margin on every side as a reasonable minimum.
        let minimumMarginPercent = 5.0

        #expect(leftMargin >= minimumMarginPercent,
                "Left margin is \(String(format: "%.1f", leftMargin))%, need ≥\(minimumMarginPercent)%")
        #expect(topMargin >= minimumMarginPercent,
                "Top margin is \(String(format: "%.1f", topMargin))%, need ≥\(minimumMarginPercent)%")
        #expect(rightMargin >= minimumMarginPercent,
                "Right margin is \(String(format: "%.1f", rightMargin))%, need ≥\(minimumMarginPercent)%")
        #expect(bottomMargin >= minimumMarginPercent,
                "Bottom margin is \(String(format: "%.1f", bottomMargin))%, need ≥\(minimumMarginPercent)%")
    }
}
