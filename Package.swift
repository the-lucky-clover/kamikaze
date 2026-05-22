// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Kamikaze",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "KamikazeCore", targets: ["KamikazeCore"]),
        .library(name: "KamikazeGame", targets: ["KamikazeGame"]),
        .library(name: "Kamikaze", targets: ["Kamikaze"])
    ],
    targets: [
        .target(name: "KamikazeCore"),
        .target(name: "KamikazeGame", dependencies: ["KamikazeCore"]),
        .target(name: "Kamikaze", dependencies: ["KamikazeCore", "KamikazeGame"]),
        .testTarget(name: "KamikazeGameTests", dependencies: ["KamikazeGame", "KamikazeCore"])
    ],
    swiftLanguageModes: [.v6]
)
