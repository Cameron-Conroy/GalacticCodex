// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Chronicle",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Chronicle", targets: ["Chronicle"]),
    ],
    dependencies: [
        .package(name: "TI4Data", path: "../TI4Data"),
        .package(name: "ClaudeAPI", path: "../ClaudeAPI"),
    ],
    targets: [
        .target(
            name: "Chronicle",
            dependencies: ["TI4Data", "ClaudeAPI"]
        ),
        .testTarget(
            name: "ChronicleTests",
            dependencies: ["Chronicle"]
        ),
    ]
)
