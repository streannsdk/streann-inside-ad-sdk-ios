// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "streann-inside-ad-sdk-ios",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "streann-inside-ad-sdk-ios",
            targets: ["streann-inside-ad-sdk-ios", "GoogleInteractiveMediaAds"]),
    ],
    targets: [
        .binaryTarget(
            name: "GoogleInteractiveMediaAds",
            path: "./Resources/GoogleInteractiveMediaAds.zip"
        ),
        .target(
            name: "streann-inside-ad-sdk-ios",
            dependencies: [],
            path: "./Sources/",
            resources: []
        ),
//        .testTarget(
//            name: "InsideAdsSDKTests",
//            dependencies: ["streann-inside-ad-sdk-ios", "GoogleInteractiveMediaAds"],
//            resources: []),
    ]
)
