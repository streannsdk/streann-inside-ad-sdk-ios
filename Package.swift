// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let googleMobileAdsAlias = "GoogleMobileAdsAlias"

let package = Package(
    name: "streann-inside-ad-sdk-ios",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "streann-inside-ad-sdk-ios",
            targets: ["streann-inside-ad-sdk-ios", "GoogleInteractiveMediaAds", googleMobileAdsAlias]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    targets: [
        .binaryTarget(
            name: "GoogleInteractiveMediaAds",
            path: "./Resources/GoogleInteractiveMediaAds.zip"
        ),
        .binaryTarget(
                    name: googleMobileAdsAlias,
                    path: "./Resources/GoogleMobileAds.zip"
                ),
        .target(
            name: "streann-inside-ad-sdk-ios",
            dependencies: [
                "Alamofire"
            ],
            path: "./Sources/",
            resources: [.process("streann-inside-ad-sdk-ios.xcassets")]
        ),
//        .testTarget(
//            name: "InsideAdsSDKTests",
//            dependencies: ["streann-inside-ad-sdk-ios", "GoogleInteractiveMediaAds"],
//            resources: []),
    ]
)
