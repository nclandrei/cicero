import Testing
import Foundation
@testable import Shared

// Tests for the pure logic backing MCPInstaller — launch-source detection
// and config-entry rendering. The pure helpers live in Shared so they can
// be exercised here without importing the Cicero executable target.

@Suite("MCPInstaller — launch source detection")
struct MCPInstallerLaunchSourceTests {

    /// Simulated app bundle: /Applications/Cicero.app
    private let bundleURL = URL(fileURLWithPath: "/Applications/Cicero.app")
    private var bundledBinaryURL: URL { bundleURL.appendingPathComponent("Contents/MacOS/CiceroMCP") }

    @Test("Bundled CiceroMCP binary present → returns .bundled with absolute path")
    func test_bundledBinaryPresent_returnsBundledSource() {
        let existing: Set<String> = [bundledBinaryURL.path]
        let fileExists: (URL) -> Bool = { existing.contains($0.path) }

        let source = CiceroMCPLaunchSource.detect(
            bundleURL: bundleURL,
            executableURL: nil,
            currentDirectoryPath: "/tmp",
            fileExists: fileExists
        )

        switch source {
        case .bundled(let url):
            #expect(url.path == bundledBinaryURL.path)
        case .source, .none:
            Issue.record("Expected .bundled, got \(String(describing: source))")
        }
    }

    @Test("No bundled binary, Package.swift found in walk-up → returns .source")
    func test_noBundledBinary_findsPackageSwift_returnsSourceSource() {
        // Synthetic: executable is at /Users/me/cicero/.build/debug/Cicero
        // Package.swift is 3 levels up: /Users/me/cicero/Package.swift
        let execURL = URL(fileURLWithPath: "/Users/me/cicero/.build/debug/Cicero")
        let packageRoot = URL(fileURLWithPath: "/Users/me/cicero")
        let packageSwift = packageRoot.appendingPathComponent("Package.swift")

        let existing: Set<String> = [packageSwift.path]
        let fileExists: (URL) -> Bool = { existing.contains($0.path) }

        let source = CiceroMCPLaunchSource.detect(
            bundleURL: bundleURL,
            executableURL: execURL,
            currentDirectoryPath: "/tmp",
            fileExists: fileExists
        )

        switch source {
        case .source(let pkg):
            #expect(pkg.path == packageRoot.path)
        case .bundled, .none:
            Issue.record("Expected .source, got \(String(describing: source))")
        }
    }

    @Test("Neither bundled binary nor Package.swift → returns .none")
    func test_noBundledBinary_noPackageSwift_returnsError() {
        let execURL = URL(fileURLWithPath: "/Applications/Cicero.app/Contents/MacOS/Cicero")
        let fileExists: (URL) -> Bool = { _ in false }

        let source = CiceroMCPLaunchSource.detect(
            bundleURL: bundleURL,
            executableURL: execURL,
            currentDirectoryPath: "/tmp",
            fileExists: fileExists
        )

        switch source {
        case .none:
            break
        case .bundled, .source:
            Issue.record("Expected .none, got \(String(describing: source))")
        }
    }

    @Test("Falls back to current working directory when walk-up fails")
    func test_noBundledBinary_cwdHasPackageSwift_returnsSourceFromCWD() {
        let cwd = "/Users/me/cicero"
        let packageSwift = URL(fileURLWithPath: cwd).appendingPathComponent("Package.swift")
        let existing: Set<String> = [packageSwift.path]
        let fileExists: (URL) -> Bool = { existing.contains($0.path) }

        let source = CiceroMCPLaunchSource.detect(
            bundleURL: bundleURL,
            executableURL: nil,
            currentDirectoryPath: cwd,
            fileExists: fileExists
        )

        switch source {
        case .source(let pkg):
            #expect(pkg.path == cwd)
        case .bundled, .none:
            Issue.record("Expected .source from cwd, got \(String(describing: source))")
        }
    }

    @Test("Bundled binary takes priority over Package.swift walk-up")
    func test_bundledTakesPriorityOverSource() {
        let execURL = URL(fileURLWithPath: "/Users/me/cicero/.build/debug/Cicero")
        let packageRoot = URL(fileURLWithPath: "/Users/me/cicero")
        let existing: Set<String> = [
            bundledBinaryURL.path,
            packageRoot.appendingPathComponent("Package.swift").path,
        ]
        let fileExists: (URL) -> Bool = { existing.contains($0.path) }

        let source = CiceroMCPLaunchSource.detect(
            bundleURL: bundleURL,
            executableURL: execURL,
            currentDirectoryPath: "/tmp",
            fileExists: fileExists
        )

        switch source {
        case .bundled:
            break
        default:
            Issue.record("Expected .bundled to win over .source, got \(String(describing: source))")
        }
    }
}

@Suite("MCPInstaller — config entry rendering")
struct MCPInstallerRenderingTests {

    @Test("Bundled launch source renders absolute binary path with empty args")
    func test_renderedConfig_bundled_usesAbsolutePath() {
        let binary = URL(fileURLWithPath: "/Applications/Cicero.app/Contents/MacOS/CiceroMCP")
        let source = CiceroMCPLaunchSource.bundled(binary)

        let entry = source.serverEntry(forOpenCode: false)

        #expect(entry["command"] as? String == binary.path)
        #expect((entry["args"] as? [String])?.isEmpty == true)
    }

    @Test("Source launch source renders `swift run --package-path … CiceroMCP`")
    func test_renderedConfig_source_usesSwiftRun() {
        let pkg = URL(fileURLWithPath: "/Users/me/cicero")
        let source = CiceroMCPLaunchSource.source(packagePath: pkg)

        let entry = source.serverEntry(forOpenCode: false)

        #expect(entry["command"] as? String == "swift")
        #expect(entry["args"] as? [String] == ["run", "--package-path", pkg.path, "CiceroMCP"])
    }

    @Test("Bundled OpenCode entry uses absolute path in `command` array")
    func test_renderedConfig_bundled_openCode() {
        let binary = URL(fileURLWithPath: "/Applications/Cicero.app/Contents/MacOS/CiceroMCP")
        let source = CiceroMCPLaunchSource.bundled(binary)

        let entry = source.serverEntry(forOpenCode: true)

        #expect(entry["type"] as? String == "local")
        #expect(entry["enabled"] as? Bool == true)
        #expect(entry["command"] as? [String] == [binary.path])
    }

    @Test("Source OpenCode entry uses swift run command array")
    func test_renderedConfig_source_openCode() {
        let pkg = URL(fileURLWithPath: "/Users/me/cicero")
        let source = CiceroMCPLaunchSource.source(packagePath: pkg)

        let entry = source.serverEntry(forOpenCode: true)

        #expect(entry["type"] as? String == "local")
        #expect(entry["enabled"] as? Bool == true)
        #expect(entry["command"] as? [String] == ["swift", "run", "--package-path", pkg.path, "CiceroMCP"])
    }

    @Test("Bundled TOML entry quotes the absolute path with empty args")
    func test_renderedTOML_bundled() {
        let binary = URL(fileURLWithPath: "/Applications/Cicero.app/Contents/MacOS/CiceroMCP")
        let source = CiceroMCPLaunchSource.bundled(binary)

        let toml = source.tomlEntry()

        #expect(toml.contains("[mcp_servers.cicero]"))
        // Paths are emitted as TOML literal strings (single-quoted) so
        // backslashes and double quotes round-trip untouched.
        #expect(toml.contains("command = '\(binary.path)'"))
        #expect(toml.contains("args = []"))
        #expect(!toml.contains("swift"))
    }

    @Test("Source TOML entry uses swift run with package path")
    func test_renderedTOML_source() {
        let pkg = URL(fileURLWithPath: "/Users/me/cicero")
        let source = CiceroMCPLaunchSource.source(packagePath: pkg)

        let toml = source.tomlEntry()

        #expect(toml.contains("[mcp_servers.cicero]"))
        #expect(toml.contains("command = \"swift\""))
        #expect(toml.contains("\"run\", \"--package-path\", '\(pkg.path)', \"CiceroMCP\""))
    }

    @Test("Bundled TOML entry tolerates spaces in the path")
    func test_renderedTOML_bundled_pathWithSpaces() {
        // The original hand-rolled implementation only escaped backslashes,
        // so any path-with-double-quote would have produced invalid TOML.
        // The literal-string form leaves spaces and quotes alone.
        let binary = URL(fileURLWithPath: "/Users/Foo Bar/cicero-mcp")
        let source = CiceroMCPLaunchSource.bundled(binary)

        let toml = source.tomlEntry()

        #expect(toml.contains("command = '/Users/Foo Bar/cicero-mcp'"))
    }

    @Test("Source TOML entry falls back to escaped basic string when path contains a single quote")
    func test_renderedTOML_source_singleQuote() {
        let pkg = URL(fileURLWithPath: "/Users/o'brien/cicero")
        let source = CiceroMCPLaunchSource.source(packagePath: pkg)

        let toml = source.tomlEntry()

        // Single quote in the path forces a basic (double-quoted) string.
        #expect(toml.contains("\"--package-path\", \"/Users/o'brien/cicero\""))
    }

    @Test("Display path: bundled returns binary path, source returns package dir")
    func test_displayPath() {
        let binary = URL(fileURLWithPath: "/Applications/Cicero.app/Contents/MacOS/CiceroMCP")
        let pkg = URL(fileURLWithPath: "/Users/me/cicero")

        #expect(CiceroMCPLaunchSource.bundled(binary).displayPath == binary.path)
        #expect(CiceroMCPLaunchSource.source(packagePath: pkg).displayPath == pkg.path)
    }
}
