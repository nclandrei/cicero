import AppKit
import Shared

final class PDFExportService {
    private let screenshotService: ScreenshotService

    init(screenshotService: ScreenshotService) {
        self.screenshotService = screenshotService
    }

    /// Renders all slides into a multi-page PDF. Must be called on the main thread.
    func exportPDF(slides: [Slide]) -> Data? {
        MainActor.assumeIsolated {
            renderPDF(slides: slides)
        }
    }

    @MainActor
    private func renderPDF(slides: [Slide]) -> Data? {
        let pageSize = CGSize(width: 1920, height: 1080)
        let mediaBox = CGRect(origin: .zero, size: pageSize)

        let data = NSMutableData()
        var box = mediaBox
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil)
        else {
            return nil
        }

        for slide in slides {
            guard let pngData = screenshotService.renderSlideSync(slide, size: pageSize),
                  let imageSource = CGImageSourceCreateWithData(pngData as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
            else {
                continue
            }

            var box = mediaBox
            context.beginPage(mediaBox: &box)
            context.draw(cgImage, in: mediaBox)
            context.endPage()
        }

        context.closePDF()
        return data as Data
    }
}
