// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-buttons",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "UnionButtons",
            targets: ["UnionButtons"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/unionst/union-haptics.git", .upToNextMajor(from: "1.2.1")),
        .package(url: "https://github.com/unionst/union-gestures.git", .upToNextMajor(from: "1.0.1"))
    ],
    targets: [
        .target(
            name: "UnionButtons",
            dependencies: [
                .product(name: "UnionHaptics", package: "union-haptics"),
                .product(name: "UnionGestures", package: "union-gestures")
            ]
        )
    ]
)
