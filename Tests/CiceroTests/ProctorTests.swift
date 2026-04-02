import Testing
import Foundation
@testable import Shared

@Suite("PresentationValidator")
struct ProctorTests {

    private func writeTempFile(_ content: String) throws -> String {
        let dir = FileManager.default.temporaryDirectory
        let file = dir.appendingPathComponent("proctor-test-\(UUID().uuidString).md")
        try content.write(to: file, atomically: true, encoding: .utf8)
        return file.path
    }

    @Test("Valid presentation has no errors")
    func testValidateValidPresentation() throws {
        let md = """
        ---
        title: Test
        theme: auto
        font: Helvetica
        ---

        # Hello World
        """
        let path = try writeTempFile(md)
        let errors = PresentationValidator.validate(at: path)
        #expect(errors.isEmpty)
    }

    @Test("Invalid font reports error")
    func testValidateInvalidFont() throws {
        let md = """
        ---
        font: FakeFont123
        ---

        # Hello
        """
        let path = try writeTempFile(md)
        let errors = PresentationValidator.validate(at: path)
        #expect(!errors.isEmpty)
        #expect(errors.first?.message.contains("not available") == true)
    }

    @Test("Invalid hex color reports error")
    func testValidateInvalidHexColor() throws {
        let md = """
        ---
        theme: custom
        theme_background: notahex
        ---

        # Hello
        """
        let path = try writeTempFile(md)
        let errors = PresentationValidator.validate(at: path)
        #expect(errors.contains { $0.message.contains("Invalid hex color") })
    }

    @Test("Invalid layout value reports error")
    func testValidateInvalidLayout() throws {
        let md = """
        # Before

        ---

        layout: nonexistent
        # Slide
        """
        let path = try writeTempFile(md)
        let errors = PresentationValidator.validate(at: path)
        #expect(errors.contains { $0.message.contains("Unknown layout") })
    }

    @Test("Missing file reports error")
    func testValidateMissingFile() {
        let errors = PresentationValidator.validate(at: "/tmp/nonexistent-\(UUID().uuidString).md")
        #expect(!errors.isEmpty)
        #expect(errors.first?.message.contains("File not found") == true)
    }
}
