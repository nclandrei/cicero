import Foundation

/// Computes display-width constraints for images rendered inside slide previews.
public enum ImageSizing {
    public static let maxAllowedWidth: CGFloat = 1600
    public static let minAllowedWidth: CGFloat = 100

    /// Returns the max display width for a slide image.
    ///
    /// - Parameters:
    ///   - explicitWidth: Width from a `#w=N` URL fragment, if any.
    ///   - naturalWidth: The image's intrinsic pixel width.
    /// - Returns: The width to use as `maxWidth` / `width` frame constraint.
    public static func constrainedWidth(
        explicitWidth: CGFloat?,
        naturalWidth: CGFloat
    ) -> CGFloat {
        if let explicitWidth {
            return max(minAllowedWidth, min(explicitWidth, maxAllowedWidth))
        }
        return min(naturalWidth, maxAllowedWidth)
    }
}

// MARK: - Positioned Images

/// A single `![alt](url#w=…&x=…&y=…)` reference extracted from slide markdown.
///
/// Positions are expressed in the 960×540 reference coordinate space (same one used
/// by `SlideView` for theme scaling). Both `x` and `y` are required for an image
/// to be rendered as a freely positioned overlay — otherwise it renders inline.
public struct PositionedImageRef: Sendable, Equatable {
    public let url: String
    public let width: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    public let alt: String
    /// The range of the full `![alt](url#…)` match inside the source string (as UTF-16 offsets).
    public let matchRange: NSRange

    public init(url: String, width: CGFloat, x: CGFloat, y: CGFloat, alt: String, matchRange: NSRange) {
        self.url = url
        self.width = width
        self.x = x
        self.y = y
        self.alt = alt
        self.matchRange = matchRange
    }
}

public enum PositionedImageParser {
    /// Scans the text for `![alt](url#…)` patterns whose fragment contains
    /// both `x=` and `y=` keys. Returns one `PositionedImageRef` per match.
    ///
    /// Width defaults to 400 if missing.
    public static func parse(_ text: String) -> [PositionedImageRef] {
        let pattern = "!\\[([^\\]]*)\\]\\(([^)\\s]+)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        var results: [PositionedImageRef] = []
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let alt = nsText.substring(with: match.range(at: 1))
            let fullURL = nsText.substring(with: match.range(at: 2))
            guard let parsed = parseFragment(fullURL) else { continue }
            guard let x = parsed.x, let y = parsed.y else { continue }
            results.append(
                PositionedImageRef(
                    url: parsed.path,
                    width: parsed.width ?? 400,
                    x: x,
                    y: y,
                    alt: alt,
                    matchRange: match.range
                )
            )
        }
        return results
    }

    /// Returns the source path and fragment values for a markdown image URL.
    /// Path is the portion before any `#` character.
    public static func parseFragment(_ urlString: String) -> (path: String, width: CGFloat?, x: CGFloat?, y: CGFloat?)? {
        let parts = urlString.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let path = String(parts[0])
        guard !path.isEmpty else { return nil }
        guard parts.count == 2 else {
            return (path, nil, nil, nil)
        }
        let fragment = String(parts[1])
        var width: CGFloat?
        var x: CGFloat?
        var y: CGFloat?
        for param in fragment.split(separator: "&") {
            let kv = param.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let key = kv[0]
            guard let value = Double(kv[1]) else { continue }
            switch key {
            case "w": width = CGFloat(value)
            case "x": x = CGFloat(value)
            case "y": y = CGFloat(value)
            default: break
            }
        }
        return (path, width, x, y)
    }
}
