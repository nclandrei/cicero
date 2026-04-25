import Foundation

/// How a Markdown code fence's content should be styled.
///
/// Splash (the syntax highlighter we use) only understands Swift, so any other
/// language hint must be rendered as plain styled text. An absent or empty
/// language hint is also routed through Splash — Splash's plain-text fallback
/// then applies the theme's `plainTextColor`, which is what we want.
public enum CodeFenceLanguageMode: Equatable {
    /// Apply Splash's Swift tokenization (Swift fence or no language hint).
    case swift
    /// Render as plain text styled with the theme's plain-text color (any
    /// non-Swift language hint).
    case plain

    /// Decide how to highlight a code fence whose info string is `language`.
    ///
    /// - Returns:
    ///   - `.swift` if `language` is `nil`, empty/whitespace-only, or
    ///     case-insensitively equal to `"swift"`.
    ///   - `.plain` for any other language hint.
    public static func mode(for language: String?) -> CodeFenceLanguageMode {
        guard let language else { return .swift }
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .swift }
        return trimmed.lowercased() == "swift" ? .swift : .plain
    }
}
