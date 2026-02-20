// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BattleCalc",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BattleCalc", targets: ["BattleCalc"]),
    ],
    dependencies: [
        .package(name: "TI4Data", path: "../TI4Data"),
    ],
    targets: [
        .target(
            name: "BattleCalc",
            dependencies: ["TI4Data"]
        ),
        .testTarget(
            name: "BattleCalcTests",
            dependencies: ["BattleCalc"]
        ),
    ]
)
