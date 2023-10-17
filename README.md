# streann-inside-ad-sdk-ios

This is an adds support for Swift Package to the Google Interactive Media Ads (IMA) SDK.

## Current supported version:

iOS: `14.0`

## Getting Started

### Swift Package Manager

To use this SwiftUI Package in your Xcode project, follow these steps:

1. Open your project in Xcode.
2. Go to File > Swift Packages > Add Package Dependency.
3. Enter the URL of this repository https://github.com/streannsdk/streann-inside-ad-sdk-ios.git and click Next.
4. Choose the "main" from the Dependency rule and click Next.
5. Select the target you want to add the package to and click Finish.
6. Import the streann-inside-ad-sdk-ios module in your SwiftUI App where you want to use the streann-inside-ad-sdk-ios SDK:
    ```Swift
    import streann_inside_ad_sdk_ios
    ```
7. Initialize the SDK with the baseUrl and apiKey in the main Scene:
    ```Swift
    ...
        ContentView()
            .onAppear {
                StreannInsideAdSdk.initializeSdk(baseUrl: "some base url", apiKey: "some api key")
            }
        ...
    ```
8. In the view where the the Ad will be presented import the streann-inside-ad-sdk-ios module:
    ```Swift
    import streann_inside_ad_sdk_ios
    ```
9. Create a State String property to receive the insideAd callbacks:
    ```Swift
    @State var insideAdCallback = ""
    ```
10. Insert the screenName as a parameter and request the ad in the view body:
    ```Swift
        var body: some View {
            insideAd.requestAd(screen: "", insideAdCallback: $insideAdCallback)
        }        
    ```
