import Foundation

/// Pure policy used by `Presentation.save()` to detect that the file on
/// disk was modified by something else (a different editor, a sync
/// agent) since Cicero last touched it. The actual filesystem call is
/// done by the caller — this helper only compares the two timestamps so
/// the rule is unit-testable from `Shared` without any disk I/O.
public enum SaveConflictPolicy {

    /// Returns `true` when the save should be refused because the on-disk
    /// modification time has moved since Cicero last wrote (or read) the
    /// file. The convention is:
    ///
    /// - `lastKnown == nil` — we never observed the file, so there's
    ///   nothing to compare. Allow the save (this is a fresh save_as).
    /// - `currentOnDisk == nil` — the file was deleted while open. Allow
    ///   the save (re-create it).
    /// - Both present — refuse iff `currentOnDisk > lastKnown`. Equal
    ///   timestamps are fine. An older on-disk timestamp (clock skew,
    ///   file system rounding) is also tolerated.
    public static func shouldRejectSave(
        lastKnown: Date?,
        currentOnDisk: Date?
    ) -> Bool {
        guard let lastKnown, let currentOnDisk else { return false }
        // Allow a tiny tolerance (1 second) to absorb filesystem timestamp
        // truncation. APFS records mtime at nanosecond precision but some
        // network filesystems round to whole seconds.
        return currentOnDisk.timeIntervalSince(lastKnown) > 1.0
    }
}
