//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI
#if os(iOS)
import GoogleMobileAds
#endif

public protocol InsideAdCallbackDelegate {
    func insideAdCallbackReceived(data: InsideAdCallbackType)

    /// Sent once per ad, just before the SDK requests it: the IMA request for VAST, the
    /// Google request for a banner, the file download for a local image or video.
    func insideAdRequested(screen: String?, ad: InsideAd)

    /// Sent once per ad, when it is actually on screen. Unlike `.STARTED`, which a newly
    /// mounted view is sent again for an ad already playing, this is never repeated — so
    /// a host can count it.
    func insideAdDisplayed(screen: String?, ad: InsideAd)
}

/// Empty defaults, so hosts that only need `insideAdCallbackReceived` don't change.
public extension InsideAdCallbackDelegate {
    func insideAdRequested(screen: String?, ad: InsideAd) {}
    func insideAdDisplayed(screen: String?, ad: InsideAd) {}
}

public class InsideAdSdk {
    public static let shared = InsideAdSdk()
    
    public var hasAdForReels: Bool = false
    public var intervalForReels: Int?
    public var activeInsideAd: InsideAd?
    public var vastTagUrl: String?
    public var vastErrorMessage: String?

    /// Turns on IMA's verbose logging, including the full ad request it sends. Off by
    /// default: it is noisy and prints the whole tag. Set it before the first ad request.
    public static var imaDebugLoggingEnabled = false

    /// Logs what every ad slot is doing whenever the app goes to the background or comes
    /// back. Off by default.
    public static var lifecycleLoggingEnabled = false

    public init(baseUrl: String,
                apiKey: String,
                apiToken: String,
                siteUrl: String? = nil,
                storeUrl: String? = nil,
                descriptionUrl: String? = nil,
                userBirthYear: Int64? = nil,
                userGender: UserGender? = nil) {
        Constants.ResellerInfo.baseUrl = baseUrl
        Constants.ResellerInfo.apiKey = apiKey
        Constants.ResellerInfo.apiToken = apiToken
        Constants.ResellerInfo.siteUrl = siteUrl ?? ""
        Constants.ResellerInfo.storeUrl = storeUrl ?? ""
        Constants.ResellerInfo.descriptionUrl = descriptionUrl ?? ""
        Constants.UserInfo.userBirthYear = userBirthYear
        Constants.UserInfo.userGender = userGender ?? .unknown
        Self.startMobileAdsIfNeeded()
        CampaignManager.shared.getAllCampaigns()
    }
    
    public init() { }

    /// Starts Google's Mobile Ads SDK once per process.
    ///
    /// IMA uses it to identify the app to the ad server on in-app VAST requests — the
    /// app-signal equivalent of a browser's `url`. Without it an ad server sees an
    /// unidentified request and can refuse to serve, which is what Multiview hit: the same
    /// tag filled in a browser and on Android but returned an empty VAST in the app.
    ///
    /// It reads `GADApplicationIdentifier` from the host's Info.plist, which must be the
    /// publisher's real AdMob id, not Google's test one. Google Mobile Ads has no tvOS
    /// build, so on Apple TV IMA requests carry no app signals.
    private static var hasStartedMobileAds = false
    static func startMobileAdsIfNeeded() {
#if os(iOS)
        guard !hasStartedMobileAds else { return }
        hasStartedMobileAds = true
        GADMobileAds.sharedInstance().start { status in
            let states = status.adapterStatusesByClassName
                .map { "\($0.key): \($0.value.state == .ready ? "ready" : "not ready")" }
                .joined(separator: ", ")
            print(Logger.log("GoogleMobileAds started — \(states)"))
        }
#endif
    }
    
    /// Builds an ad view for one placement.
    ///
    /// - Parameters:
    ///   - screen: Placement tag to match campaigns against. Ad state is keyed by this
    ///     value, so two views with different screen names run independently and may be
    ///     on screen at the same time. Use `InsideAdScreenLocations` for the known names.
    ///   - activePlayersCount: Number of players currently visible in the Multiview canvas.
    ///     Only used when `screen` is `MULTIVIEW_CANVAS`, where the ad occupies a grid tile
    ///     and is therefore only served while 1–3 players are visible.
    ///   - containerSize: Size of the container the ad renders into. When omitted the ad
    ///     assumes it spans the full device width at 16:9.
    ///   - showsCloseButton: Set false to render the ad non-dismissable, for hosts that
    ///     present it as part of their own layout.
    @ViewBuilder
    public func insideAdView(delegate: InsideAdCallbackDelegate,
                             screen: String? = nil,
                             isAdMuted: Bool = false,
                             contentTargeting: TargetModel? = nil,
                             rotateVolumeButton: Bool? = false,
                             isPrerollAd: Bool = false,
                             activePlayersCount: Int? = nil,
                             containerSize: CGSize? = nil,
                             showsCloseButton: Bool = true) -> some View {
        AdsContentView(delegate: delegate,
                       screen: screen,
                       isAdMuted: isAdMuted,
                       targetModel: contentTargeting,
                       rotateVolumeButton: rotateVolumeButton,
                       isPrerollAd: isPrerollAd,
                       activePlayersCount: activePlayersCount,
                       containerSize: containerSize,
                       showsCloseButton: showsCloseButton)
    }

    /// Clears the resolved ad. Pass `screen` to clear one placement, omit it to clear all.
    public func removeAdView(screen: String? = nil) {
        if let screen {
            CampaignManager.shared.slot(for: screen).clearResolvedAd()
        } else {
            CampaignManager.shared.clearAll()
        }
    }

    public func removeLocalVideoAdView(screen: String? = nil) {
        CampaignManager.shared.slot(for: screen).localVideoManager.stop()
    }

    public func removeVastAdView(screen: String? = nil) {
        CampaignManager.shared.slot(for: screen).clearPlayback()
    }
}
