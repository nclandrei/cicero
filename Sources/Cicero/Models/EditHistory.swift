import Foundation
import Observation

@Observable
final class EditHistory {
    private(set) var undoStack: [String] = []
    private(set) var redoStack: [String] = []
    private let maxStackSize = 50

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func checkpoint(_ text: String) {
        // Don't push duplicates
        if undoStack.last == text { return }
        undoStack.append(text)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    func undo(currentText: String) -> String? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(currentText)
        if redoStack.count > maxStackSize {
            redoStack.removeFirst()
        }
        return previous
    }

    func redo(currentText: String) -> String? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(currentText)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        return next
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
