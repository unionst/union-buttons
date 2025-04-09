// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-buttons",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "UnionButtons",
            targets: ["UnionButtons"]
        ),
    ],
    targets: [
        .target(
            name: "UnionButtons"
        ),
    ]
)
