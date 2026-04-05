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

    var body: some View {
        Form {
            Section {
                if isAuthenticated {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
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
                    }

                    if let error = authError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
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
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
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
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
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
