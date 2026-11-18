// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ferret_handoff",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ferret-handoff", targets: ["ferret_handoff"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ferret_handoff",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
