import Foundation

actor GitHubAuth {
    private let clientId: String

    private(set) var token: String?
    private(set) var username: String?

    init(clientId: String) {
        self.clientId = clientId
    }

    var isAuthenticated: Bool { token != nil }

    // MARK: - Device Flow

    struct DeviceCode {
        let deviceCode: String
        let userCode: String
        let verificationURI: String
        let interval: Int
        let expiresIn: Int
    }

    func requestDeviceCode() async throws -> DeviceCode {
        var request = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["client_id": clientId, "scope": "gist"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.deviceCodeRequestFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceCode = json["device_code"] as? String,
              let userCode = json["user_code"] as? String,
              let verificationURI = json["verification_uri"] as? String else {
            throw AuthError.invalidResponse
        }

        return DeviceCode(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURI: verificationURI,
            interval: (json["interval"] as? Int) ?? 5,
            expiresIn: (json["expires_in"] as? Int) ?? 900
        )
    }

    func pollForToken(deviceCode: DeviceCode) async throws -> String {
        let deadline = Date().addingTimeInterval(TimeInterval(deviceCode.expiresIn))
        let interval = UInt64(max(deviceCode.interval, 5)) * 1_000_000_000

        while Date() < deadline {
            try await Task.sleep(nanoseconds: interval)

            let result = try await checkAuthorization(deviceCode: deviceCode.deviceCode)
            switch result {
            case .success(let accessToken):
                self.token = accessToken
                saveTokenToFile(accessToken)
                self.username = try? await fetchUsername(token: accessToken)
                return accessToken
            case .pending:
                continue
            case .slowDown:
                try await Task.sleep(nanoseconds: 5_000_000_000)
                continue
            case .expired:
                throw AuthError.codeExpired
            case .denied:
                throw AuthError.accessDenied
            }
        }

        throw AuthError.codeExpired
    }

    func restoreSession() async {
        if self.token == nil {
            self.token = Self.loadTokenFromFile()
        }
        guard let token = self.token else { return }
        self.username = try? await fetchUsername(token: token)
    }

    func signOut() {
        token = nil
        username = nil
        deleteTokenFromFile()
    }

    // MARK: - Token Check

    private enum PollResult {
        case success(String)
        case pending
        case slowDown
        case expired
        case denied
    }

    private func checkAuthorization(deviceCode: String) async throws -> PollResult {
        var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": clientId,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }

        if let accessToken = json["access_token"] as? String {
            return .success(accessToken)
        }

        if let error = json["error"] as? String {
            switch error {
            case "authorization_pending": return .pending
            case "slow_down": return .slowDown
            case "expired_token": return .expired
            case "access_denied": return .denied
            default: throw AuthError.unknownError(error)
            }
        }

        throw AuthError.invalidResponse
    }

    private func fetchUsername(token: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("Cicero", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let login = json["login"] as? String else {
            throw AuthError.invalidResponse
        }

        return login
    }

    // MARK: - File storage
    //
    // Token is stored at ~/Library/Application Support/Cicero/github-token
    // with 0600 perms. Mirrors the approach used by `gh` CLI.
    // Chose this over Keychain because SecItem ACLs are tied to code signatures,
    // and debug rebuilds produced constantly-changing signatures → repeated prompts.

    private static func tokenFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Cicero", isDirectory: true).appendingPathComponent("github-token")
    }

    private static func loadTokenFromFile() -> String? {
        let url = tokenFileURL()
        guard let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveTokenToFile(_ token: String) {
        let url = Self.tokenFileURL()
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = token.data(using: .utf8) else { return }
        try? data.write(to: url, options: [.atomic])
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func deleteTokenFromFile() {
        try? FileManager.default.removeItem(at: Self.tokenFileURL())
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case deviceCodeRequestFailed
    case invalidResponse
    case codeExpired
    case accessDenied
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .deviceCodeRequestFailed: return "Failed to request device code from GitHub"
        case .invalidResponse: return "Invalid response from GitHub"
        case .codeExpired: return "Authorization code expired. Please try again."
        case .accessDenied: return "Access was denied"
        case .unknownError(let msg): return "GitHub error: \(msg)"
        }
    }
}
