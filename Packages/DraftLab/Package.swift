// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DraftLab",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DraftLab", targets: ["DraftLab"]),
    ],
    dependencies: [
        .package(name: "TI4Data", path: "../TI4Data"),
    ],
    targets: [
        .target(
            name: "DraftLab",
            dependencies: ["TI4Data"]
        ),
        .testTarget(
            name: "DraftLabTests",
            dependencies: ["DraftLab"]
        ),
    ]
)
