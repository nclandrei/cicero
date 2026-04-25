import Testing
import Foundation
@testable import Shared

@Suite("save_as path validation")
struct SaveAsPathTests {

    @Test("Empty path is invalid")
    func emptyPath() {
        #expect(SaveAsPathValidator.validate("") == .empty)
    }

    @Test("Relative path is invalid")
    func relativePath() {
        #expect(SaveAsPathValidator.validate("foo.md") == .notAbsolute)
    }

    @Test("Absolute path with existing parent dir is valid")
    func validAbsolutePath() {
        let tempDir = NSTemporaryDirectory()
        let path = (tempDir as NSString).appendingPathComponent("save-as-test-\(UUID().uuidString).md")
        #expect(SaveAsPathValidator.validate(path) == .valid)
    }

    @Test("Absolute path with nonexistent but creatable parent dir is valid")
    func nonexistentParentValid() {
        let tempDir = NSTemporaryDirectory()
        let nestedPath = (tempDir as NSString).appendingPathComponent("save-as-\(UUID().uuidString)/sub/deck.md")
        #expect(SaveAsPathValidator.validate(nestedPath) == .valid)
    }

    @Test("Absolute path under non-creatable root is invalid")
    func invalidPath() {
        // /System/Library is read-only, sub-paths are not creatable.
        let bogus = "/System/Library/CiceroSaveAsTest-\(UUID().uuidString)/deck.md"
        let result = SaveAsPathValidator.validate(bogus)
        if case .parentNotCreatable = result {
            // expected
        } else {
            Issue.record("Expected parentNotCreatable, got \(result)")
        }
    }
}
