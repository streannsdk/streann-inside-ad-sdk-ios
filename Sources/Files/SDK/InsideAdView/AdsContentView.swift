//
//  AdsContentView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadziev on 19.4.24.
//

import SwiftUI

struct AdsContentView: View {
    @ObservedObject var campaignManager = CampaignManager.shared
    @ObservedObject var adsManager = AdsManager.shared
    
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @State var adViewId = UUID()

    var delegate: InsideAdCallbackDelegate?
    
    public init(delegate: InsideAdCallbackDelegate, screen: String, isAdMuted: Bool, targetModel: TargetModel?) {
        Constants.ResellerInfo.isAdMuted = isAdMuted
        self.delegate = delegate
        campaignManager.screen = screen
        campaignManager.targetModel = targetModel

        //If adLoaded is true, set the activeCampaign, activeInsideAd and activePlacement otherwise don't initialize them
        if campaignManager.fetchCompleted {
            self.findActiveAdForScreen()
        }
    }
    
    var body: some View {
        ZStack {
            if campaignManager.activeInsideAd != nil {
                Group {
                    if let activeInsideAd = CampaignManager.shared.activeInsideAd {
                        switch activeInsideAd.adType {
                        case .VAST:
                            VastViewWrapper(insideAdCallback: $adsManager.insideAdCallback)
                            
                        case .LOCAL_IMAGE:
                            LocalImageView(insideAdCallback: $adsManager.insideAdCallback)
                                .environmentObject(adsManager.localImageManager)
                            
                        case .LOCAL_VIDEO:
                            LocalVideoPlayerView(insideAdCallback: $adsManager.insideAdCallback)
                                .environmentObject(adsManager.localVideoManager)
                            
                        case .BANNER:
                            BannerAdViewWrapper(insideAdCallback: $adsManager.insideAdCallback)
                            
                        case .FULLSCREEN_NATIVE:
                            NativeAdView()
                            
                        case .unsupported, .none:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .id(adViewId)
        .frame(maxWidth: adsManager.adViewWidth, maxHeight:  adsManager.adViewHeight)
        .onReceive(NotificationCenter.default.publisher(for: .AdsContentView_restoreSize), perform: { _ in
            //Reset the size of the vast view if user clicked on the vast ad link and return back in the app
            switch campaignManager.activeInsideAd?.adType {
            case .VAST:
                withAnimation {
                    adViewId = UUID()
                }
            default: break
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { orientation in
            campaignManager.isDeviceRotated = true
        }
        .onChange(of: campaignManager.fetchCompleted) { newValue in
            self.findActiveAdForScreen()
        }
        .onChange(of: adsManager.insideAdCallback) { newValue in
            print(Logger.log("AdsContentView INSIDE AD CALLBACK RECEIVED: \(newValue)"))
            self.delegate?.insideAdCallbackReceived(data: newValue)
        }
        .onAppear(perform: {
            adViewId = UUID()
            print(Logger.log("AdsContentView APPEARED"))
        })
        .onDisappear{
            //If the device is rotated, don't reset the ad otherwise reset the ad
            if !campaignManager.isDeviceRotated {
                print(Logger.log("AdsContentView Disappeared"))
                adsManager.insideAdCallback = .ALL_ADS_COMPLETED
            } else {
                campaignManager.isDeviceRotated = false
            }
        }
    }
    
    private func findActiveAdForScreen(){
        if adsManager.insideAdCallback == .UNKNOWN || adsManager.insideAdCallback == .ALL_ADS_COMPLETED{
            campaignManager.findActiveAdForScreen()
            adViewId = UUID()
        }
    }
}
