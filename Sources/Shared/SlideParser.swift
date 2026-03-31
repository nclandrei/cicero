import Foundation

public struct Slide: Codable, Identifiable, Sendable {
    public let id: Int
    public var content: String

    public init(id: Int, content: String) {
        self.id = id
        self.content = content
    }

    public var title: String? {
        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2))
            } else if trimmed.hasPrefix("## ") {
                return String(trimmed.dropFirst(3))
            }
        }
        return nil
    }
}

public struct PresentationMetadata: Codable, Sendable {
    public var title: String?
    public var theme: String?
    public var author: String?
    public var gistId: String?
    public var themeBackground: String?
    public var themeText: String?
    public var themeHeading: String?
    public var themeAccent: String?
    public var themeCodeBackground: String?
    public var themeCodeText: String?

    public init(
        title: String? = nil,
        theme: String? = nil,
        author: String? = nil,
        gistId: String? = nil,
        themeBackground: String? = nil,
        themeText: String? = nil,
        themeHeading: String? = nil,
        themeAccent: String? = nil,
        themeCodeBackground: String? = nil,
        themeCodeText: String? = nil
    ) {
        self.title = title
        self.theme = theme
        self.author = author
        self.gistId = gistId
        self.themeBackground = themeBackground
        self.themeText = themeText
        self.themeHeading = themeHeading
        self.themeAccent = themeAccent
        self.themeCodeBackground = themeCodeBackground
        self.themeCodeText = themeCodeText
    }

    /// Resolve theme from metadata: named built-in, custom inline, or nil
    public func resolveTheme() -> ThemeDefinition? {
        guard let themeName = theme, themeName != "auto" else { return nil }
        if themeName == "custom" {
            guard let bg = themeBackground else { return nil }
            return ThemeDefinition(
                name: "custom",
                background: bg,
                text: themeText ?? "#ffffff",
                heading: themeHeading ?? themeText ?? "#ffffff",
                accent: themeAccent ?? "#6c63ff",
                codeBackground: themeCodeBackground ?? bg,
                codeText: themeCodeText ?? themeText ?? "#ffffff"
            )
        }
        return ThemeRegistry.find(themeName)
    }
}

public enum SlideParser {

    public static func parse(_ markdown: String) -> (metadata: PresentationMetadata, slides: [Slide]) {
        var content = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        var metadata = PresentationMetadata()

        // Detect YAML frontmatter delimited by --- on first line
        if content.hasPrefix("---") {
            let lines = content.components(separatedBy: "\n")
            var frontmatterEnd = -1
            for i in 1..<lines.count {
                if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                    frontmatterEnd = i
                    break
                }
            }
            if frontmatterEnd > 0 {
                let yaml = lines[1..<frontmatterEnd].joined(separator: "\n")
                metadata = parseFrontmatter(yaml)
                content = lines[(frontmatterEnd + 1)...].joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let slides = splitSlides(content)
        return (metadata, slides)
    }

    public static func serialize(metadata: PresentationMetadata, slides: [Slide]) -> String {
        var parts: [String] = []

        var fm: [String] = []
        if let t = metadata.title { fm.append("title: \(t)") }
        if let t = metadata.theme { fm.append("theme: \(t)") }
        if let a = metadata.author { fm.append("author: \(a)") }
        if let g = metadata.gistId { fm.append("gist_id: \(g)") }
        if let v = metadata.themeBackground { fm.append("theme_background: \(v)") }
        if let v = metadata.themeText { fm.append("theme_text: \(v)") }
        if let v = metadata.themeHeading { fm.append("theme_heading: \(v)") }
        if let v = metadata.themeAccent { fm.append("theme_accent: \(v)") }
        if let v = metadata.themeCodeBackground { fm.append("theme_code_background: \(v)") }
        if let v = metadata.themeCodeText { fm.append("theme_code_text: \(v)") }
        if !fm.isEmpty {
            parts.append("---\n\(fm.joined(separator: "\n"))\n---")
        }

        for slide in slides {
            parts.append(slide.content)
        }

        return parts.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Private

    private static func parseFrontmatter(_ yaml: String) -> PresentationMetadata {
        var meta = PresentationMetadata()
        for line in yaml.split(separator: "\n") {
            let pair = line.split(separator: ":", maxSplits: 1)
            guard pair.count == 2 else { continue }
            let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = pair[1].trimmingCharacters(in: .whitespaces)
            switch key {
            case "title": meta.title = value
            case "theme": meta.theme = value
            case "author": meta.author = value
            case "gist_id": meta.gistId = value
            case "theme_background": meta.themeBackground = value
            case "theme_text": meta.themeText = value
            case "theme_heading": meta.themeHeading = value
            case "theme_accent": meta.themeAccent = value
            case "theme_code_background": meta.themeCodeBackground = value
            case "theme_code_text": meta.themeCodeText = value
            default: break
            }
        }
        return meta
    }

    private static func splitSlides(_ content: String) -> [Slide] {
        var slides: [Slide] = []
        var current = ""
        var index = 0
        var inCodeBlock = false

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
            }
            if !inCodeBlock && trimmed == "---" {
                let body = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !body.isEmpty {
                    slides.append(Slide(id: index, content: body))
                    index += 1
                }
                current = ""
            } else {
                current += line + "\n"
            }
        }

        let body = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty {
            slides.append(Slide(id: index, content: body))
        }
        return slides
    }
}
