import Foundation

public enum PresentationTransition: String, Codable, Sendable, CaseIterable {
    case none = "none"
    case fade = "fade"
    case slide = "slide"
    case push = "push"
}

public enum SlideLayout: String, Codable, Sendable {
    case `default` = "default"
    case title = "title"
    case twoColumn = "two-column"
    case imageLeft = "image-left"
    case imageRight = "image-right"
    case video = "video"
    case embed = "embed"
}

public struct Slide: Codable, Identifiable, Sendable {
    public var id: Int
    /// Raw content including frontmatter lines (used for serialization/editor)
    public var content: String
    /// Content with frontmatter lines stripped (used for rendering)
    public var body: String
    public var layout: SlideLayout
    public var imageURL: String?
    public var videoURL: String?
    public var embedURL: String?
    public var notes: String?
    /// Persisted per-slide drawings, parsed from a `drawings: <base64-json>`
    /// frontmatter line. Nil when there are no drawings on the slide.
    public var drawings: [SlideDrawingStroke]?

    public init(id: Int, content: String) {
        let parsed = SlideParser.parseSlideMetadata(content)
        self.id = id
        self.content = content
        self.body = parsed.body
        self.layout = parsed.layout
        self.imageURL = parsed.imageURL
        self.videoURL = parsed.videoURL
        self.embedURL = parsed.embedURL
        self.notes = parsed.notes
        self.drawings = parsed.drawings
    }

    public init(id: Int, content: String, body: String, layout: SlideLayout, imageURL: String?, videoURL: String? = nil, embedURL: String? = nil, notes: String? = nil, drawings: [SlideDrawingStroke]? = nil) {
        self.id = id
        self.content = content
        self.body = body
        self.layout = layout
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.embedURL = embedURL
        self.notes = notes
        self.drawings = drawings
    }

    /// Update the drawings on this slide, rewriting `content` to keep the
    /// `drawings: <base64-json>` frontmatter line in sync. Passing nil or an
    /// empty array removes the line entirely.
    public mutating func setDrawings(_ strokes: [SlideDrawingStroke]?) {
        let newContent = SlideParser.replaceDrawings(in: content, with: strokes)
        let parsed = SlideParser.parseSlideMetadata(newContent)
        self.content = newContent
        self.body = parsed.body
        self.layout = parsed.layout
        self.imageURL = parsed.imageURL
        self.videoURL = parsed.videoURL
        self.embedURL = parsed.embedURL
        self.notes = parsed.notes
        self.drawings = parsed.drawings
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
    public var themeBackground: String?
    public var themeText: String?
    public var themeHeading: String?
    public var themeAccent: String?
    public var themeCodeBackground: String?
    public var themeCodeText: String?
    public var font: String?
    public var transition: PresentationTransition?

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
        themeCodeText: String? = nil,
        font: String? = nil,
        transition: PresentationTransition? = nil
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
        self.font = font
        self.transition = transition
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

    public struct SlideMetadata {
        public let body: String
        public let layout: SlideLayout
        public let imageURL: String?
        public let videoURL: String?
        public let embedURL: String?
        public let notes: String?
        public let drawings: [SlideDrawingStroke]?
    }

    /// Extract speaker notes from a `<!-- notes ... -->` HTML comment block at the end of content.
    /// Returns the body with the notes block removed, and the notes text (or nil).
    public static func extractNotes(_ content: String) -> (body: String, notes: String?) {
        guard let openRange = content.range(of: "<!-- notes\n") else {
            return (content, nil)
        }
        guard let closeRange = content.range(of: "\n-->", range: openRange.upperBound..<content.endIndex) else {
            return (content, nil)
        }
        let notesText = String(content[openRange.upperBound..<closeRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let body = String(content[content.startIndex..<openRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (body, notesText.isEmpty ? nil : notesText)
    }

    /// Parse per-slide frontmatter (layout:, image:, video:, embed:, drawings:) from the top of slide content.
    /// Lines like `layout: title` and `image: url` at the very top are consumed.
    public static func parseSlideMetadata(_ content: String) -> SlideMetadata {
        // First extract notes from content
        let (contentWithoutNotes, notes) = extractNotes(content)

        var layout: SlideLayout = .default
        var imageURL: String? = nil
        var videoURL: String? = nil
        var embedURL: String? = nil
        var drawings: [SlideDrawingStroke]? = nil
        var bodyLines: [String] = []
        var inFrontmatter = true

        for line in contentWithoutNotes.components(separatedBy: "\n") {
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
                    case "video":
                        videoURL = value
                        continue
                    case "embed":
                        embedURL = value
                        continue
                    case "drawings":
                        // Decode is best-effort. Malformed values yield nil drawings
                        // but the line is still consumed so it does not pollute the body.
                        drawings = SlideDrawingCodec.decode(value)
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
        return SlideMetadata(body: body, layout: layout, imageURL: imageURL, videoURL: videoURL, embedURL: embedURL, notes: notes, drawings: drawings)
    }

    /// Replace the `drawings: <base64>` frontmatter line in slide content. If
    /// `strokes` is nil or empty, removes the line entirely. Otherwise inserts
    /// or updates it. Preserves position of other frontmatter lines.
    public static func replaceDrawings(in content: String, with strokes: [SlideDrawingStroke]?) -> String {
        // Extract notes block first so we don't disturb it.
        let (bodyContent, notes) = extractNotes(content)

        var lines = bodyContent.components(separatedBy: "\n")
        var insertIndex = 0
        var foundDrawingsLine = false
        var inFrontmatter = true

        // Walk leading frontmatter lines. Stop at first non-frontmatter line.
        var i = 0
        while i < lines.count && inFrontmatter {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { i += 1; continue }
            let pair = trimmed.split(separator: ":", maxSplits: 1)
            if pair.count == 2 {
                let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                if ["layout", "image", "video", "embed", "drawings"].contains(key) {
                    if key == "drawings" {
                        // Remove the existing drawings line.
                        lines.remove(at: i)
                        foundDrawingsLine = true
                        continue
                    }
                    i += 1
                    insertIndex = i
                    continue
                }
            }
            inFrontmatter = false
        }
        if !foundDrawingsLine {
            // insertIndex was advanced past existing recognized frontmatter lines.
        }

        if let encoded = SlideDrawingCodec.encode(strokes) {
            lines.insert("drawings: \(encoded)", at: min(insertIndex, lines.count))
        }

        var result = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if let notes {
            result += "\n\n<!-- notes\n\(notes)\n-->"
        }
        return result
    }

    /// Mutate a single per-slide frontmatter field (`layout`, `image`, `video`, `embed`)
    /// in raw slide content. Replaces the line if it exists, inserts at the top of the
    /// frontmatter zone if it doesn't, or removes the line if `value` is nil/empty.
    /// Body text and speaker notes are preserved exactly. Other frontmatter fields are
    /// untouched.
    public static func setSlideMetadataField(_ content: String, key: String, value: String?) -> String {
        let allowedKeys: Set<String> = ["layout", "image", "video", "embed"]
        let lowercaseKey = key.lowercased()
        guard allowedKeys.contains(lowercaseKey) else { return content }

        // Separate notes from main content so we don't accidentally mutate them.
        let (mainBody, notes) = extractNotes(content)

        // Walk lines, classifying frontmatter zone (recognized key:value lines, possibly
        // with leading blank lines) vs body. Same logic as parseSlideMetadata.
        let lines = mainBody.components(separatedBy: "\n")
        var frontmatterIndices: [Int] = []  // indices of recognized frontmatter lines
        var firstBodyIndex = lines.count
        var seenContent = false

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !seenContent {
                if trimmed.isEmpty {
                    // Leading blank lines stay in frontmatter zone but aren't recognized lines.
                    continue
                }
                let pair = trimmed.split(separator: ":", maxSplits: 1)
                if pair.count == 2 {
                    let lk = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                    if allowedKeys.contains(lk) {
                        frontmatterIndices.append(i)
                        continue
                    }
                }
                seenContent = true
                firstBodyIndex = i
                break
            }
        }
        if !seenContent {
            firstBodyIndex = lines.count
        }

        // Find existing line for this key, if any.
        var existingIndex: Int? = nil
        for i in frontmatterIndices {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            let pair = trimmed.split(separator: ":", maxSplits: 1)
            if pair.count == 2 {
                let lk = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                if lk == lowercaseKey {
                    existingIndex = i
                    break
                }
            }
        }

        var newLines = lines
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let v = trimmedValue, !v.isEmpty {
            let newLine = "\(lowercaseKey): \(v)"
            if let idx = existingIndex {
                newLines[idx] = newLine
            } else {
                // Insert at top of frontmatter zone (before first non-frontmatter content,
                // skipping leading blank lines so we don't shove this in front of them).
                let insertAt: Int
                if let lastFM = frontmatterIndices.last {
                    insertAt = lastFM + 1
                } else {
                    // No existing frontmatter — insert at very top.
                    insertAt = 0
                }
                newLines.insert(newLine, at: insertAt)
                _ = firstBodyIndex
            }
        } else {
            // Remove the line if it exists.
            if let idx = existingIndex {
                newLines.remove(at: idx)
            }
        }

        var rebuilt = newLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if let notes {
            rebuilt += "\n\n<!-- notes\n\(notes)\n-->"
        }
        return rebuilt
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

    /// Map a cursor line number (0-based) in the full markdown source to the slide index
    /// it belongs to. Accounts for YAML frontmatter and code fences (so `---` inside code
    /// blocks is not treated as a slide separator). A cursor inside frontmatter or on a
    /// slide-separator line maps to the slide that *precedes* the separator (slide 0 when
    /// in frontmatter). Returns 0 for empty input.
    public static func slideIndex(forLine lineNumber: Int, in markdown: String) -> Int {
        let lines = markdown.components(separatedBy: "\n")
        guard !lines.isEmpty else { return 0 }
        let target = max(0, min(lineNumber, lines.count - 1))

        // Skip YAML frontmatter (leading `---` ... `---`) if present.
        var i = 0
        if lines[0].trimmingCharacters(in: .whitespaces) == "---" {
            for j in 1..<lines.count where lines[j].trimmingCharacters(in: .whitespaces) == "---" {
                i = j + 1
                break
            }
        }

        // Cursor inside frontmatter always maps to slide 0.
        if target < i {
            return 0
        }

        var slideIdx = 0
        var currentSlideHasContent = false
        var inCodeBlock = false

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isFence = trimmed.hasPrefix("```")
            let isSeparator = !inCodeBlock && !isFence && trimmed == "---"

            if target == i {
                return slideIdx
            }

            if isFence {
                inCodeBlock.toggle()
                currentSlideHasContent = true
            } else if isSeparator {
                if currentSlideHasContent {
                    slideIdx += 1
                    currentSlideHasContent = false
                }
            } else if !trimmed.isEmpty {
                currentSlideHasContent = true
            }
            i += 1
        }

        return slideIdx
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
        if let f = metadata.font { fm.append("font: \(f)") }
        if let t = metadata.transition, t != .none { fm.append("transition: \(t.rawValue)") }
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
            case "font": meta.font = value
            case "transition": meta.transition = PresentationTransition(rawValue: value)
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

public extension Array where Element == Slide {
    /// Reassigns each slide's `id` to its current array index. Mutates in
    /// place and preserves every other field on each slide (content, body,
    /// layout, imageURL, videoURL, embedURL, notes). Use after any reorder,
    /// duplicate, or removal operation.
    mutating func reindex() {
        for i in indices {
            self[i].id = i
        }
    }
}
