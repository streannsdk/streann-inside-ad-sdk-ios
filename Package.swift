// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let googleMobileAdsAlias = "GoogleMobileAdsAlias"

let package = Package(
    name: "streann-inside-ad-sdk-ios",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
    ],
    products: [
        // Products can't carry platform conditions, so the binary targets are declared as
        // conditional dependencies of the main target instead of being listed here.
        // GoogleMobileAds ships no tvOS slice; GoogleInteractiveMediaAds does.
        .library(
            name: "streann-inside-ad-sdk-ios",
            targets: ["streann-inside-ad-sdk-ios"]),
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
                "Alamofire",
                .target(name: "GoogleInteractiveMediaAds"),
                .target(name: googleMobileAdsAlias, condition: .when(platforms: [.iOS])),
            ],
            path: "./Sources/",
            // iOS-only xib: ibtool refuses to build it for tvOS. It is loaded from
            // Bundle.main (the host app), never from the package bundle, so excluding it
            // from the build changes nothing at runtime — see GADNativeViewController.
            exclude: ["Files/SDK/View/NativeAdView/NativeAdView.xib"],
            resources: [.process("streann-inside-ad-sdk-ios.xcassets")]
        ),
    ]
)
