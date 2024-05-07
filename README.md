# streann-inside-ad-sdk-ios

This is an adds support for SwiftUI Package to the Google Interactive Media Ads (IMA) SDK.

## Current supported version:

iOS: `15.0`

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
7. Initialize the SDK with the baseUrl, apiKey and apiToken in the main Scene or AppDelegate. These parameters are mandatory:
    ```Swift
    _ = InsideAdSdk.init(baseUrl: "some base url", apiKey: "some api key")
    ```
8. Update your app's Info.plist file to add two keys:
    1. GADApplicationIdentifier key with a string value of your AdMob app ID found in the AdMob UI.
    2. SKAdNetworkItems key with SKAdNetworkIdentifier values for Google (cstr6suwn9.skadnetwork) and select third-party buyers who have provided these values to Google.
    ```Swift
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
    <key>SKAdNetworkItems</key>
    <array>
        <dict>
            <key>SKAdNetworkIdentifier</key>
            <string>cstr6suwn9.skadnetwork</string>
        </dict>
    <array>
    ```
9. In the view where the the Ad will be presented import the streann-inside-ad-sdk-ios module:
    ```Swift
    import streann_inside_ad_sdk_ios
    ```
10. Implement the protocol of the streann-inside-ad-sdk-ios:
    ```Swift
    struct SomeView: View, InsideAdCallbackDelegate
    ```
    
11. Create a State String property with ".UNKNOWN" status to receive the insideAd status callbacks (errors and ad player's state):
    ```Swift
    @State var insideAdCallback: InsideAdCallbackType = .UNKNOWN
    ```
    
12. Implement the delegate function of the of the streann-inside-ad-sdk-ios to update the status of the callback property:
    ```Swift
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
    ```
    
13. Create the sdk ad view with the parameters to request an ad in the view body. 
    This will return a view:
    ```Swift
    InsideAdSdk.shared.insideAdView(delegate: self)
    ```  
    
    Optionally add content targeting with the parameters (all optional).
    ```Swift
    var body: some View {
        InsideAdSdk.shared.insideAdView(delegate: self, 
        screen: "some screen", 
        isAdMuted: Bool, 
        contentTargeting: TargetModel(contentId: "some id", 
                                    contentType: "some content type", 
                                    seriesId: "some session id", 
                                    contentProviderId: "some content provider", 
                                    categoryIds:  "[some array of categories ids]"))
    }        
    ```
    
14. If needed read the sdk public parameters if the campaign contains reels and ther interval
    ```Swift
    InsideAdSdk.shared.hasAdForReels: Bool
    InsideAdSdk.shared.intervalForReels: Int 
    ```
