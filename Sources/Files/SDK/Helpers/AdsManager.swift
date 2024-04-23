//
//  AdsManager.swift
//  TestTheLibrary
//
//  Created by Igor Parnadziev on 19.4.24.
//

import Foundation
import UIKit

class AdsManager: ObservableObject {
    static let shared = AdsManager()
    
    @Published var insideAdCallback: InsideAdCallbackType = .UNKNOWN{
        didSet{
            if insideAdCallback == .STARTED {
                setFullSize()
            }
            else if insideAdCallback == .ALL_ADS_COMPLETED {
                CampaignManager.shared.invalidateActiveAds()
                clearAll()
                startTimerForNextAd()
            }
        }
    }

    @Published var adViewWidth: CGFloat = 0
    @Published var adViewHeight: CGFloat = 0
    @Published var timerNextAd: Timer? = nil
    @Published var localImageManager = LocalImageManager()
    @Published var localVideoManager = LocalVideoManager()
    
    var vastController: VastViewController?
    var bannerAdViewController: BannerAdViewController?
    
    func clearAll() {
        vastController = nil
        bannerAdViewController = nil
        AdsManager.shared.localVideoManager.player.replaceCurrentItem(with: nil)
        setZeroSize()
        
        timerNextAd = nil
        timerNextAd?.invalidate()
    }
    
    func setFullSize(){
        adViewHeight = UIScreen.main.bounds.width / 16 * 9
        adViewWidth = .infinity
    }
    
    func setZeroSize(){
        adViewHeight = 0
        adViewWidth = 0
    }
    
    func startTimerForNextAd(){
        timerNextAd?.invalidate()
        timerNextAd = nil
        
        let intervalInMinutes = CampaignManager.shared.activeCampaign?.properties?.intervalInMinutes
        
        
        if let intervalInMinutes, intervalInMinutes > 0 {
            print(Logger.log("DEBUG: Timer started for next ad - intervalInMinutes \(intervalInMinutes)"))
            timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes.convertMinutesToSeconds()), repeats: false){ _ in
                CampaignManager.shared.findActiveAdForScreen()
            }
        }else{
            print(Logger.log("Timer not started - intervalInMinutes \(intervalInMinutes ?? 0)"))
        }
    }
}
