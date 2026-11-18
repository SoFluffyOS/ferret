// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ferret_system",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "ferret-system", targets: ["ferret_system"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ferret_system",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
