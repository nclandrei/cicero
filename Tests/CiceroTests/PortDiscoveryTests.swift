import Foundation
import Testing
@testable import Shared

@Suite("PortDiscovery")
struct PortDiscoveryTests {

    private let fallback = 19847

    // MARK: - parse

    @Test("Parses a plain integer")
    func parsesInteger() {
        #expect(PortDiscovery.parse("12345") == 12345)
    }

    @Test("Strips surrounding whitespace and trailing newline")
    func parsesWithWhitespace() {
        #expect(PortDiscovery.parse("  20000\n") == 20000)
    }

    @Test("Empty string is nil")
    func emptyIsNil() {
        #expect(PortDiscovery.parse("") == nil)
        #expect(PortDiscovery.parse("\n  \t") == nil)
    }

    @Test("Garbage is nil")
    func garbageIsNil() {
        #expect(PortDiscovery.parse("not-a-port") == nil)
        #expect(PortDiscovery.parse("19847abc") == nil)
    }

    @Test("Out-of-range port is nil")
    func outOfRangeIsNil() {
        #expect(PortDiscovery.parse("80") == nil)        // below 1024
        #expect(PortDiscovery.parse("70000") == nil)     // above 65535
        #expect(PortDiscovery.parse("-1") == nil)
    }

    // MARK: - resolve

    @Test("Env var wins over file")
    func envBeatsFile() {
        let resolved = PortDiscovery.resolve(
            env: ["CICERO_PORT": "30000"],
            fileReader: { "20000" },
            fallback: fallback
        )
        #expect(resolved == 30000)
    }

    @Test("File wins when env is absent")
    func fileWhenEnvMissing() {
        let resolved = PortDiscovery.resolve(
            env: [:],
            fileReader: { "20000" },
            fallback: fallback
        )
        #expect(resolved == 20000)
    }

    @Test("Fallback when neither env nor file is usable")
    func fallbackWhenAllMissing() {
        let resolved = PortDiscovery.resolve(
            env: [:],
            fileReader: { nil },
            fallback: fallback
        )
        #expect(resolved == fallback)
    }

    @Test("Garbage env falls through to file")
    func garbageEnvFallsThroughToFile() {
        let resolved = PortDiscovery.resolve(
            env: ["CICERO_PORT": "garbage"],
            fileReader: { "25000" },
            fallback: fallback
        )
        #expect(resolved == 25000)
    }

    @Test("Garbage env and file both fall through to fallback")
    func garbageEnvAndFileFallThrough() {
        let resolved = PortDiscovery.resolve(
            env: ["CICERO_PORT": "garbage"],
            fileReader: { "also garbage" },
            fallback: fallback
        )
        #expect(resolved == fallback)
    }

    // MARK: - encode

    @Test("Encode appends a single trailing newline")
    func encodeFormat() {
        #expect(PortDiscovery.encode(19847) == "19847\n")
    }
}
