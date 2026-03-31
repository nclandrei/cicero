import Foundation

public enum SlideLayout: String, Codable, Sendable {
    case `default` = "default"
    case title = "title"
    case twoColumn = "two-column"
    case imageLeft = "image-left"
    case imageRight = "image-right"
}

public struct Slide: Codable, Identifiable, Sendable {
    public let id: Int
    /// Raw content including frontmatter lines (used for serialization/editor)
    public var content: String
    /// Content with frontmatter lines stripped (used for rendering)
    public var body: String
    public var layout: SlideLayout
    public var imageURL: String?

    public init(id: Int, content: String) {
        let parsed = SlideParser.parseSlideMetadata(content)
        self.id = id
        self.content = content
        self.body = parsed.body
        self.layout = parsed.layout
        self.imageURL = parsed.imageURL
    }

    public init(id: Int, content: String, body: String, layout: SlideLayout, imageURL: String?) {
        self.id = id
        self.content = content
        self.body = body
        self.layout = layout
        self.imageURL = imageURL
    }

    public var title: String? {
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
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

    public init(title: String? = nil, theme: String? = nil, author: String? = nil, gistId: String? = nil) {
        self.title = title
        self.theme = theme
        self.author = author
        self.gistId = gistId
    }
}

public enum SlideParser {

    public struct SlideMetadata {
        public let body: String
        public let layout: SlideLayout
        public let imageURL: String?
    }

    /// Parse per-slide frontmatter (layout:, image:) from the top of slide content.
    /// Lines like `layout: title` and `image: url` at the very top are consumed.
    public static func parseSlideMetadata(_ content: String) -> SlideMetadata {
        var layout: SlideLayout = .default
        var imageURL: String? = nil
        var bodyLines: [String] = []
        var inFrontmatter = true

        for line in content.components(separatedBy: "\n") {
            if inFrontmatter {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    // Skip leading blank lines in frontmatter zone
                    continue
                }
                let pair = trimmed.split(separator: ":", maxSplits: 1)
                if pair.count == 2 {
                    let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = pair[1].trimmingCharacters(in: .whitespaces)
                    switch key {
                    case "layout":
                        layout = SlideLayout(rawValue: value) ?? .default
                        continue
                    case "image":
                        imageURL = value
                        continue
                    default:
                        // Not a recognized frontmatter key — treat as body
                        inFrontmatter = false
                    }
                } else {
                    inFrontmatter = false
                }
            }
            bodyLines.append(line)
        }

        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return SlideMetadata(body: body, layout: layout, imageURL: imageURL)
    }

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
                let raw = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !raw.isEmpty {
                    slides.append(Slide(id: index, content: raw))
                    index += 1
                }
                current = ""
            } else {
                current += line + "\n"
            }
        }

        let raw = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty {
            slides.append(Slide(id: index, content: raw))
        }
        return slides
    }
}
