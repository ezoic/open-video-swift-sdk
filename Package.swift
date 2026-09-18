// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenVideo",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "OpenVideoCore", targets: ["OpenVideoCore"]),
        .library(name: "OpenVideo", targets: ["OpenVideo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ezoic/ezoic-swift-sdk.git", from: "1.10.1"),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
            from: "3.23.0"
        ),
    ],
    targets: [
        .target(
            name: "OpenVideoCore",
            path: "Sources/OpenVideoCore"
        ),
        .target(
            name: "OpenVideo",
            dependencies: [
                "OpenVideoCore",
                .product(name: "EzoicAdsSDK", package: "ezoic-swift-sdk"),
                .product(
                    name: "GoogleInteractiveMediaAds",
                    package: "swift-package-manager-google-interactive-media-ads-ios"
                ),
            ],
            path: "Sources/OpenVideo"
        ),
        .testTarget(
            name: "OpenVideoCoreTests",
            dependencies: ["OpenVideoCore"],
            path: "Tests/OpenVideoCoreTests"
        ),
    ]
)
