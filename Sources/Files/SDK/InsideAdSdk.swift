//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI

public class InsideAdSdk {
    public static let shared = InsideAdSdk()
    
    public init(baseUrl: String,
                apiKey: String,
                apiToken: String,
                siteUrl: String? = nil,
                unitId: String? = nil,
                storeUrl: String? = nil,
                descriptionUrl: String? = nil,
                userBirthYear: Int64? = nil,
userGender: UserGender? = nil) {
        Constants.ResellerInfo.baseUrl = baseUrl
        Constants.ResellerInfo.apiKey = apiKey
        Constants.ResellerInfo.apiToken = apiToken
        Constants.ResellerInfo.unitId = unitId ?? ""
        Constants.ResellerInfo.siteUrl = siteUrl ?? ""
        Constants.ResellerInfo.storeUrl = storeUrl ?? ""
        Constants.ResellerInfo.descriptionUrl = descriptionUrl ?? ""
        Constants.UserInfo.userBirthYear = userBirthYear
        Constants.UserInfo.userGender = userGender ?? .unknown
        _ = CampaignManager.shared
    }
    
    public init() { }
    
    @ViewBuilder
    public func insideAdView(screen: String, playerState: Binding<InsideAdCallbackType>, isAdMuted: Bool = false) -> some View {
        AdsContentView(screen: screen, playerState: playerState, isAdMuted: isAdMuted)
    }
    
    struct AdsContentView: View {
        var screen: String
        var playerState: Binding<InsideAdCallbackType>
        
        @State var adViewId = UUID()
        @State var timerNextAd: Timer? = nil
        @State private var adViewHeight: CGFloat = 0
        @State private var adViewWidth: CGFloat = 0
        
        public init(screen:String, playerState: Binding<InsideAdCallbackType>, isAdMuted: Bool) {
            self.screen = screen
            self.playerState = playerState
            Constants.ResellerInfo.isAdMuted = isAdMuted
        }
        
        var body: some View {
            VStack {
                InsideAdView(screen: screen, insideAdCallback: playerState)
                    .id(adViewId)
                    .frame(maxWidth: adViewWidth, maxHeight: adViewHeight)
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setFullSize), perform: { _ in
                        adViewHeight = UIScreen.main.bounds.width / 16 * 9
                        adViewWidth = .infinity
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setZeroSize), perform: { _ in
                        adViewHeight = 0
                        adViewWidth = 0
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_startTimer), perform: { _ in
                        var intervalInMinutes = Constants.ResellerInfo.intervalInMinutes
                        if let intervalInMinutesCamp = CampaignManager.shared.allCampaigns?.getActiveCampaign()?.properties?.intervalInMinutes {
                            intervalInMinutes = intervalInMinutesCamp
                        }
                        
                        if let intervalInMinutes, intervalInMinutes > 0 {
                            print(Logger.log("Timer started for next ad - intervalInMinutes \(intervalInMinutes)"))
                            timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes.convertMinutesToSeconds()), repeats: false){ _ in
                                adViewId = UUID()
                            }
                        }else{
                            print(Logger.log("Timer not started - intervalInMinutes \(intervalInMinutes ?? 0)"))
                        }
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_stopTimer), perform: { _ in
                        timerNextAd?.invalidate()
                        timerNextAd = nil
                    })
            }
        }
    }
}
