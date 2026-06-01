// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MyStudyDen",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MyStudyDenCore",
            targets: ["MyStudyDenCore"]
        )
    ],
    targets: [
        .target(
            name: "MyStudyDenCore"
        ),
        .testTarget(
            name: "MyStudyDenCoreTests",
            dependencies: ["MyStudyDenCore"]
        )
    ]
)

