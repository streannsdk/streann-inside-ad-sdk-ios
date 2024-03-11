//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI

public class InsideAdSdk {
    public static let shared = InsideAdSdk()
    public var activePlacement: Placement?
    public var activeInsideAd: InsideAd?
    
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
        _ = CampaignManager.shared
    }
    
    public init() { }
    
    @ViewBuilder
    public func insideAdView(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool = false) -> some View {
        AdsContentView(screen: screen, insideAdCallback: insideAdCallback, isAdMuted: isAdMuted)
    }
    
    struct AdsContentView: View {
        var screen: String
        var insideAdCallback: Binding<InsideAdCallbackType>
        
        @State var adViewId = UUID()
        @State var timerNextAd: Timer? = nil
        @State private var adViewHeight: CGFloat = 0
        @State private var adViewWidth: CGFloat = 0
        
        public init(screen:String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool) {
            self.screen = screen
            self.insideAdCallback = insideAdCallback
            Constants.ResellerInfo.isAdMuted = isAdMuted
            CampaignManager.shared.activePlacement = CampaignManager.shared.placements?.getInsideAdByPlacement(screen: screen).1
            CampaignManager.shared.activeInsideAd = CampaignManager.shared.placements?.getInsideAdByPlacement(screen: screen).0
        }

        var body: some View {
            InsideAdView(insideAdCallback: insideAdCallback)
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
                    if let intervalInMinutesCamp = CampaignManager.shared.activeCampaign?.properties?.intervalInMinutes {
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
