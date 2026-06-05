// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "three-blind-mice-app",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "three-blind-mice-app"
        ),
        .testTarget(
            name: "three-blind-mice-appTests",
            dependencies: ["three-blind-mice-app"]
        ),
    ]
)
