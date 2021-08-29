// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tactile",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Tactile",
            targets: ["Tactile"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(name: "Tactile")
    ]
)
