import Foundation

/// Helpers for emitting TOML string literals safely. The Codex MCP config
/// is hand-rolled TOML (Codex doesn't read JSON), so any path we substitute
/// into `command = "…"` must be properly escaped or wrapped in a literal
/// string. Concentrating the policy here keeps it unit-testable from
/// `Shared` without depending on the Cicero target.
public enum TOMLString {

    /// Quote `value` as a TOML string literal suitable for substituting on
    /// the right-hand side of a key=value assignment. Prefers a literal
    /// (single-quoted) string when the value contains no single quotes,
    /// because literal strings need zero escaping and round-trip absolute
    /// filesystem paths byte-for-byte. Falls back to a basic
    /// (double-quoted) string with full escaping when the input contains
    /// a single quote (which TOML literal strings cannot represent).
    public static func quote(_ value: String) -> String {
        if !value.contains("'") {
            // TOML literal string: surrounded by single quotes, contents
            // taken verbatim. Forbids only the single-quote character.
            return "'\(value)'"
        }
        return "\"\(escapeBasic(value))\""
    }

    /// Apply the basic-string escape rules from the TOML spec:
    /// backslash, double-quote, and the control characters
    /// (b, t, n, f, r). Other control characters are emitted as `\uXXXX`.
    private static func escapeBasic(_ value: String) -> String {
        var out = ""
        out.reserveCapacity(value.count)
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\\":          out += "\\\\"
            case "\"":          out += "\\\""
            case "\u{08}":      out += "\\b"
            case "\t":          out += "\\t"
            case "\n":          out += "\\n"
            case "\u{0C}":      out += "\\f"
            case "\r":          out += "\\r"
            default:
                if scalar.value < 0x20 || scalar.value == 0x7F {
                    out += String(format: "\\u%04X", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out
    }
}
