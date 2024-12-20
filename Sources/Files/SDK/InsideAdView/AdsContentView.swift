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
    
    public init(delegate: InsideAdCallbackDelegate, screen: String?, isAdMuted: Bool, targetModel: TargetModel?, rotateVolumeButton: Bool? = false) {
        
        self.delegate = delegate
        campaignManager.screen = screen
        campaignManager.targetModel = targetModel
        Constants.ResellerInfo.isAdMuted = isAdMuted

        // in some cases when the device is rotated the volume button is in an opposite direction, so this condition can modify the image if necessary
        campaignManager.rotateVolumeButton = rotateVolumeButton

        //If adLoaded is true, set the activeCampaign, activeInsideAd and activePlacement otherwise don't initialize them
        if campaignManager.fetchCompleted {
            self.findActiveAdForScreen()
        }
    }
    
    var body: some View {
        ZStack {
            if let activeInsideAd = CampaignManager.shared.activeInsideAd {
                Group {
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
        .id(adViewId)
        .frame(maxWidth: adsManager.adViewWidth, maxHeight:  adsManager.adViewHeight)
//        .opacity(adsManager.adViewHeight == 0 ? 0 : 1)
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
            //Send the callback to the delegate
            self.delegate?.insideAdCallbackReceived(data: newValue)
        }
        .onAppear(perform: {
            print(Logger.log("AdsContentView APPEARED"))
        })
        .onDisappear{
            //If the device is rotated, don't reset the ad otherwise reset the ad
            if !campaignManager.isDeviceRotated {
                adsManager.insideAdCallback = .AD_VIEW_DISAPPEARED
            } else {
                campaignManager.isDeviceRotated = false
            }
        }
    }
    
    private func findActiveAdForScreen(){
        //If the insideAdCallback is UNKNOWN or ALL_ADS_COMPLETED and the timerNextAd is nil, find the active ad for the screen
        //adsManager.timerNextAd == nil is needed to prevent the view to find another ad while phone is being rotated
        if (adsManager.insideAdCallback == .UNKNOWN ||
            adsManager.insideAdCallback == .ALL_ADS_COMPLETED ||
            adsManager.insideAdCallback == .AD_VIEW_DISAPPEARED) &&
            adsManager.timerNextAd == nil{
            
            campaignManager.findActiveAdForScreen()
        }
    }
}
