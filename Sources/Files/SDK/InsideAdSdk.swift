//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI

public class InsideAdSdk {
    
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
    }
    
    @ViewBuilder
//    if loaded {
    public func insideAdView(screen: String, playerState: Binding<InsideAdCallbackType>, intervalInMinutes: Int? = nil, viewSize:CGSize = CGSize(width: 300, height: 250), isAdMuted: Bool = false) -> some View {
        AdsContentView(screen: screen, playerState: playerState, intervalInMinutes: intervalInMinutes, viewSize: viewSize, isAdMuted: isAdMuted)
    }
//    }
    
    struct AdsContentView: View {
        var screen: String
        var playerState: Binding<InsideAdCallbackType>
        var viewSize: CGSize
        
        @State var adViewId = UUID()
        @State var timerNextAd: Timer? = nil
        
        @State private var adViewHeight: CGFloat = 0
        @State private var adViewWidth: CGFloat = 0
        
        public init(screen:String, playerState: Binding<InsideAdCallbackType>, intervalInMinutes: Int? = nil, viewSize: CGSize, isAdMuted: Bool) {
            self.screen = screen
            self.playerState = playerState
            self.viewSize = viewSize
            
            if let intervalInMinutes = intervalInMinutes{
                Constants.ResellerInfo.intervalInMinutes = intervalInMinutes
            }
            Constants.ResellerInfo.isAdMuted = isAdMuted
        }
        
        var body: some View {
            InsideAdView(screen: screen, insideAdCallback: playerState, viewSize: viewSize)
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
                    
                    if intervalInMinutes > 0 {
                        print(Logger.log("Timer started for next ad - intervalInMinutes \(intervalInMinutes)"))
                        timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes * 60), repeats: false){ _ in
                            adViewId = UUID()
                        }
                    }else{
                        print(Logger.log("Timer not started - intervalInMinutes \(intervalInMinutes)"))
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_stopTimer), perform: { _ in
                    timerNextAd?.invalidate()
                    timerNextAd = nil
                })
        }
    }
}
