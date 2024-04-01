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
    public var activeCampaign: CampaignAppModel?
    public var hasAdForReels: Bool = false
    
    var vastController = InsideAdViewController()
    
    @State var bannerAdViewController = BannerAdViewController()
    var campaignManager = CampaignManager()
    @State var imageLoader = LocalImageLoaderManager()
    @State var localVideoPlayerManager = LocalVideoPlayerManager()
    
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
        campaignManager = CampaignManager()
    }
    
    public init() { }
    
    @ViewBuilder
    public func insideAdView(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool = false) -> some View {
        AdsContentView(screen: screen, insideAdCallback: insideAdCallback, isAdMuted: isAdMuted, campaignManager: campaignManager)
    }
}
    
struct AdsContentView: View {
    @Environment(\.isPresented) var isPresented
    @ObservedObject var campaignManager: CampaignManager
    var insideAdCallback: Binding<InsideAdCallbackType>
    var screen = ""
    
    @State var adViewId = UUID()
    @State var timerNextAd: Timer? = nil
    @State var campaignManagerFinishedLoading = false
    
    public init(screen:String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool, campaignManager: CampaignManager) {
        self.insideAdCallback = insideAdCallback
        Constants.ResellerInfo.isAdMuted = isAdMuted
        self.campaignManager = campaignManager
        self.screen = screen
        InsideAdSdk.shared.activePlacement = self.campaignManager.allPlacements.getInsideAdByPlacement(screen: screen).1
        InsideAdSdk.shared.activeInsideAd = self.campaignManager.allPlacements.getInsideAdByPlacement(screen: screen).0
        InsideAdSdk.shared.activeCampaign = self.campaignManager.allCampaigns.findActiveCampaignFromActivePlacement( InsideAdSdk.shared.activePlacement?.id ?? "")
    }
    
    var body: some View {
        ZStack {
            if campaignManagerFinishedLoading || InsideAdSdk.shared.campaignManager.adLoaded {
                InsideAdView(insideAdCallback: insideAdCallback)
                    .id(adViewId)
                    .frame(maxWidth: campaignManager.adViewWidth, maxHeight:  campaignManager.adViewHeight)
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setFullSize), perform: { _ in
                        campaignManager.adViewHeight = UIScreen.main.bounds.width / 16 * 9
                        campaignManager.adViewWidth = .infinity
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setZeroSize), perform: { _ in
                        campaignManager.adViewHeight = 0
                        campaignManager.adViewWidth = 0
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_restoreSize), perform: { _ in
                        //Reset the size of the vast view if user clicked on the vast ad link and return back in the app
                        switch InsideAdSdk.shared.activeInsideAd?.adType {
                        case .VAST:
                            withAnimation {
                                adViewId = UUID()
                            }
                        default: break
                        }
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_startTimer), perform: { _ in
                        var intervalInMinutes = Constants.ResellerInfo.intervalInMinutes
                        
                        if let intervalInMinutesCamp = InsideAdSdk.shared.activeCampaign?.properties?.intervalInMinutes {
                            intervalInMinutes = intervalInMinutesCamp
                        }
                        
                        if let intervalInMinutes, intervalInMinutes > 0 {
                            print(Logger.log("Timer started for next ad - intervalInMinutes \(intervalInMinutes)"))
                            timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes.convertMinutesToSeconds()), repeats: false){ _ in
                                adViewId = UUID()
                                switch InsideAdSdk.shared.activeInsideAd?.adType {
                                case .VAST:
                                    InsideAdSdk.shared.campaignManager.vastRequested = false
                                    InsideAdSdk.shared.vastController = InsideAdViewController()
                                    
                                case.LOCAL_VIDEO:
                                    InsideAdSdk.shared.localVideoPlayerManager.loadAsset()
                                    
                                default: break
                                }
                            }
                        }else{
                            print(Logger.log("Timer not started - intervalInMinutes \(intervalInMinutes ?? 0)"))
                        }
                    })
                    .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_stopTimer), perform: { _ in
                        timerNextAd?.invalidate()
                        timerNextAd = nil
                    })
                    .onChange(of: isPresented) { presented in
                        //Close the ad tasks when the view is dismissed
                        if !presented {
                            InsideAdSdk.shared.campaignManager.vastRequested = false
                            InsideAdSdk.shared.vastController = InsideAdViewController()
                            InsideAdSdk.shared.localVideoPlayerManager.stop()
                            campaignManager.adViewHeight = 0
                            campaignManager.adViewWidth = 0
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_startAd), perform: { value in
            InsideAdSdk.shared.activePlacement = InsideAdSdk.shared.campaignManager.allPlacements.getInsideAdByPlacement(screen: screen).1
            InsideAdSdk.shared.activeInsideAd = InsideAdSdk.shared.campaignManager.allPlacements.getInsideAdByPlacement(screen: screen).0
            InsideAdSdk.shared.activeCampaign = InsideAdSdk.shared.campaignManager.allCampaigns.findActiveCampaignFromActivePlacement( InsideAdSdk.shared.activePlacement?.id ?? "")
            DispatchQueue.main.asyncAfter(deadline: InsideAdSdk.shared.activeInsideAd?.adType == .FULLSCREEN_NATIVE ? .now() + 2 : .now() + 0) {
                campaignManagerFinishedLoading = true
            }
        })
    }
}
