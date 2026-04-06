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
}
