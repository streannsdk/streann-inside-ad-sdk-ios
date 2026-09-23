//
//  CampaignManager.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 5.4.24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

class CampaignManager: ObservableObject {
    
    static let shared = CampaignManager()
    
    @Published var fetchCompleted = false
    
#if os(iOS)
    // Native ads are Google Mobile Ads only, which has no tvOS build.
    var adLoader: NativeAdLoaderViewModel?
#endif
    var allPlacements = [Placement]()
    var geoIp: GeoIp?
    var allActiveCampaigns = [CampaignAppModel]()

    // MARK: - Slots
    // One AdSlot per screen name, so several ad views can be on screen at once without
    // sharing an ad, a size or a callback. Hosts that pass no screen get the default slot.
    private var slots = [String: AdSlot]()

    func slot(for screen: String?) -> AdSlot {
        let key = screen ?? AdSlot.defaultKey
        if let existing = slots[key] { return existing }
        let created = AdSlot(screen: screen)
        slots[key] = created
        return created
    }

    /// The slot used by hosts that never pass a screen name.
    var defaultSlot: AdSlot { slot(for: nil) }

    var allSlots: [AdSlot] { Array(slots.values) }

    // MARK: - App lifecycle logging

    /// Prints what every slot is doing when the app changes state. Ad resolution and the
    /// interval timer keep running in the background — nothing tears them down, because the
    /// host's views stay mounted — so this is how to see what a slot did while off screen.
    private func startLifecycleLogging() {
#if canImport(UIKit) && !os(watchOS)
        let center = NotificationCenter.default
        let events: [(Notification.Name, String)] = [
            (UIApplication.didEnterBackgroundNotification, "DID ENTER BACKGROUND"),
            (UIApplication.willEnterForegroundNotification, "WILL ENTER FOREGROUND"),
            (UIApplication.didBecomeActiveNotification, "DID BECOME ACTIVE"),
            (UIApplication.willResignActiveNotification, "WILL RESIGN ACTIVE")
        ]
        for (name, label) in events {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.logSlotStates(label)
            }
        }
#endif
    }

    func logSlotStates(_ label: String) {
        guard InsideAdSdk.lifecycleLoggingEnabled else { return }
        print(Logger.log("APP \(label)"))
        for slot in allSlots.sorted(by: { $0.key < $1.key }) {
            let ad = slot.activeInsideAd
            let nextAd = slot.timerNextAd?.fireDate.timeIntervalSinceNow ?? -1
            let dueIn = slot.adStartDate?.timeIntervalSinceNow ?? -1
            print(Logger.log(String(
                format: "  [%@] views=%d resolved=%@ onScreen=%@ startsIn=%@ nextAdIn=%@ callback=%@",
                slot.key,
                slot.mountedViewCount,
                ad == nil ? "none" : (ad?.adType.map { "\($0)" } ?? "unknown"),
                slot.hasSizedAd ? "yes" : "no",
                dueIn < 0 ? "-" : String(format: "%.0fs", dueIn),
                nextAd < 0 ? "-" : String(format: "%.0fs", nextAd),
                "\(slot.insideAdCallback)")))
        }
    }
    
    init() {
        startLifecycleLogging()
    }

    func getAllCampaigns() {
        if Constants.ResellerInfo.apiKey == "" {
            let errorMsg = "Api Key is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            return
        }
        
        if Constants.ResellerInfo.baseUrl == "" {
            let errorMsg = "Base Url is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            SDKAPI.getGeoIp { geoIp, error in
                if let geoIp {
                    DispatchQueue.main.async {
                        self.geoIp = geoIp
                        SDKAPI.getCampaigns(countryCode: self.geoIp?.countryCode ?? "") { campaigns, error in
                            DispatchQueue.main.async {
                                if let campaigns {
                                    self.allActiveCampaigns = campaigns.sortActiveCampaign() ?? []
                                    self.allActiveCampaigns.forEach { self.allPlacements.append(contentsOf: $0.placements ?? []) }
                                    
                                    if let nativeAdType = self.allPlacements.flatMap({ $0.ads ?? []  }).first(where: { $0.adType == .FULLSCREEN_NATIVE }) {
#if os(iOS)
                                        // Native ads are Google Mobile Ads only, which has no tvOS build.
                                        if let url = nativeAdType.url {
                                            self.adLoader = NativeAdLoaderViewModel(unitAd: url)
                                        }
#endif
                                        
                                        //find the placement that contains the nativeAdType
                                        if let nativeAdPlacement = self.allPlacements.first(where: { $0.ads?.contains(where: { $0.adType == .FULLSCREEN_NATIVE }) ?? false }) {
                                            if let intervalForReels = nativeAdPlacement.properties?.intervalForReels {
                                                InsideAdSdk.shared.intervalForReels = intervalForReels
                                            }
                                        }
                                    }
                                    
                                    self.checkIfAdHasTagForReels()
                                    // Delay for the native ad to load
                                    DispatchQueue.main.asyncAfter(deadline: .now() + self.delayLaunchForNativeAd) {
                                        self.fetchCompleted = true
                                    }
                                } else {
                                    let errorMsg = Logger.log("Error while getting AD.")
                                    print(Logger.log(errorMsg))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func clearAll() {
        allSlots.forEach { $0.clearResolvedAd() }
    }

    private func checkIfAdHasTagForReels() {
        // check if any of the placements has the tag for reels
        allPlacements.forEach { $0.tags?.forEach { if $0 == InsideAdScreenLocations.reels.rawValue { InsideAdSdk.shared.hasAdForReels = true } } }
    }
}

extension CampaignManager {
    private var delayLaunchForNativeAd: Double {
        // delay the launch for the native ad to load
#if os(iOS)
        return adLoader != nil ? 2 : 0
#else
        return 0
#endif
    }
}
