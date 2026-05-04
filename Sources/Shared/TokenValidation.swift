import Foundation

/// Outcome of validating a stored GitHub token against `GET /user`.
/// Lives in `Shared` so the auth classifier policy is testable from the
/// unit-test target without depending on the Cicero app target.
public enum TokenValidationOutcome: Equatable, Sendable {
    /// Token is valid; the username was retrieved.
    case valid(username: String)
    /// GitHub explicitly rejected the token (401/403). The caller should
    /// drop the token from memory and delete the on-disk copy.
    case unauthorized
    /// Some other failure (5xx, transport, parse). The caller should
    /// keep the token — a transient network blip shouldn't sign the
    /// user out — and just leave the username unset.
    case transient
}

/// Pure classifier: given the HTTP status code returned by GitHub's
/// `/user` endpoint and an optional decoded username, choose the
/// outcome the caller should act on. 200 with a username is `.valid`;
/// 401 or 403 is `.unauthorized`; everything else is `.transient`.
public enum TokenValidationClassifier {

    public static func classify(statusCode: Int, username: String?) -> TokenValidationOutcome {
        switch statusCode {
        case 200:
            if let username, !username.isEmpty {
                return .valid(username: username)
            }
            return .transient
        case 401, 403:
            return .unauthorized
        default:
            return .transient
        }
    }
}
