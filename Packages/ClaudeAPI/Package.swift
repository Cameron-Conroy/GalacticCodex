// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeAPI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ClaudeAPI", targets: ["ClaudeAPI"]),
    ],
    targets: [
        .target(name: "ClaudeAPI"),
        .testTarget(
            name: "ClaudeAPITests",
            dependencies: ["ClaudeAPI"]
        ),
    ]
)
