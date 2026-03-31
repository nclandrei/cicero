import Foundation

final class GistService {
    static let shared = GistService()

    func publish(
        token: String,
        filename: String,
        content: String,
        description: String,
        isPublic: Bool,
        existingGistId: String?
    ) async throws -> (gistId: String, url: String) {
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
        case .noToken: return "Not signed in to GitHub. Sign in via Settings (Cmd+,)."
        case .apiError(let msg): return "GitHub API error: \(msg)"
        case .invalidResponse: return "Invalid response from GitHub API"
        }
    }
}
