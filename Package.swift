// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-buttons",
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
