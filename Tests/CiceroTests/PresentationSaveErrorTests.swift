import Foundation
import Testing
@testable import Shared

@Suite("PresentationSaveError")
struct PresentationSaveErrorTests {

    @Test("noFilePath has a user-facing description that mentions save_as")
    func noFilePathDescription() {
        let err: PresentationSaveError = .noFilePath
        let message = err.errorDescription ?? ""
        #expect(message.contains("save_as"),
                "Description should tell the caller how to recover")
    }

    @Test("noFilePath equals itself")
    func equality() {
        #expect(PresentationSaveError.noFilePath == PresentationSaveError.noFilePath)
    }

    @Test("externalConflict mentions the path and the recovery action")
    func externalConflictDescription() {
        let err: PresentationSaveError = .externalConflict(path: "/tmp/deck.md")
        let message = err.errorDescription ?? ""
        #expect(message.contains("/tmp/deck.md"))
        #expect(message.contains("force"))
    }

    @Test("externalConflict equality compares the path")
    func externalConflictEquality() {
        #expect(PresentationSaveError.externalConflict(path: "/a") == PresentationSaveError.externalConflict(path: "/a"))
        #expect(PresentationSaveError.externalConflict(path: "/a") != PresentationSaveError.externalConflict(path: "/b"))
    }
}
