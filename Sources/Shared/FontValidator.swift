import CoreText
import Foundation

public enum FontValidationResult: Equatable, Sendable {
    case valid
    case invalid(suggestion: String?)
    case empty
}

public enum FontValidator {

    /// All font family names available on the system.
    public static func availableFontFamilies() -> [String] {
        let names = CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
        return names.sorted()
    }

    /// Whether a font family name matches an installed system font (case-insensitive).
    public static func isSystemFont(_ name: String) -> Bool {
        let lower = name.lowercased()
        return availableFontFamilies().contains { $0.lowercased() == lower }
    }

    /// Validate a font name, returning a suggestion for close matches.
    public static func validate(_ name: String) -> FontValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        if isSystemFont(trimmed) {
            return .valid
        }

        // Try fuzzy match — find closest family name
        let lower = trimmed.lowercased()
        let families = availableFontFamilies()
        var bestMatch: String?
        var bestDistance = Int.max

        for family in families {
            let familyLower = family.lowercased()
            // Check if one contains the other
            if familyLower.contains(lower) || lower.contains(familyLower) {
                return .invalid(suggestion: family)
            }
            let dist = levenshtein(lower, familyLower)
            if dist < bestDistance {
                bestDistance = dist
                bestMatch = family
            }
        }

        // Only suggest if edit distance is reasonable (< 40% of name length)
        let threshold = max(3, trimmed.count * 4 / 10)
        if bestDistance <= threshold, let match = bestMatch {
            return .invalid(suggestion: match)
        }

        return .invalid(suggestion: nil)
    }

    // MARK: - Private

    private static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,       // deletion
                    curr[j - 1] + 1,   // insertion
                    prev[j - 1] + cost  // substitution
                )
            }
            prev = curr
        }
        return prev[n]
    }
}
