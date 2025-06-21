// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-buttons",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionButtons",
            targets: ["UnionButtons"]
        )
    ],
    dependencies: [
        .package(path: "../union-haptics")
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
