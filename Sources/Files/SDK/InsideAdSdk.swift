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
    public var intervalForReels: Int?
    
    var vastController = InsideAdViewController()
    var currentAdScreen = ""
    
    @State var bannerAdViewController = BannerAdViewController()
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
        CampaignManager.shared.getAllCampaigns()
    }
    
    public init() { }
    
    @ViewBuilder
    public func insideAdView(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool = false, contentTargeting: TargetModel? = nil) -> some View {
        AdsContentView(screen: screen, insideAdCallback: insideAdCallback, isAdMuted: isAdMuted, targetModel: contentTargeting)
    }
}
    
struct AdsContentView: View {
    @ObservedObject var campaignManager = CampaignManager.shared
    @StateObject var viewModel = AdsContentViewModel()
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @State var adViewId = UUID()
    @State var timerNextAd: Timer? = nil
    
    @Binding var insideAdCallback: InsideAdCallbackType

    var screen = ""
    var targetModel: TargetModel?
    
    public init(screen:String, insideAdCallback: Binding<InsideAdCallbackType>, isAdMuted: Bool, targetModel: TargetModel?) {
        self._insideAdCallback = insideAdCallback
        Constants.ResellerInfo.isAdMuted = isAdMuted
        self.screen = screen
        self.targetModel = targetModel
        
        // Set the current screen to check the startAfterSeconds delay
        InsideAdSdk.shared.currentAdScreen = screen
        
        //If adLoaded is true, set the activeCampaign, activeInsideAd and activePlacement otherwise don't initialize them
        if campaignManager.adLoaded {
            self.findActiveCampaignForScreen()
        }
    }
    
    private func findActiveCampaignForScreen(){
        if insideAdCallback == .UNKNOWN || insideAdCallback == .ALL_ADS_COMPLETED{
            adViewId = UUID()
            InsideAdSdk.shared.activeCampaign = campaignManager.allActiveCampaigns.findActiveCampaignFromScreenAndTargetModel(screen: InsideAdSdk.shared.currentAdScreen, targetModel: targetModel)
            InsideAdSdk.shared.activeInsideAd = campaignManager.allPlacements.activeAdFromPlacement()
            InsideAdSdk.shared.activePlacement = TargetManager.shared.activePlacement()
        }
    }
    
    var body: some View {
        ZStack {
            if campaignManager.adLoaded {
                InsideAdView(insideAdCallback: $insideAdCallback)
            }
        }
        .id(adViewId)
        .frame(maxWidth: campaignManager.adViewWidth, maxHeight:  campaignManager.adViewHeight)
        .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setZeroSize), perform: { _ in
            campaignManager.adViewHeight = 0
            campaignManager.adViewWidth = 0
        })
        .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_setFullSize), perform: { _ in
            campaignManager.adViewHeight = UIScreen.main.bounds.width / 16 * 9
            campaignManager.adViewWidth = .infinity
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
            timerNextAd?.invalidate()
            timerNextAd = nil
            
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
                        campaignManager.vastRequested = false
                        InsideAdSdk.shared.vastController = InsideAdViewController()
                        
                    case.LOCAL_VIDEO:
                        InsideAdSdk.shared.localVideoPlayerManager.loadAsset()
                        
                    case .LOCAL_IMAGE:
                        InsideAdSdk.shared.imageLoader.image = nil
                        
                    case .BANNER:
                        InsideAdSdk.shared.bannerAdViewController = BannerAdViewController()
                        
                    default:
                        break
                    }
                }
            }else{
                print(Logger.log("Timer not started - intervalInMinutes \(intervalInMinutes ?? 0)"))
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { orientation in
            campaignManager.isDeviceRotated = true
        }
        .onDisappear{
            //If the device is rotated, don't reset the ad otherwise reset the ad
            if !campaignManager.isDeviceRotated {
                switch InsideAdSdk.shared.activeInsideAd?.adType {
                    case .VAST:
                        campaignManager.vastRequested = false
                        InsideAdSdk.shared.vastController = InsideAdViewController()

                    case.LOCAL_VIDEO:
                        InsideAdSdk.shared.localVideoPlayerManager.player.replaceCurrentItem(with: nil)
                        InsideAdSdk.shared.localVideoPlayerManager.playing = false
                        InsideAdSdk.shared.localVideoPlayerManager = LocalVideoPlayerManager()

                    case .LOCAL_IMAGE:
                        InsideAdSdk.shared.imageLoader.image = nil
                        
                    case .BANNER:
                        InsideAdSdk.shared.bannerAdViewController = BannerAdViewController()
                        
                    default: break
                }
                timerNextAd?.invalidate()
                timerNextAd = nil
                campaignManager.adViewHeight = 0
                campaignManager.adViewWidth = 0
            } else {
                campaignManager.isDeviceRotated = false
            }
        }
        .onChange(of: campaignManager.adLoaded) { newValue in
            self.findActiveCampaignForScreen()
        }
        .onAppear(perform: {
            adViewId = UUID()
        })
    }
}
