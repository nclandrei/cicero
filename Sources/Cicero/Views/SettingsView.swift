import SwiftUI

struct SettingsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var githubUsername: String?
    @Binding var isAuthenticating: Bool
    @Binding var authUserCode: String?
    @Binding var authError: String?
    var onSignIn: () -> Void
    var onSignOut: () -> Void

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
                            Text("Sign in to publish presentations as Gists")
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
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 180)
    }
}
