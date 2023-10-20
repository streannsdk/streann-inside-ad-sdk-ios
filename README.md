# streann-inside-ad-sdk-ios

This is an adds support for SwiftUI Package to the Google Interactive Media Ads (IMA) SDK.

## Current supported version:

iOS: `14.0`

## Getting Started

### streann-inside-ad-sdk-ios SwiftUI Package Manager

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
7. Initialize the SDK with the baseUrl and apiKey in the main Scene. The both parameters are mandatory. Read the StreannInsideAdSDK log in the console for errors:
    ```Swift
    ...
        ContentView()
            .onAppear {
                StreannInsideAdSdk.initializeSdk(baseUrl: "some base url", apiKey: "some api key")
            }
    ...
    ```
    You could also implement the optional parameters:
    ```Swift
    siteUrl: String, 
    storeUrl: String, 
    descriptionUrl: String, 
    userBirthYear: Int64, 
    userGender: UserGender(Enum)
    ```
    
8. In the view where the the Ad will be presented import the streann-inside-ad-sdk-ios module:
    ```Swift
    import streann_inside_ad_sdk_ios
    ```
9. Create an instance of the streann-inside-ad-sdk-ios module:
    ```Swift
    var streannInsideAdSdk  = StreannInsideAdSdk()
    ```
10. Create a State String property to receive the insideAd status callbacks (errors and ad player's state'):
    ```Swift
    @State var insideAdCallback = ""
    ```
    Callbacks:
    ```Swift
    "StreannInsideAdSDK: Started"
    "StreannInsideAdSDK: Loaded"
    "StreannInsideAdSDK: Started First Quartile"
    "StreannInsideAdSDK: Midpoint"
    "StreannInsideAdSDK: Third Quartile"
    "StreannInsideAdSDK: Complete"
    "StreannInsideAdSDK: All Ads Completed"
    "StreannInsideAdSDK: The VAST response document is empty"
    ```    
11. Insert the screenName (e.g. "Launch") as a parameter and request the ad in the view body. This will return a view:
    ```Swift
    var body: some View {
        streannInsideAdSdk.requestAd(screen: "Launch", insideAdCallback: $insideAdCallback)
    }        
    ```
