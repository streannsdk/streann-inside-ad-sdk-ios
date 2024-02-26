//
//  InsideAdViewModel.swift
//  TestTheLibrary
//
//  Created by Fani on 9.1.24.
//

import Combine
import SwiftUI

class InsideAdViewModel: NSObject, ObservableObject {
    
    var screen: String
    
    @Published var allCampaigns:[CampaignAppModel]?
    @Published var activeCampaign:CampaignAppModel?
    
    @Published var activeInsideAd: InsideAd?
    @Published var activePlacement: Placement?
    @Published var geoIp: GeoIp?
    
    @Binding var insideAdCallback: InsideAdCallbackType
    
    let APIProtocolType: SDKAPIProtocol.Type
    
    init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, apiProtocolType: SDKAPIProtocol.Type) {
        self.screen = screen
        self._insideAdCallback = insideAdCallback
        self.APIProtocolType = apiProtocolType
        super.init()
        
        requestAds()
    }
    
    func requestAds(){
        
        if Constants.ResellerInfo.apiKey == "" {
            let errorMsg = "Api Key is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            insideAdCallback = .IMAAdError(errorMsg)
        }
        
        if Constants.ResellerInfo.baseUrl == "" {
            let errorMsg = "Base Url is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            insideAdCallback = .IMAAdError(errorMsg)
        }
        
        Constants.CampaignInfo.intervalInMinutes = nil
        
        APIProtocolType.getGeoIpUrl { geoIpUrl, error in
            if let geoIpUrl {
                self.APIProtocolType.getGeoIp(fromUrl: geoIpUrl.geoIpUrl) { geoIp, error in
                    self.geoIp = geoIp
                    
                    if let geoIp {
                        self.APIProtocolType.getCampaigns(countryCode: geoIp.countryCode ?? "") {[weak self] campaigns, error in
                            self?.allCampaigns = campaigns
                            
                            if let campaigns {
                                let activeCampaign = campaigns.getActiveCampaign()
                                self?.activeCampaign = activeCampaign
                                
                                Constants.CampaignInfo.intervalInMinutes = activeCampaign?.properties?.intervalInMinutes ?? 1
                                
                                if let screen = self?.screen {
                                    let activeInsideAdAndPlacement = activeCampaign?.placements?.getInsideAdByPlacement(screen: screen)
                                    
                                    DispatchQueue.main.async {
                                        self?.activeInsideAd = activeInsideAdAndPlacement?.0
                                        self?.activePlacement = activeInsideAdAndPlacement?.1
                                    }
                                }
                            }else{
                                let errorMsg = "Error while getting AD."
                                self?.insideAdCallback = .IMAAdError(errorMsg)
                            }
                        }
                    }
                }
            }
        }
    }
}
