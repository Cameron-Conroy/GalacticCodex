// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Advisor",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Advisor", targets: ["Advisor"]),
    ],
    dependencies: [
        .package(name: "TI4Data", path: "../TI4Data"),
        .package(name: "ClaudeAPI", path: "../ClaudeAPI"),
    ],
    targets: [
        .target(
            name: "Advisor",
            dependencies: ["TI4Data", "ClaudeAPI"]
        ),
        .testTarget(
            name: "AdvisorTests",
            dependencies: ["Advisor"]
        ),
    ]
)
