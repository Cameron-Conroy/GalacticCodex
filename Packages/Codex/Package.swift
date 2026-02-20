// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Codex",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Codex", targets: ["Codex"]),
    ],
    dependencies: [
        .package(name: "TI4Data", path: "../TI4Data"),
    ],
    targets: [
        .target(
            name: "Codex",
            dependencies: ["TI4Data"]
        ),
        .testTarget(
            name: "CodexTests",
            dependencies: ["Codex"]
        ),
    ]
)
