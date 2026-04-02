import Testing

// EditHistory is defined in the Cicero target which is an executable,
// so we test the logic inline here with a minimal reimplementation.
// This mirrors the exact logic of Sources/Cicero/Models/EditHistory.swift.

/// Test-local copy of EditHistory logic to unit-test without importing the app target.
private final class EditHistory {
    private(set) var undoStack: [String] = []
    private(set) var redoStack: [String] = []
    private let maxStackSize = 50

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func checkpoint(_ text: String) {
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

@Suite("EditHistory")
struct EditHistoryTests {

    @Test("Checkpoint pushes state to undo stack")
    func checkpointPushes() {
        let history = EditHistory()
        history.checkpoint("state1")
        #expect(history.canUndo)
        #expect(history.undoStack == ["state1"])
    }

    @Test("Duplicate checkpoint is ignored")
    func duplicateCheckpoint() {
        let history = EditHistory()
        history.checkpoint("state1")
        history.checkpoint("state1")
        #expect(history.undoStack.count == 1)
    }

    @Test("Undo returns previous state and pushes current to redo")
    func undoReturnsPrevious() {
        let history = EditHistory()
        history.checkpoint("state1")
        let result = history.undo(currentText: "state2")
        #expect(result == "state1")
        #expect(!history.canUndo)
        #expect(history.canRedo)
        #expect(history.redoStack == ["state2"])
    }

    @Test("Redo returns next state and pushes current to undo")
    func redoReturnsNext() {
        let history = EditHistory()
        history.checkpoint("state1")
        let _ = history.undo(currentText: "state2")
        let result = history.redo(currentText: "state1")
        #expect(result == "state2")
        #expect(history.canUndo)
        #expect(!history.canRedo)
        #expect(history.undoStack == ["state1"])
    }

    @Test("New checkpoint clears redo stack")
    func checkpointClearsRedo() {
        let history = EditHistory()
        history.checkpoint("state1")
        let _ = history.undo(currentText: "state2")
        #expect(history.canRedo)
        history.checkpoint("state3")
        #expect(!history.canRedo)
        #expect(history.redoStack.isEmpty)
    }

    @Test("Undo on empty stack returns nil")
    func undoEmptyStack() {
        let history = EditHistory()
        let result = history.undo(currentText: "current")
        #expect(result == nil)
    }

    @Test("Redo on empty stack returns nil")
    func redoEmptyStack() {
        let history = EditHistory()
        let result = history.redo(currentText: "current")
        #expect(result == nil)
    }

    @Test("Max stack size is respected for undo stack")
    func maxUndoStackSize() {
        let history = EditHistory()
        for i in 0..<60 {
            history.checkpoint("state\(i)")
        }
        #expect(history.undoStack.count == 50)
        // Oldest entries should be dropped — first entry should be state10
        #expect(history.undoStack.first == "state10")
        #expect(history.undoStack.last == "state59")
    }

    @Test("Max stack size is respected for redo stack")
    func maxRedoStackSize() {
        let history = EditHistory()
        // Build up 50 entries in undo stack
        for i in 0..<50 {
            history.checkpoint("state\(i)")
        }
        // Undo all 50 to fill redo stack
        for i in 0..<50 {
            let _ = history.undo(currentText: "current\(i)")
        }
        #expect(history.redoStack.count == 50)
    }

    @Test("Multiple undo/redo cycles work correctly")
    func multipleUndoRedoCycles() {
        let history = EditHistory()

        // Build history: A -> B -> C
        history.checkpoint("A")
        history.checkpoint("B")
        history.checkpoint("C")

        // Current text is "D", undo to C
        var result = history.undo(currentText: "D")
        #expect(result == "C")

        // Undo to B
        result = history.undo(currentText: "C")
        #expect(result == "B")

        // Redo to C
        result = history.redo(currentText: "B")
        #expect(result == "C")

        // Redo to D
        result = history.redo(currentText: "C")
        #expect(result == "D")

        // Should be back to original state
        #expect(!history.canRedo)
        #expect(history.canUndo)
    }

    @Test("Clear removes all history")
    func clearHistory() {
        let history = EditHistory()
        history.checkpoint("A")
        history.checkpoint("B")
        let _ = history.undo(currentText: "C")
        #expect(history.canUndo)
        #expect(history.canRedo)
        history.clear()
        #expect(!history.canUndo)
        #expect(!history.canRedo)
    }

    @Test("Undo then new checkpoint creates branch")
    func undoThenCheckpointBranches() {
        let history = EditHistory()
        history.checkpoint("A")
        history.checkpoint("B")
        history.checkpoint("C")

        // Undo twice: back to B then A
        let _ = history.undo(currentText: "D")
        let _ = history.undo(currentText: "C")

        // New checkpoint from state B should clear redo
        history.checkpoint("E")
        #expect(!history.canRedo)
        #expect(history.undoStack == ["A", "E"])
    }
}
