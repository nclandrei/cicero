import Foundation
import Testing
@testable import Shared

@Suite("CloseRequest / ClosePolicy")
struct CloseRequestTests {

    // MARK: - decoding

    @Test("Decodes empty body as force == nil")
    func decodesEmptyObject() throws {
        let req = try JSONDecoder().decode(CloseRequest.self, from: Data("{}".utf8))
        #expect(req.force == nil)
    }

    @Test("Decodes explicit force flag")
    func decodesForceTrue() throws {
        let req = try JSONDecoder().decode(CloseRequest.self, from: Data(#"{"force":true}"#.utf8))
        #expect(req.force == true)
    }

    @Test("Decodes explicit force=false")
    func decodesForceFalse() throws {
        let req = try JSONDecoder().decode(CloseRequest.self, from: Data(#"{"force":false}"#.utf8))
        #expect(req.force == false)
    }

    // MARK: - policy

    @Test("Clean buffer — never rejected")
    func cleanBufferAlwaysAllowed() {
        #expect(ClosePolicy.shouldReject(isDirty: false, force: nil) == false)
        #expect(ClosePolicy.shouldReject(isDirty: false, force: false) == false)
        #expect(ClosePolicy.shouldReject(isDirty: false, force: true) == false)
    }

    @Test("Dirty buffer without force — rejected")
    func dirtyWithoutForceRejected() {
        #expect(ClosePolicy.shouldReject(isDirty: true, force: nil) == true)
        #expect(ClosePolicy.shouldReject(isDirty: true, force: false) == true)
    }

    @Test("Dirty buffer with force=true — allowed")
    func dirtyWithForceAllowed() {
        #expect(ClosePolicy.shouldReject(isDirty: true, force: true) == false)
    }
}
