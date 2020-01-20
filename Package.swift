// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "XPCCombine",
    products: [
        .library(
            name: "XPCCombine",
            targets: ["XPCCombine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cx-org/CombineX", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "XPCCombine",
            dependencies: ["CXShim"]),
        .testTarget(
            name: "XPCCombineTests",
            dependencies: ["XPCCombine"]),
    ]
)
