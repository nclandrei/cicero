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
        VStack(alignment: .leading, spacing: 14) {
            // GitHub Account
            VStack(alignment: .leading, spacing: 6) {
                Text("GitHub")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        if let username = githubUsername {
                            Text("Signed in as \(username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Signed in")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Sign Out") { onSignOut() }
                            .font(.subheadline)
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                    }
                } else if isAuthenticating {
                    if let code = authUserCode {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(code)
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Text("Enter this code on GitHub")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ProgressView()
                                .controlSize(.small)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Connecting to GitHub...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        if let error = authError {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button("Sign in with GitHub") { onSignIn() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 360)
    }
}
