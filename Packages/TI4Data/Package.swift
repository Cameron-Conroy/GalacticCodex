// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TI4Data",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TI4Data", targets: ["TI4Data"]),
    ],
    targets: [
        .target(
            name: "TI4Data",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TI4DataTests",
            dependencies: ["TI4Data"]
        ),
    ]
)
