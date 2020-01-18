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
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "XPCCombine",
            dependencies: []),
        .testTarget(
            name: "XPCCombineTests",
            dependencies: ["XPCCombine"]),
    ]
)
