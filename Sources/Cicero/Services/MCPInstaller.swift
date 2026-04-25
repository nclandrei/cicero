import Foundation
import Shared

// MARK: - Agent definitions

enum MCPAgent: String, CaseIterable, Identifiable {
    case claudeCode
    case claudeDesktop
    case cursor
    case windsurf
    case amp
    case openCode
    case codex

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode:    return "Claude Code"
        case .claudeDesktop: return "Claude Desktop"
        case .cursor:        return "Cursor"
        case .windsurf:      return "Windsurf"
        case .amp:           return "Amp"
        case .openCode:      return "OpenCode"
        case .codex:         return "Codex"
        }
    }

    var iconName: String {
        switch self {
        case .claudeCode:    return "terminal"
        case .claudeDesktop: return "message"
        case .cursor:        return "cursorarrow"
        case .windsurf:      return "wind"
        case .amp:           return "bolt"
        case .openCode:      return "chevron.left.forwardslash.chevron.right"
        case .codex:         return "book"
        }
    }

    var configURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .claudeCode:
            return home.appendingPathComponent(".claude.json")
        case .claudeDesktop:
            return home.appendingPathComponent("Library/Application Support/Claude/claude_desktop_config.json")
        case .cursor:
            return home.appendingPathComponent(".cursor/mcp.json")
        case .windsurf:
            return home.appendingPathComponent(".codeium/windsurf/mcp_config.json")
        case .amp:
            return home.appendingPathComponent(".config/amp/settings.json")
        case .openCode:
            return home.appendingPathComponent(".config/opencode/opencode.json")
        case .codex:
            return home.appendingPathComponent(".codex/config.toml")
        }
    }

    /// The JSON key that holds the MCP servers dictionary.
    var serversKey: String {
        switch self {
        case .amp:      return "amp.mcpServers"
        case .openCode: return "mcp"
        default:        return "mcpServers"
        }
    }

    var isJSON: Bool { self != .codex }

    /// Short description of the config file location (for display).
    var configDescription: String {
        switch self {
        case .claudeCode:    return "~/.claude.json"
        case .claudeDesktop: return "~/Library/Application Support/Claude/claude_desktop_config.json"
        case .cursor:        return "~/.cursor/mcp.json"
        case .windsurf:      return "~/.codeium/windsurf/mcp_config.json"
        case .amp:           return "~/.config/amp/settings.json"
        case .openCode:      return "~/.config/opencode/opencode.json"
        case .codex:         return "~/.codex/config.toml"
        }
    }
}

// MARK: - Installer

class MCPInstaller: ObservableObject {
    /// How CiceroMCP will be launched. `nil` means detection failed
    /// (neither a bundled binary nor a Package.swift could be found).
    @Published private(set) var launchSource: CiceroMCPLaunchSource?

    /// Display path shown in Settings. Empty string when detection
    /// failed (used by SettingsView to disable Install buttons and
    /// surface the warning row).
    @Published var packagePath: String

    @Published private(set) var installedAgents: Set<MCPAgent> = []
    @Published var lastError: String?

    init() {
        let source = Self.detectLaunchSource()
        self.launchSource = source
        self.packagePath = source?.displayPath ?? ""
        if source == nil {
            self.lastError = """
                Could not locate the CiceroMCP server.
                Install Cicero.app via Homebrew or run from a SwiftPM checkout.
                """
        }
        refreshStatus()
    }

    // MARK: - Launch source detection

    /// Production detection: uses `Bundle.main` and the real `FileManager`.
    /// All decision logic lives in `CiceroMCPLaunchSource.detect` (in Shared)
    /// and is independently unit-tested.
    static func detectLaunchSource() -> CiceroMCPLaunchSource? {
        let fm = FileManager.default
        return CiceroMCPLaunchSource.detect(
            bundleURL: Bundle.main.bundleURL,
            executableURL: Bundle.main.executableURL?.resolvingSymlinksInPath(),
            currentDirectoryPath: fm.currentDirectoryPath,
            fileExists: { fm.fileExists(atPath: $0.path) }
        )
    }

    // MARK: - Status

    func refreshStatus() {
        var result = Set<MCPAgent>()
        for agent in MCPAgent.allCases {
            if checkInstalled(agent) {
                result.insert(agent)
            }
        }
        installedAgents = result
    }

    private func checkInstalled(_ agent: MCPAgent) -> Bool {
        if agent.isJSON {
            guard let config = readJSON(at: agent.configURL) else { return false }
            guard let servers = config[agent.serversKey] as? [String: Any] else { return false }
            return servers["cicero"] != nil
        } else {
            guard let contents = try? String(contentsOf: agent.configURL, encoding: .utf8) else { return false }
            return contents.contains("[mcp_servers.cicero]")
        }
    }

    // MARK: - Install / Uninstall

    func install(_ agent: MCPAgent) {
        lastError = nil
        guard let source = launchSource else {
            lastError = """
                Cannot install: CiceroMCP could not be located. \
                Install Cicero.app via Homebrew or build from source.
                """
            return
        }
        do {
            if agent.isJSON {
                try installJSON(agent, source: source)
            } else {
                try installTOML(agent, source: source)
            }
            refreshStatus()
        } catch {
            lastError = "Failed to install for \(agent.displayName): \(error.localizedDescription)"
        }
    }

    func uninstall(_ agent: MCPAgent) {
        lastError = nil
        do {
            if agent.isJSON {
                try uninstallJSON(agent)
            } else {
                try uninstallTOML(agent)
            }
            refreshStatus()
        } catch {
            lastError = "Failed to uninstall for \(agent.displayName): \(error.localizedDescription)"
        }
    }

    // MARK: - JSON helpers

    private func readJSON(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func writeJSON(_ dict: [String: Any], to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: url, options: .atomic)
    }

    private func installJSON(_ agent: MCPAgent, source: CiceroMCPLaunchSource) throws {
        var config = readJSON(at: agent.configURL) ?? [:]
        var servers = (config[agent.serversKey] as? [String: Any]) ?? [:]
        servers["cicero"] = source.serverEntry(forOpenCode: agent == .openCode)
        config[agent.serversKey] = servers
        try writeJSON(config, to: agent.configURL)
    }

    private func uninstallJSON(_ agent: MCPAgent) throws {
        guard var config = readJSON(at: agent.configURL) else { return }
        guard var servers = config[agent.serversKey] as? [String: Any] else { return }
        servers.removeValue(forKey: "cicero")
        config[agent.serversKey] = servers
        try writeJSON(config, to: agent.configURL)
    }

    // MARK: - TOML helpers (Codex)

    private func installTOML(_ agent: MCPAgent, source: CiceroMCPLaunchSource) throws {
        let url = agent.configURL
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var contents = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        if contents.contains("[mcp_servers.cicero]") {
            contents = removeTOMLSection(contents, header: "[mcp_servers.cicero]")
        }
        contents += source.tomlEntry()
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func uninstallTOML(_ agent: MCPAgent) throws {
        let url = agent.configURL
        guard var contents = try? String(contentsOf: url, encoding: .utf8) else { return }
        contents = removeTOMLSection(contents, header: "[mcp_servers.cicero]")
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func removeTOMLSection(_ toml: String, header: String) -> String {
        var lines = toml.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header })
        else { return toml }
        var end = start + 1
        while end < lines.count {
            let trimmed = lines[end].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && !trimmed.isEmpty { break }
            end += 1
        }
        // Remove trailing blank lines left behind
        while start > 0 && lines[start - 1].trimmingCharacters(in: .whitespaces).isEmpty {
            lines.remove(at: start - 1)
        }
        lines.removeSubrange(start..<end)
        return lines.joined(separator: "\n")
    }
}
