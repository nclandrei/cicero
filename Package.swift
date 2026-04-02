// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cicero",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Cicero", targets: ["Cicero"]),
        .executable(name: "CiceroMCP", targets: ["CiceroMCP"]),
        .executable(name: "Proctor", targets: ["Proctor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0"),
        .package(url: "https://github.com/httpswift/swifter", from: "1.5.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "Shared",
            dependencies: [],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Cicero",
            dependencies: [
                "Shared",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Splash", package: "Splash"),
                .product(name: "Swifter", package: "swifter"),
            ],
            resources: [
                .copy("Resources/AppIcon.icns"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Proctor",
            dependencies: ["Shared"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "CiceroMCP",
            dependencies: [
                "Shared",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CiceroTests",
            dependencies: ["Shared"],
            resources: [
                .copy("Resources/AppIcon.icns"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MCPIntegrationTests",
            dependencies: [
                "Shared",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
