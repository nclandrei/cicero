import Foundation
import Security

final class GistService {
    static let shared = GistService()
    private static let keychainService = "com.andreinicolas.Cicero.github"

    // MARK: - Keychain

    func storeToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: "github_token",
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "GistService", code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "Failed to store token in Keychain"])
        }
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: "github_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: "github_token",
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - API

    func publish(
        filename: String,
        content: String,
        description: String,
        isPublic: Bool,
        existingGistId: String?
    ) async throws -> (gistId: String, url: String) {
        guard let token = getToken() else {
            throw GistError.noToken
        }

        let body: [String: Any] = [
            "description": description,
            "public": isPublic,
            "files": [filename: ["content": content]],
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let apiURL: URL
        let method: String
        if let gistId = existingGistId {
            apiURL = URL(string: "https://api.github.com/gists/\(gistId)")!
            method = "PATCH"
        } else {
            apiURL = URL(string: "https://api.github.com/gists")!
            method = "POST"
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = method
        request.httpBody = jsonData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GistError.apiError(msg)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let gistId = json["id"] as? String,
              let htmlURL = json["html_url"] as? String
        else {
            throw GistError.invalidResponse
        }

        return (gistId, htmlURL)
    }
}

enum GistError: LocalizedError {
    case noToken
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noToken: return "No GitHub token configured. Add one in Cicero preferences."
        case .apiError(let msg): return "GitHub API error: \(msg)"
        case .invalidResponse: return "Invalid response from GitHub API"
        }
    }
}
