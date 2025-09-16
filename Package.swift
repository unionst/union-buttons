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
        .package(url: "https://github.com/unionst/union-haptics.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "UnionButtons",
            dependencies: [
                .product(name: "UnionHaptics", package: "union-haptics")
            ]
        )
    ]
)
