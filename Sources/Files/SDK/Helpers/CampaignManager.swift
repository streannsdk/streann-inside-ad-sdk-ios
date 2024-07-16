//
//  CampaignManager.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 5.4.24.
//

import Foundation

class CampaignManager: ObservableObject {
    
    static let shared = CampaignManager()
    
    @Published var activePlacement: Placement?
    @Published var activeInsideAd: InsideAd?
    @Published var activeCampaign: CampaignAppModel?
    
    @Published var fetchCompleted = false
    
    var adLoader: NativeAdLoaderViewModel?
    var allPlacements = [Placement]()
    var geoIp: GeoIp?
    var allActiveCampaigns = [CampaignAppModel]()
    var isDeviceRotated =  false
    var rotateVolumeButton: Bool? = false
    
    var screen: String?
    var targetModel: TargetModel?
    
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
        
        SDKAPI.getGeoIpUrl { geoIpUrl, error in
            if let geoIpUrl {
                DispatchQueue.global(qos: .background).async {
                    SDKAPI.getGeoIp(fromUrl: geoIpUrl.geoIpUrl) { geoIp, error in
                        if let geoIp {
                            DispatchQueue.main.async {
                                self.geoIp = geoIp
                                SDKAPI.getCampaigns(countryCode: self.geoIp?.countryCode ?? "") { campaigns, error in
                                    DispatchQueue.main.async {
                                        if let campaigns {
                                            self.allActiveCampaigns = campaigns.sortActiveCampaign() ?? []
                                            self.allActiveCampaigns.forEach { self.allPlacements.append(contentsOf: $0.placements ?? []) }
                                            
                                            if let nativeAdType = self.allPlacements.flatMap({ $0.ads ?? []  }).first(where: { $0.adType == .FULLSCREEN_NATIVE }) {
                                                if let url = nativeAdType.url {
                                                    self.adLoader = NativeAdLoaderViewModel(unitAd: url)
                                                }
                                                
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
        }
    }
    
    func findActiveAdForScreen(){
        DispatchQueue.main.async {
            self.activeCampaign = self.allActiveCampaigns.findActiveCampaignFromScreenAndTargetModel(screen: self.screen, targetModel: self.targetModel)
            self.activeInsideAd = self.activeCampaign?.placements?.activeAdFromPlacement()
            self.activePlacement = self.activeCampaign?.placements?.findBy(adId: self.activeInsideAd?.id ?? "")
        }
    }
    
    func setFallbackAdAsActive(){
        if let fallbackAd = self.activeInsideAd?.fallback{
            self.activeInsideAd = fallbackAd
        }
    }
    
    func clearAll(){
        activeInsideAd = nil
        activePlacement = nil
    }
    private func checkIfAdHasTagForReels() {
        // check if any of the placements has the tag for reels
        allPlacements.forEach { $0.tags?.forEach { if $0 == InsideAdScreenLocations.reels.rawValue { InsideAdSdk.shared.hasAdForReels = true } } }
    }
}

extension CampaignManager {
    var startAfterSeconds: Double {
        if activeInsideAd?.adType != .FULLSCREEN_NATIVE &&
            screen != InsideAdScreenLocations.reels.rawValue {
            return Double(activePlacement?.properties?.startAfterSeconds ?? 5)
        } else {
            return 0
        }
    }
    
    private var delayLaunchForNativeAd: Double {
        // delay the launch for the native ad to load
        return adLoader != nil ? 2 : 0
    }
}
