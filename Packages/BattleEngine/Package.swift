// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BattleEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BattleEngine", targets: ["BattleEngine"])
    ],
    targets: [
        .target(name: "BattleEngine"),
        .testTarget(name: "BattleEngineTests", dependencies: ["BattleEngine"])
    ]
)
