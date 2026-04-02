import Foundation
import Shared

// MARK: - ANSI Colors

enum ANSIColor: String {
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case cyan = "\u{001B}[36m"
    case bold = "\u{001B}[1m"
    case reset = "\u{001B}[0m"
}

func colored(_ text: String, _ color: ANSIColor) -> String {
    "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
}

// MARK: - Validation

struct ValidationError {
    let message: String
    let isWarning: Bool
}

func validatePresentation(at path: String) -> [ValidationError] {
    var errors: [ValidationError] = []

    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        errors.append(ValidationError(message: "File not found: \(path)", isWarning: false))
        return errors
    }

    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        errors.append(ValidationError(message: "Could not read file: \(path)", isWarning: false))
        return errors
    }

    let (metadata, slides) = SlideParser.parse(content)

    // Validate font
    if let font = metadata.font {
        let result = FontValidator.validate(font)
        switch result {
        case .valid:
            break
        case .empty:
            errors.append(ValidationError(message: "Font name is empty", isWarning: false))
        case .invalid(let suggestion):
            var msg = "Font '\(font)' is not available on this system"
            if let suggestion {
                msg += " (did you mean '\(suggestion)'?)"
            }
            errors.append(ValidationError(message: msg, isWarning: false))
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
                errors.append(ValidationError(message: "Invalid hex color for \(key): '\(hex)'", isWarning: false))
            }
        }
    }

    // Validate slide layouts
    for slide in slides {
        // Layout is already validated by the parser (defaults to .default for unknown values),
        // but warn if frontmatter has an unrecognized layout string
        let lines = slide.content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let pair = trimmed.split(separator: ":", maxSplits: 1)
            if pair.count == 2 {
                let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = pair[1].trimmingCharacters(in: .whitespaces)
                if key == "layout" && SlideLayout(rawValue: value) == nil {
                    errors.append(ValidationError(
                        message: "Unknown layout '\(value)' on slide \(slide.id + 1) (valid: default, title, two-column, image-left, image-right, video, embed)",
                        isWarning: false
                    ))
                }
            }
            // Stop checking after first non-frontmatter line
            if !trimmed.isEmpty && pair.count != 2 {
                break
            }
        }
    }

    return errors
}

// MARK: - Commands

func printUsage() {
    print("""
    \(colored("Proctor", .bold)) — Cicero presentation validator

    \(colored("USAGE:", .cyan))
      proctor validate <file.md>   Validate a presentation file
      proctor fonts                List available system font families
      proctor --help, -h           Show this help message

    \(colored("EXIT CODES:", .cyan))
      0  Validation passed (or help/fonts command)
      1  Validation errors found
    """)
}

func listFonts() {
    let families = FontValidator.availableFontFamilies()
    print(colored("\(families.count) font families available:\n", .bold))
    for family in families {
        print("  \(family)")
    }
}

func validate(filePath: String) -> Int32 {
    print(colored("Validating: \(filePath)\n", .bold))

    let errors = validatePresentation(at: filePath)

    if errors.isEmpty {
        print(colored("✓ No issues found", .green))
        return 0
    }

    for error in errors {
        if error.isWarning {
            print(colored("  ⚠ ", .yellow) + error.message)
        } else {
            print(colored("  ✗ ", .red) + error.message)
        }
    }

    let errorCount = errors.filter { !$0.isWarning }.count
    let warningCount = errors.filter { $0.isWarning }.count

    var summary = ""
    if errorCount > 0 { summary += colored("\(errorCount) error(s)", .red) }
    if warningCount > 0 {
        if !summary.isEmpty { summary += ", " }
        summary += colored("\(warningCount) warning(s)", .yellow)
    }
    print("\n" + summary)

    return errorCount > 0 ? 1 : 0
}

// MARK: - Main

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty || args.first == "--help" || args.first == "-h" {
    printUsage()
    exit(0)
}

switch args.first {
case "fonts":
    listFonts()
    exit(0)
case "validate":
    guard args.count >= 2 else {
        print(colored("Error: missing file path", .red))
        print("Usage: proctor validate <file.md>")
        exit(1)
    }
    let code = validate(filePath: args[1])
    exit(code)
default:
    print(colored("Unknown command: \(args.first ?? "")", .red))
    printUsage()
    exit(1)
}
