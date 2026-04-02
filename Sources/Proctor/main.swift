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

    let errors = PresentationValidator.validate(at: filePath)

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
