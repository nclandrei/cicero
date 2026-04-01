import Foundation

/// A lightweight MCP client that communicates with CiceroMCP over stdin/stdout pipes.
/// Uses the MCP JSON-RPC 2.0 protocol with newline-delimited JSON messages.
final class MCPTestClient {
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var outputBuffer = Data()
    private var nextID = 1

    /// Launch the CiceroMCP binary as a subprocess.
    func start() throws {
        let binaryPath = Self.findBinary()
        guard FileManager.default.fileExists(atPath: binaryPath) else {
            throw MCPTestError.binaryNotFound(binaryPath)
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardInput = stdin
        proc.standardOutput = stdout
        proc.standardError = stderr

        try proc.run()

        self.process = proc
        self.stdinPipe = stdin
        self.stdoutPipe = stdout
        self.stderrPipe = stderr
    }

    /// Send a JSON-RPC request and read the response.
    func sendRequest(method: String, params: [String: Any]? = nil) throws -> [String: Any] {
        let id = nextID
        nextID += 1

        var message: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
        ]
        if let params = params {
            message["params"] = params
        } else {
            message["params"] = [String: Any]()
        }

        try sendJSON(message)
        return try readResponse(expectedID: id)
    }

    /// Send a JSON-RPC notification (no response expected).
    func sendNotification(method: String, params: [String: Any]? = nil) throws {
        var message: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
        ]
        if let params = params {
            message["params"] = params
        } else {
            message["params"] = [String: Any]()
        }

        try sendJSON(message)
    }

    /// Perform the MCP handshake (initialize + initialized notification).
    func handshake() throws -> [String: Any] {
        let result = try sendRequest(method: "initialize", params: [
            "protocolVersion": "2024-11-05",
            "capabilities": [String: Any](),
            "clientInfo": [
                "name": "MCPIntegrationTests",
                "version": "1.0.0",
            ],
        ])
        try sendNotification(method: "notifications/initialized")
        return result
    }

    /// Call an MCP tool by name.
    func callTool(name: String, arguments: [String: Any] = [:]) throws -> [String: Any] {
        return try sendRequest(method: "tools/call", params: [
            "name": name,
            "arguments": arguments,
        ])
    }

    /// List all available tools.
    func listTools() throws -> [[String: Any]] {
        let response = try sendRequest(method: "tools/list")
        guard let result = response["result"] as? [String: Any],
              let tools = result["tools"] as? [[String: Any]]
        else {
            throw MCPTestError.unexpectedResponse("Missing tools in response")
        }
        return tools
    }

    /// Extract text content from a tools/call result.
    func extractText(from response: [String: Any]) throws -> String {
        guard let result = response["result"] as? [String: Any],
              let content = result["content"] as? [[String: Any]]
        else {
            if let error = response["error"] as? [String: Any] {
                let msg = error["message"] as? String ?? "unknown error"
                throw MCPTestError.serverError(msg)
            }
            throw MCPTestError.unexpectedResponse("Missing content in response")
        }
        let texts = content.compactMap { item -> String? in
            guard (item["type"] as? String) == "text" else { return nil }
            return item["text"] as? String
        }
        return texts.joined(separator: "\n")
    }

    /// Check if a response contains image content.
    func hasImageContent(in response: [String: Any]) -> Bool {
        guard let result = response["result"] as? [String: Any],
              let content = result["content"] as? [[String: Any]]
        else { return false }
        return content.contains { ($0["type"] as? String) == "image" }
    }

    /// Count content items in a response.
    func contentCount(in response: [String: Any]) -> Int {
        guard let result = response["result"] as? [String: Any],
              let content = result["content"] as? [[String: Any]]
        else { return 0 }
        return content.count
    }

    /// Check if the response indicates an error.
    func isErrorResult(_ response: [String: Any]) -> Bool {
        if response["error"] != nil { return true }
        guard let result = response["result"] as? [String: Any] else { return false }
        return (result["isError"] as? Bool) == true
    }

    /// Terminate the CiceroMCP process.
    func stop() {
        stdinPipe?.fileHandleForWriting.closeFile()
        process?.terminate()
        process?.waitUntilExit()
        process = nil
    }

    // MARK: - Private

    private func sendJSON(_ object: [String: Any]) throws {
        guard let pipe = stdinPipe else {
            throw MCPTestError.notStarted
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        var line = data
        line.append(contentsOf: [0x0A]) // newline
        pipe.fileHandleForWriting.write(line)
    }

    private func readResponse(expectedID: Int, timeout: TimeInterval = 30) throws -> [String: Any] {
        guard let pipe = stdoutPipe else {
            throw MCPTestError.notStarted
        }

        let deadline = Date().addingTimeInterval(timeout)
        let handle = pipe.fileHandleForReading

        while Date() < deadline {
            // Check for complete lines in the buffer
            if let newlineRange = outputBuffer.range(of: Data([0x0A])) {
                let lineData = outputBuffer.subdata(in: outputBuffer.startIndex..<newlineRange.lowerBound)
                outputBuffer.removeSubrange(outputBuffer.startIndex...newlineRange.lowerBound)

                // Skip empty lines
                guard !lineData.isEmpty else { continue }

                guard let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                    continue
                }

                // Skip notifications (no id field) — server may emit log notifications
                guard let responseID = json["id"] as? Int else { continue }

                if responseID == expectedID {
                    return json
                }
                // Unexpected ID — keep reading
                continue
            }

            // Read more data
            let available = handle.availableData
            if available.isEmpty {
                // EOF — process might have crashed
                if let proc = process, !proc.isRunning {
                    throw MCPTestError.processCrashed(proc.terminationStatus)
                }
                Thread.sleep(forTimeInterval: 0.05)
            } else {
                outputBuffer.append(available)
            }
        }

        throw MCPTestError.timeout
    }

    private static func findBinary() -> String {
        // Check for the binary in the build directory
        let packageDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
        let debugPath = packageDir + "/.build/debug/CiceroMCP"
        if FileManager.default.fileExists(atPath: debugPath) {
            return debugPath
        }
        // Fallback: try common build paths
        let fallback = FileManager.default.currentDirectoryPath + "/.build/debug/CiceroMCP"
        return fallback
    }
}

// MARK: - Check if Cicero app is running

extension MCPTestClient {
    /// Check if the Cicero app HTTP server is reachable.
    static func isCiceroAppRunning() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isRunning = false

        guard let url = URL(string: "http://localhost:19847/status") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                isRunning = true
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 3)
        return isRunning
    }
}

// MARK: - Errors

enum MCPTestError: Error, CustomStringConvertible {
    case binaryNotFound(String)
    case notStarted
    case timeout
    case processCrashed(Int32)
    case unexpectedResponse(String)
    case serverError(String)

    var description: String {
        switch self {
        case .binaryNotFound(let path): return "CiceroMCP binary not found at \(path)"
        case .notStarted: return "MCPTestClient not started"
        case .timeout: return "Timeout waiting for response"
        case .processCrashed(let code): return "CiceroMCP process crashed with code \(code)"
        case .unexpectedResponse(let msg): return "Unexpected response: \(msg)"
        case .serverError(let msg): return "Server error: \(msg)"
        }
    }
}
