// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenWebUIApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenWebUIApp", targets: ["OpenWebUIApp"])
    ],
    targets: [
        .executableTarget(
            name: "OpenWebUIApp",
            path: "Sources"
        )
    ]
)
