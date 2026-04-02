import Foundation

public struct ValidationError: Sendable {
    public let message: String
    public let isWarning: Bool

    public init(message: String, isWarning: Bool = false) {
        self.message = message
        self.isWarning = isWarning
    }
}

public enum PresentationValidator {

    public static func validate(at path: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            errors.append(ValidationError(message: "File not found: \(path)"))
            return errors
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            errors.append(ValidationError(message: "Could not read file: \(path)"))
            return errors
        }

        return validate(content: content)
    }

    public static func validate(content: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let (metadata, slides) = SlideParser.parse(content)

        // Validate font
        if let font = metadata.font {
            let result = FontValidator.validate(font)
            switch result {
            case .valid:
                break
            case .empty:
                errors.append(ValidationError(message: "Font name is empty"))
            case .invalid(let suggestion):
                var msg = "Font '\(font)' is not available on this system"
                if let suggestion {
                    msg += " (did you mean '\(suggestion)'?)"
                }
                errors.append(ValidationError(message: msg))
            }
        }

        // Validate theme colors
        let colorFields: [(String, String?)] = [
            ("theme_background", metadata.themeBackground),
            ("theme_text", metadata.themeText),
            ("theme_heading", metadata.themeHeading),
            ("theme_accent", metadata.themeAccent),
            ("theme_code_background", metadata.themeCodeBackground),
            ("theme_code_text", metadata.themeCodeText),
        ]
        for (key, value) in colorFields {
            if let hex = value {
                if ThemeDefinition.parseHex(hex) == nil {
                    errors.append(ValidationError(message: "Invalid hex color for \(key): '\(hex)'"))
                }
            }
        }

        // Validate slide layouts
        for slide in slides {
            let lines = slide.content.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let pair = trimmed.split(separator: ":", maxSplits: 1)
                if pair.count == 2 {
                    let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = pair[1].trimmingCharacters(in: .whitespaces)
                    if key == "layout" && SlideLayout(rawValue: value) == nil {
                        errors.append(ValidationError(
                            message: "Unknown layout '\(value)' on slide \(slide.id + 1) (valid: default, title, two-column, image-left, image-right, video, embed)"
                        ))
                    }
                }
                // Stop after first non-frontmatter line
                if !trimmed.isEmpty && pair.count != 2 {
                    break
                }
            }
        }

        return errors
    }
}
