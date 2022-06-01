// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ergo",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_10),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "Ergo",
            targets: ["Ergo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/hainayanda/Chary.git", from: "1.0.1"),
        .package(url: "https://github.com/Quick/Quick.git", from: "5.0.1"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "Ergo",
            dependencies: ["Chary"],
            path: "Ergo/Classes"
        ),
        .testTarget(
            name: "ErgoTests",
            dependencies: [
                "Ergo", "Quick", "Nimble"
            ],
            path: "Example/Tests",
            exclude: ["Info.plist"]
        )
    ]
)
