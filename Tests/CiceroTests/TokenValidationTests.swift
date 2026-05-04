import Foundation
import Testing
@testable import Shared

@Suite("TokenValidationClassifier")
struct TokenValidationTests {

    @Test("200 with username is valid")
    func okWithUsername() {
        #expect(TokenValidationClassifier.classify(statusCode: 200, username: "alice") == .valid(username: "alice"))
    }

    @Test("200 with nil username is transient (don't sign out)")
    func okWithoutUsername() {
        // GitHub never returns 200 without a login, but if our parse fails
        // we shouldn't punish the user — keep the token, retry later.
        #expect(TokenValidationClassifier.classify(statusCode: 200, username: nil) == .transient)
    }

    @Test("200 with empty username is transient")
    func okWithEmptyUsername() {
        #expect(TokenValidationClassifier.classify(statusCode: 200, username: "") == .transient)
    }

    @Test("401 is unauthorized — caller must clear token")
    func unauthorized401() {
        #expect(TokenValidationClassifier.classify(statusCode: 401, username: nil) == .unauthorized)
    }

    @Test("403 is unauthorized — caller must clear token")
    func unauthorized403() {
        #expect(TokenValidationClassifier.classify(statusCode: 403, username: nil) == .unauthorized)
    }

    @Test("500 is transient — token survives")
    func transient500() {
        #expect(TokenValidationClassifier.classify(statusCode: 500, username: nil) == .transient)
    }

    @Test("404 is transient (unexpected, not an auth verdict)")
    func transient404() {
        #expect(TokenValidationClassifier.classify(statusCode: 404, username: nil) == .transient)
    }
}
