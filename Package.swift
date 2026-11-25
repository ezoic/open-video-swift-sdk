// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenVideo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "OpenVideoCore", targets: ["OpenVideoCore"]),
        .library(name: "OpenVideo", targets: ["OpenVideo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ezoic/ezoic-swift-sdk-dist.git", .upToNextMinor(from: "1.26.0")),
        // Preserve the supported Google IMA range.
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
            "3.23.0"..<"3.28.0"
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
                .product(name: "EzoicAdsSDK", package: "ezoic-swift-sdk-dist"),
                .product(
                    name: "GoogleInteractiveMediaAds",
                    package: "swift-package-manager-google-interactive-media-ads-ios"
                ),
            ],
            path: "Sources/OpenVideo",
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "OpenVideoCoreTests",
            dependencies: ["OpenVideoCore"],
            path: "Tests/OpenVideoCoreTests"
        ),
        .testTarget(
            name: "OpenVideoTests",
            dependencies: ["OpenVideo"],
            path: "Tests/OpenVideoTests"
        ),
    ]
)
