import Foundation
import Testing
@testable import Shared

@Suite("SaveConflictPolicy")
struct SaveConflictPolicyTests {

    private static let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Both timestamps nil — allow (fresh save)")
    func bothNilAllowed() {
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: nil, currentOnDisk: nil) == false)
    }

    @Test("Last known nil — allow (we never observed the file)")
    func lastKnownNilAllowed() {
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: nil, currentOnDisk: now) == false)
    }

    @Test("On-disk nil — allow (file was deleted while open)")
    func onDiskNilAllowed() {
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: nil) == false)
    }

    @Test("Equal timestamps — allow")
    func equalTimestampsAllowed() {
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: now) == false)
    }

    @Test("On-disk older than last known — allow (clock skew tolerated)")
    func olderOnDiskAllowed() {
        let earlier = now.addingTimeInterval(-30)
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: earlier) == false)
    }

    @Test("On-disk a few hundred ms newer — allow (filesystem rounding tolerated)")
    func subSecondNewerAllowed() {
        let slightlyNewer = now.addingTimeInterval(0.5)
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: slightlyNewer) == false)
    }

    @Test("On-disk five seconds newer — refuse (external edit)")
    func clearlyNewerRejected() {
        let later = now.addingTimeInterval(5)
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: later) == true)
    }

    @Test("On-disk just over the 1-second tolerance — refuse")
    func justOverToleranceRejected() {
        let later = now.addingTimeInterval(1.1)
        #expect(SaveConflictPolicy.shouldRejectSave(lastKnown: now, currentOnDisk: later) == true)
    }
}
