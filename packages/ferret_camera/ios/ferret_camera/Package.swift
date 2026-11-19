// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ferret_camera",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ferret-camera", targets: ["ferret_camera"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ferret_camera",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
