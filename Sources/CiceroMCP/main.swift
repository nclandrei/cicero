import Foundation
import MCP

let server = Server(
    name: "cicero",
    version: "1.0.0",
    capabilities: .init(tools: .init(listChanged: false))
)

let appClient = AppClient()

await server.withMethodHandler(ListTools.self) { _ in
    .init(tools: CiceroTools.all)
}

await server.withMethodHandler(CallTool.self) { params in
    do {
        return try await CiceroToolHandler.handle(
            name: params.name,
            arguments: params.arguments,
            client: appClient
        )
    } catch {
        return .init(
            content: [.text(
                text: "Error: \(error.localizedDescription). Is the Cicero app running?",
                annotations: nil,
                _meta: nil
            )],
            isError: true
        )
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
