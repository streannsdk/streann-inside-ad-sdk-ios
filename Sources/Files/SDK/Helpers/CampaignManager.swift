//
//  CampaignManager.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 5.4.24.
//

import Foundation

class CampaignManager: ObservableObject {
    
    init() {
        getAllCampaigns()
    }
    
    @Published var adViewWidth: CGFloat = 0
    @Published var adViewHeight: CGFloat = 0
    
    var adLoader: NativeAdLoaderViewModel?
    var allCampaigns = [CampaignAppModel]()
    var allPlacements = [Placement]()
    var geoIp: GeoIp?
    var vastRequested = false
    var adLoaded = false
    
    var allActiveCampaigns = [CampaignAppModel]()

    private func getAllCampaigns() {
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
//                                            self.allCampaigns = campaigns.sortActiveCampaign() ?? []
                                            self.allActiveCampaigns = campaigns.sortActiveCampaign() ?? []
                                            
                                            if let unitId = self.allPlacements.flatMap({ $0.ads ?? []  }).first(where: { $0.adType == .FULLSCREEN_NATIVE })?.url {
                                                self.adLoader = NativeAdLoaderViewModel(unitAd: unitId)
                                            }
                                            self.checkIfAdHasTagForReels()
                                            
                                            //Update the shared campaign manager with the new data
                                            InsideAdSdk.shared.campaignManager = self
                                            
                                            //Inform the InsideAdsView to display the ad
                                            NotificationCenter.post(name: .AdsContentView_startAd)

                                            self.adLoaded = true
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
    
    private func checkIfAdHasTagForReels() {
        allPlacements.forEach { $0.tags?.forEach { if $0 == "Reels" { InsideAdSdk.shared.hasAdForReels = true } } }
    }
}

extension CampaignManager {
    var startAfterSeconds: Double {
            if InsideAdSdk.shared.activeInsideAd?.adType != .FULLSCREEN_NATIVE &&
                InsideAdSdk.shared.currentAdScreen != InsideAdScreenLocations.reels.rawValue {
                return Double(InsideAdSdk.shared.activePlacement?.properties?.startAfterSeconds ?? 0)
            } else {
                return 0
            }
        }
}
