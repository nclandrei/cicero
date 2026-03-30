import Foundation
import Shared

/// HTTP client that communicates with the running Cicero app
actor AppClient {
    private let baseURL: String

    init(baseURL: String = CiceroConstants.httpBaseURL) {
        self.baseURL = baseURL
    }

    // MARK: - Generic request helpers

    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request("POST", path: path, body: body)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request("PUT", path: path, body: body)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func postEmpty<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Private

    private func request<B: Encodable, T: Decodable>(
        _ method: String, path: String, body: B
    ) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = try JSONEncoder().encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppClientError.notHTTP
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppClientError.httpError(http.statusCode, body)
        }
    }
}

enum AppClientError: LocalizedError {
    case notHTTP
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notHTTP:
            return "Response was not HTTP"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}
