import Foundation

/// Entries Cicero contributes to the Edit ▸ Find submenu. The `tag` value is
/// the raw value of the corresponding `NSTextFinder.Action`, which lets
/// `performTextFinderAction(_:)` on the focused NSTextView route to the
/// correct behavior. Modifiers are kept as plain Bools so this stays in
/// `Shared` without importing AppKit/SwiftUI.
public enum FindAction: CaseIterable, Equatable, Sendable {
    case find
    case findNext
    case findPrevious
    case findAndReplace

    public var title: String {
        switch self {
        case .find: return "Find…"
        case .findNext: return "Find Next"
        case .findPrevious: return "Find Previous"
        case .findAndReplace: return "Find and Replace…"
        }
    }

    public var key: Character {
        switch self {
        case .find, .findAndReplace: return "f"
        case .findNext, .findPrevious: return "g"
        }
    }

    public var requiresShift: Bool {
        self == .findPrevious
    }

    public var requiresOption: Bool {
        self == .findAndReplace
    }

    /// Raw value of the matching `NSTextFinder.Action`.
    public var tag: Int {
        switch self {
        case .find: return 1            // showFindInterface
        case .findNext: return 2        // nextMatch
        case .findPrevious: return 3    // previousMatch
        case .findAndReplace: return 12 // showReplaceInterface
        }
    }
}
