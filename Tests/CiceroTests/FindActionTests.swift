import Testing
@testable import Shared

/// `FindAction` describes the entries Cicero adds to the Edit ▸ Find submenu.
/// The tag values must match `NSTextFinder.Action` raw values so that
/// `performTextFinderAction(_:)` routes to the correct behavior on the
/// focused text view (the editor's NSTextView).
@Suite("FindAction")
struct FindActionTests {

    @Test("All four menu entries are present and ordered")
    func allCasesOrder() {
        #expect(FindAction.allCases == [.find, .findNext, .findPrevious, .findAndReplace])
    }

    @Test("Find — ⌘F, tag matches NSTextFinder.Action.showFindInterface")
    func findShortcut() {
        #expect(FindAction.find.title == "Find…")
        #expect(FindAction.find.key == "f")
        #expect(FindAction.find.requiresShift == false)
        #expect(FindAction.find.requiresOption == false)
        #expect(FindAction.find.tag == 1)
    }

    @Test("Find Next — ⌘G, tag matches NSTextFinder.Action.nextMatch")
    func findNextShortcut() {
        #expect(FindAction.findNext.title == "Find Next")
        #expect(FindAction.findNext.key == "g")
        #expect(FindAction.findNext.requiresShift == false)
        #expect(FindAction.findNext.requiresOption == false)
        #expect(FindAction.findNext.tag == 2)
    }

    @Test("Find Previous — ⇧⌘G, tag matches NSTextFinder.Action.previousMatch")
    func findPreviousShortcut() {
        #expect(FindAction.findPrevious.title == "Find Previous")
        #expect(FindAction.findPrevious.key == "g")
        #expect(FindAction.findPrevious.requiresShift == true)
        #expect(FindAction.findPrevious.requiresOption == false)
        #expect(FindAction.findPrevious.tag == 3)
    }

    @Test("Find and Replace — ⌥⌘F, tag matches NSTextFinder.Action.showReplaceInterface")
    func findAndReplaceShortcut() {
        #expect(FindAction.findAndReplace.title == "Find and Replace…")
        #expect(FindAction.findAndReplace.key == "f")
        #expect(FindAction.findAndReplace.requiresShift == false)
        #expect(FindAction.findAndReplace.requiresOption == true)
        #expect(FindAction.findAndReplace.tag == 12)
    }
}
