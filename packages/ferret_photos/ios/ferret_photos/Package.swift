// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ferret_photos",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ferret-photos", targets: ["ferret_photos"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ferret_photos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
