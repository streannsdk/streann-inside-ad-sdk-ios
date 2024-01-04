//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI

public class InsideAdSdk {
    public func initializeSdk(baseUrl: String,
                              apiKey: String,
                              apiToken: String,
//                              insideAdsPlayerIntervalInMinutes: Int,
//                              screen: String,
//                              playerState: Binding<InsideAdCallbackType>,
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
    }

    @ViewBuilder
//    if loaded {
    public func insideAdView(screen: String, playerState: Binding<InsideAdCallbackType>, campaignDelegate: CampaignDelegate? = nil, insideAdsPlayerIntervalInMinutes: Int, animation:Bool = false, viewSize:CGSize = CGSize(width: 300, height: 250)) -> some View {
        AdsContentView(screen: screen, playerState: playerState, campaignDelegate: campaignDelegate, insideAdsPlayerIntervalInMinutes: insideAdsPlayerIntervalInMinutes, viewSize: viewSize)
    }
//    }
    
    struct AdsContentView: View {
        var screen: String
        var playerState: Binding<InsideAdCallbackType>
        var campaignDelegate: CampaignDelegate? = nil
        var insideAdsPlayerIntervalInMinutes: Int
        var viewSize: CGSize
        
        @State private var adViewHeight: CGFloat = 0
        @State private var adViewWidth: CGFloat = 0
        
        var body: some View {
            InsideAdView(screen: screen, insideAdCallback: playerState, campaignDelegate: campaignDelegate, insideAdsPlayerIntervalInMinutes: insideAdsPlayerIntervalInMinutes, viewSize: viewSize)
                .frame(maxWidth: adViewWidth, maxHeight: adViewHeight)
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setFullSize), perform: { _ in
                    adViewHeight = .infinity
                    adViewWidth = .infinity
                })
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setZeroSize), perform: { _ in
                    adViewHeight = 0
                    adViewWidth = 0
                })
        }
    }
    
    public init() {}
}
