import AppKit
import Shared
import SwiftUI

struct SettingsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var githubUsername: String?
    @Binding var isAuthenticating: Bool
    @Binding var authUserCode: String?
    @Binding var authError: String?
    var onSignIn: () -> Void
    var onSignOut: () -> Void
    @ObservedObject var updater: UpdaterController
    @ObservedObject var mcpInstaller: MCPInstaller

    // MARK: - Defaults state mirrors AppDefaults; the view writes through
    // setters below on every change.
    @State private var defaultTheme: String = AppDefaults.defaultTheme
    @State private var defaultFont: String = AppDefaults.defaultFont
    @State private var defaultExportLocation: URL? = AppDefaults.defaultExportLocation
    @State private var httpPortText: String = String(AppDefaults.httpPort)
    @State private var httpPortError: String?

    var body: some View {
        Form {
            Section {
                if isAuthenticated {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            if let username = githubUsername {
                                Text(username)
                                    .fontWeight(.medium)
                                Text("Connected to GitHub")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Connected to GitHub")
                                    .fontWeight(.medium)
                            }
                        }
                        Spacer()
                        Button("Sign Out") { onSignOut() }
                            .controlSize(.regular)
                            .accessibilityHint("Disconnects this Mac from your GitHub account")
                    }
                } else if isAuthenticating {
                    if let code = authUserCode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(code)
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Text("Enter this code on GitHub to complete sign in")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ProgressView()
                                .controlSize(.small)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Connecting to GitHub...")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GitHub")
                                .fontWeight(.medium)
                            Text("Sign in to share presentations online")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Sign In...") { onSignIn() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .accessibilityLabel("Sign in to GitHub")
                            .accessibilityHint("Starts the GitHub device-code flow in your browser")
                    }

                    if let error = authError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .accessibilityHidden(true)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                    }
                }
            } header: {
                Label("Account", systemImage: "person.circle")
            }

            Section {
                if updater.isEnabled {
                    Toggle("Automatically check for updates", isOn: $updater.automaticallyChecksForUpdates)
                    Toggle("Automatically download updates", isOn: $updater.automaticallyDownloadsUpdates)
                        .disabled(!updater.automaticallyChecksForUpdates)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check Now")
                                .fontWeight(.medium)
                            Text(lastCheckedText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Check for Updates") { updater.checkForUpdates() }
                            .controlSize(.regular)
                            .disabled(!updater.canCheckForUpdates)
                            .accessibilityHint("Asks the updater to look for a newer Cicero release")
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Updates unavailable")
                                .fontWeight(.medium)
                            Text("Automatic updates require the released app. Reinstall from the official download to enable.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }
            } header: {
                Label("Software Update", systemImage: "arrow.down.circle")
            }

            Section {
                if mcpInstaller.packagePath.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Package path not detected")
                                .fontWeight(.medium)
                            Text("Set the path to the Cicero source directory to enable MCP installation.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        Text(mcpInstaller.packagePath)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .accessibilityLabel("Package path \(mcpInstaller.packagePath)")
                    }
                }

                ForEach(MCPAgent.allCases) { agent in
                    MCPAgentRow(agent: agent, installer: mcpInstaller)
                }

                if let error = mcpInstaller.lastError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .accessibilityHidden(true)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .lineLimit(3)
                    }
                }
            } header: {
                Label("MCP Server", systemImage: "server.rack")
            } footer: {
                Text("Install the Cicero MCP server for your AI coding agents. Restart the agent after installing.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            defaultsSection
        }
        .formStyle(.grouped)
        .frame(width: SettingsLayout.width, height: SettingsLayout.maxHeight)
    }

    // MARK: - Defaults section

    private var defaultsSection: some View {
        Section {
            Picker("Default theme", selection: $defaultTheme) {
                ForEach(AppDefaultsValidator.themeOptions(), id: \.self) { name in
                    Text(themeDisplayName(name)).tag(name)
                }
            }
            .onChange(of: defaultTheme) { _, newValue in
                AppDefaults.defaultTheme = newValue
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Default export location")
                        .fontWeight(.medium)
                    Text(defaultExportLocation?.path ?? "~/Documents")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibilityLabel("Current export location: \(defaultExportLocation?.path ?? "Documents folder")")
                }
                Spacer()
                if defaultExportLocation != nil {
                    Button("Clear") {
                        defaultExportLocation = nil
                        AppDefaults.defaultExportLocation = nil
                    }
                    .controlSize(.small)
                    .accessibilityLabel("Clear export location")
                    .accessibilityHint("Resets the default export location to the Documents folder")
                }
                Button("Browse...") { browseForExportLocation() }
                    .controlSize(.small)
                    .accessibilityLabel("Browse for export location")
                    .accessibilityHint("Opens a folder picker to choose where exports are saved")
            }

            Picker("Default font", selection: $defaultFont) {
                ForEach(CuratedFonts.all, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .onChange(of: defaultFont) { _, newValue in
                AppDefaults.defaultFont = newValue
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("HTTP port")
                    Spacer()
                    TextField("Port", text: $httpPortText)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onSubmit { commitPort() }
                        .onChange(of: httpPortText) { _, _ in
                            // Validate as the user types so we can show feedback,
                            // but only persist on submit/blur via commitPort().
                            validatePortInput()
                        }
                        .accessibilityLabel("HTTP port")
                        .accessibilityHint("Sets the loopback port the Cicero HTTP API listens on. Requires restart.")
                }
                if let httpPortError {
                    Text(httpPortError)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Restart Cicero for port changes to take effect.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("Defaults", systemImage: "slider.horizontal.3")
        } footer: {
            Text("These defaults apply to new presentations. Existing files keep their saved theme and font.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        // TODO: keyboard shortcut customization (future)
    }

    private func themeDisplayName(_ name: String) -> String {
        if name == "auto" { return "Auto (system)" }
        return name.capitalized
    }

    private func browseForExportLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        if let current = defaultExportLocation {
            panel.directoryURL = current
        }
        if panel.runModal() == .OK, let url = panel.url {
            defaultExportLocation = url
            AppDefaults.defaultExportLocation = url
        }
    }

    private func validatePortInput() {
        guard let value = Int(httpPortText.trimmingCharacters(in: .whitespaces)) else {
            httpPortError = "Enter a number between \(AppDefaultsValidator.minPort) and \(AppDefaultsValidator.maxPort)."
            return
        }
        if AppDefaultsValidator.isValidPort(value) {
            httpPortError = nil
        } else {
            httpPortError = "Port must be between \(AppDefaultsValidator.minPort) and \(AppDefaultsValidator.maxPort)."
        }
    }

    private func commitPort() {
        guard let value = Int(httpPortText.trimmingCharacters(in: .whitespaces)),
              AppDefaultsValidator.isValidPort(value)
        else {
            // Reset the field to the last persisted value.
            httpPortText = String(AppDefaults.httpPort)
            httpPortError = nil
            return
        }
        AppDefaults.httpPort = value
        httpPortError = nil
    }

    private var lastCheckedText: String {
        guard let date = updater.lastUpdateCheckDate else {
            return "Has not checked yet"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last checked \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - MCP agent row

private struct MCPAgentRow: View {
    let agent: MCPAgent
    @ObservedObject var installer: MCPInstaller

    private var isInstalled: Bool { installer.installedAgents.contains(agent) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: agent.iconName)
                .frame(width: 20)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(agent.displayName)
                    .fontWeight(.medium)
                Text(agent.configDescription)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("Installed")
                Button("Remove") { installer.uninstall(agent) }
                    .controlSize(.small)
                    .accessibilityLabel("Remove \(agent.displayName) integration")
                    .accessibilityHint("Uninstalls the Cicero MCP server from this agent")
            } else {
                Button("Install") { installer.install(agent) }
                    .controlSize(.small)
                    .disabled(installer.packagePath.isEmpty)
                    .accessibilityLabel("Install \(agent.displayName) integration")
                    .accessibilityHint("Installs the Cicero MCP server for this agent")
            }
        }
    }
}
