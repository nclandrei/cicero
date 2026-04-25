import Testing
import Foundation
@testable import Shared

@Suite("Image API models")
struct ImageAPIModelTests {

    @Test("ImageListItem encodes snake_case size_bytes")
    func itemEncoding() throws {
        let item = ImageListItem(id: "img.png", filename: "img.png", sizeBytes: 1234)
        let data = try JSONEncoder().encode(item)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"size_bytes\":1234"))
        #expect(json.contains("\"id\":\"img.png\""))
    }

    @Test("ImageListResponse round-trips")
    func responseRoundTrip() throws {
        let resp = ImageListResponse(images: [
            ImageListItem(id: "a.png", filename: "a.png", sizeBytes: 1),
            ImageListItem(id: "b.jpg", filename: "b.jpg", sizeBytes: 2),
        ])
        let data = try JSONEncoder().encode(resp)
        let decoded = try JSONDecoder().decode(ImageListResponse.self, from: data)
        #expect(decoded.images.count == 2)
        #expect(decoded.images[0].id == "a.png")
        #expect(decoded.images[1].sizeBytes == 2)
    }

    @Test("ImageListItem decodes from snake_case JSON")
    func itemDecoding() throws {
        let json = #"{"id":"x.png","filename":"x.png","size_bytes":42}"#
        let item = try JSONDecoder().decode(ImageListItem.self, from: Data(json.utf8))
        #expect(item.id == "x.png")
        #expect(item.sizeBytes == 42)
    }
}
