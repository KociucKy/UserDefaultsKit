// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UserDefaultsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(
            name: "UserDefaultsKit",
            targets: ["UserDefaultsKit"]
        ),
        .library(
            name: "UserDefaultsKitUI",
            targets: ["UserDefaultsKitUI"]
        ),
    ],
    targets: [
        .target(
            name: "UserDefaultsKit"
        ),
        .target(
            name: "UserDefaultsKitUI",
            dependencies: ["UserDefaultsKit"]
        ),
        .testTarget(
            name: "UserDefaultsKitTests",
            dependencies: ["UserDefaultsKit"]
        ),
    ]
)
