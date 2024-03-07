//
//  InsideAdViewModel.swift
//  TestTheLibrary
//
//  Created by Fani on 9.1.24.
//

import Combine
import SwiftUI

class InsideAdViewModel: NSObject, ObservableObject {
    var screen: String?
    
    @Published var activeCampaign: CampaignAppModel?
    @Published var activeInsideAd: InsideAd?
    @Published var activePlacement: Placement?
    
    @Binding var insideAdCallback: InsideAdCallbackType
    
    init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>) {
        self.screen = screen
        self._insideAdCallback = insideAdCallback
        super.init()
        
        requestAds()
    }
    
    func requestAds() {
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
        
        DispatchQueue.main.async {
            if let campaigns = CampaignManager.shared.allCampaigns {
                let activeCampaign = campaigns.getActiveCampaign()
                self.activeCampaign = activeCampaign
                                
                if let screen = self.screen {
                    
                    let activeInsideAdAndPlacement = activeCampaign?.placements?.getInsideAdByPlacement(screen: screen)
                    
                    
                    self.activeInsideAd = activeInsideAdAndPlacement?.0
                    self.activePlacement = activeInsideAdAndPlacement?.1
                }
            }else{
                let errorMsg = "Error while getting AD."
                self.insideAdCallback = .IMAAdError(errorMsg)
            }
        }
    }
}
