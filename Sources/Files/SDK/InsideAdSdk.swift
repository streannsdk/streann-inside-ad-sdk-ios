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
    public func insideAdView(screen: String, playerState: Binding<InsideAdCallbackType>, campaignDelegate: CampaignDelegate? = nil, intervalInMinutes: Int? = nil, viewSize:CGSize = CGSize(width: 300, height: 250)) -> some View {
        AdsContentView(screen: screen, playerState: playerState, campaignDelegate: campaignDelegate, intervalInMinutes: intervalInMinutes, viewSize: viewSize)
    }
//    }
    
    struct AdsContentView: View {
        var screen: String
        var playerState: Binding<InsideAdCallbackType>
        var campaignDelegate: CampaignDelegate? = nil
        var viewSize: CGSize
        
        @State var adViewId = UUID()
        @State var timerNextAd: Timer? = nil
        
        @State private var adViewHeight: CGFloat = 0
        @State private var adViewWidth: CGFloat = 0
        
        public init(screen:String, playerState: Binding<InsideAdCallbackType>, campaignDelegate: CampaignDelegate? = nil, intervalInMinutes: Int? = nil, viewSize: CGSize) {
            self.screen = screen
            self.playerState = playerState
            self.campaignDelegate = campaignDelegate
            self.viewSize = viewSize
            
            if let intervalInMinutes = intervalInMinutes{
                Constants.ResellerInfo.intervalInMinutes = intervalInMinutes
            }
        }
        
        var body: some View {
            InsideAdView(screen: screen, insideAdCallback: playerState, campaignDelegate: campaignDelegate, viewSize: viewSize)
                .id(adViewId)
                .frame(maxWidth: adViewWidth, maxHeight: adViewHeight)
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setFullSize), perform: { _ in
                    adViewHeight = .infinity
                    adViewWidth = .infinity
                })
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setZeroSize), perform: { _ in
                    adViewHeight = 0
                    adViewWidth = 0
                })
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_startTimer), perform: { _ in
                    var intervalInMinutes = Constants.ResellerInfo.intervalInMinutes
                    if let intervalInMinutesCamp = Constants.CampaignInfo.intervalInMinutes {
                        intervalInMinutes = intervalInMinutesCamp
                    }
                    
                    timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes * 60), repeats: false){ _ in
                        adViewId = UUID()
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_stopTimer), perform: { _ in
                    timerNextAd?.invalidate()
                    timerNextAd = nil
                })
        }
    }
    
    public init() {}
}
