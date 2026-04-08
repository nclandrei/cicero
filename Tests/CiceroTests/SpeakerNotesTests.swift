import Foundation
import Testing
@testable import Shared

@Suite("Speaker Notes — updateNotes logic")
struct SpeakerNotesTests {

    /// Simulates what Presentation.updateNotes does: strips existing notes block
    /// and optionally appends a new one.
    private func applyNotes(to content: String, notes: String?) -> String {
        let (bodyWithoutNotes, _) = SlideParser.extractNotes(content)
        var newContent = bodyWithoutNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newContent += "\n\n<!-- notes\n\(notes)\n-->"
        }
        return newContent
    }

    @Test("Insert notes into slide without existing notes")
    func insertNotes() {
        let content = "# Slide 1\n\nContent"
        let updated = applyNotes(to: content, notes: "Remember this point")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.notes == "Remember this point")
        #expect(slide.content.contains("<!-- notes"))
        #expect(slide.content.contains("Remember this point"))
        // Body should not contain notes block
        #expect(!slide.body.contains("<!-- notes"))
    }

    @Test("Update existing notes")
    func updateExistingNotes() {
        let content = "# Slide 1\n\nContent\n\n<!-- notes\nOld notes\n-->"
        let original = Slide(id: 0, content: content)
        #expect(original.notes == "Old notes")

        let updated = applyNotes(to: content, notes: "New notes")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.notes == "New notes")
        // Should not have double notes blocks
        let occurrences = slide.content.components(separatedBy: "<!-- notes").count - 1
        #expect(occurrences == 1)
    }

    @Test("Nil notes removes notes block")
    func removeNotes() {
        let content = "# Slide 1\n\nContent\n\n<!-- notes\nSome notes\n-->"
        let original = Slide(id: 0, content: content)
        #expect(original.notes == "Some notes")

        let updated = applyNotes(to: content, notes: nil)
        let slide = Slide(id: 0, content: updated)
        #expect(slide.notes == nil)
        #expect(!slide.content.contains("<!-- notes"))
        #expect(!slide.content.contains("-->"))
        #expect(slide.body.contains("Content"))
    }

    @Test("Notes for specific slide via parsing")
    func notesForSlide() {
        let md = "# Slide 1\n\n<!-- notes\nFirst notes\n-->\n\n---\n\n# Slide 2"
        let (_, slides) = SlideParser.parse(md)
        #expect(slides[0].notes == "First notes")
        #expect(slides[1].notes == nil)
    }

    @Test("Notes round-trip through updateNotes and serialize/parse")
    func roundTrip() {
        let md = "# Slide 1\n\n---\n\n# Slide 2"
        let (meta, slides) = SlideParser.parse(md)
        #expect(slides.count == 2)

        // Apply notes to both slides
        let updated0 = applyNotes(to: slides[0].content, notes: "Notes for slide 1")
        let updated1 = applyNotes(to: slides[1].content, notes: "Notes for slide 2")
        let newSlides = [
            Slide(id: 0, content: updated0),
            Slide(id: 1, content: updated1),
        ]

        // Serialize and re-parse
        let serialized = SlideParser.serialize(metadata: meta, slides: newSlides)
        let (_, reparsed) = SlideParser.parse(serialized)
        #expect(reparsed.count == 2)
        #expect(reparsed[0].notes == "Notes for slide 1")
        #expect(reparsed[1].notes == "Notes for slide 2")
        // Bodies should not contain notes
        #expect(!reparsed[0].body.contains("<!-- notes"))
        #expect(!reparsed[1].body.contains("<!-- notes"))
    }

    @Test("Empty string removes notes block")
    func emptyStringRemovesNotes() {
        let content = "# Slide 1\n\n<!-- notes\nSome notes\n-->"
        let updated = applyNotes(to: content, notes: "")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.notes == nil)
        #expect(!slide.content.contains("<!-- notes"))
    }

    @Test("Notes preserve slide frontmatter")
    func preservesFrontmatter() {
        let content = "layout: title\n# Big Title"
        let updated = applyNotes(to: content, notes: "Title slide notes")
        let slide = Slide(id: 0, content: updated)
        #expect(slide.layout == .title)
        #expect(slide.notes == "Title slide notes")
        #expect(slide.body == "# Big Title")
    }

    @Test("Get notes via API model")
    func getNotesModel() {
        let resp = NotesResponse(index: 0, notes: "My notes")
        #expect(resp.index == 0)
        #expect(resp.notes == "My notes")
    }

    @Test("Get notes nil via API model")
    func getNotesNilModel() {
        let resp = NotesResponse(index: 2, notes: nil)
        #expect(resp.index == 2)
        #expect(resp.notes == nil)
    }

    @Test("SetNotesRequest encodes correctly")
    func setNotesRequestEncoding() throws {
        let req = SetNotesRequest(notes: "Test notes")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetNotesRequest.self, from: data)
        #expect(decoded.notes == "Test notes")
    }

    @Test("SetNotesRequest with nil notes encodes correctly")
    func setNotesRequestNilEncoding() throws {
        let req = SetNotesRequest(notes: nil)
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SetNotesRequest.self, from: data)
        #expect(decoded.notes == nil)
    }

    @Test("Notes survive set_slide content update")
    func notesSurviveContentUpdate() {
        // Simulating: set notes, then update slide content to verify notes format
        let content = "# Title\n\nBody text"
        let withNotes = applyNotes(to: content, notes: "Important point")
        let slide = Slide(id: 0, content: withNotes)

        // Now update the same slide with different body but same notes
        let newBody = "# New Title\n\nNew body"
        let updated = applyNotes(to: newBody, notes: slide.notes)
        let updatedSlide = Slide(id: 0, content: updated)
        #expect(updatedSlide.notes == "Important point")
        #expect(updatedSlide.body.contains("New Title"))
    }

    @Test("Multi-line notes preserved through round-trip")
    func multiLineNotesRoundTrip() {
        let notes = "Line 1\nLine 2\nLine 3"
        let content = "# Slide\n\n<!-- notes\n\(notes)\n-->"
        let slide = Slide(id: 0, content: content)
        #expect(slide.notes == notes)

        let (meta, slides) = SlideParser.parse(content)
        let serialized = SlideParser.serialize(metadata: meta, slides: slides)
        let (_, reparsed) = SlideParser.parse(serialized)
        #expect(reparsed[0].notes == notes)
    }
}
