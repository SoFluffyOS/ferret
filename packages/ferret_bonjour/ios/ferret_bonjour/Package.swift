// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ferret_bonjour",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ferret-bonjour", targets: ["ferret_bonjour"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ferret_bonjour",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
