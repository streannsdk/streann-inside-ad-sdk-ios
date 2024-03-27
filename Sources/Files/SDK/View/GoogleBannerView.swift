//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 8.2.24.
//

import UIKit
import SwiftUI
import GoogleMobileAds

struct BannerAdViewWrapper: UIViewRepresentable {
    var insideAdCallback: InsideAdView
    
    func makeUIView(context: Context) -> UIView {
        InsideAdSdk.shared.bannerAdViewController.insideAdCallbackDelegate = insideAdCallback
        InsideAdSdk.shared.bannerAdViewController.setupBannerView()
        InsideAdSdk.shared.bannerAdViewController.loadBannerAd()
        return InsideAdSdk.shared.bannerAdViewController.bannerView
    }
    
    func updateUIView(_ uiViewController: UIView, context: Context) {
        //
    }
}

class BannerAdViewController: UIViewController, ObservableObject {
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
    var adSizes = [NSValue]()
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    var bannerView: GAMBannerView = GAMBannerView(adSize: GADAdSizeBanner)

    override func viewDidLoad() {
        
    }

    func setupBannerView() {
        switch adRequestStatus {
            case .adRequested:
                bannerView.adUnitID = InsideAdSdk.shared.activeInsideAd?.url
            case .fallbackRequested:
            bannerView.adUnitID = InsideAdSdk.shared.activeInsideAd?.fallback?.url
        }

        bannerView.rootViewController = InsideAdSdk.shared.bannerAdViewController
        bannerView.delegate = self
        bannerView.adSizeDelegate = self
        adRequestStatus = (adRequestStatus == .fallbackRequested) ? .adRequested : .fallbackRequested
    }

    func loadBannerAd() {
        let frame = view.frame.inset(by: view.safeAreaInsets)
        let viewWidth = frame.size.width
        
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        addValidSizesToBannerView()
        bannerView.validAdSizes = adSizes
        
        adRequestStatus = (adRequestStatus == .fallbackRequested) ? .adRequested : .fallbackRequested
        
        self.bannerView.load(GADRequest())
        self.view.addSubview(self.bannerView)
    }

    private func addValidSizesToBannerView() {
        if let sizes = adRequestStatus == .adRequested ? InsideAdSdk.shared.activeInsideAd?.properties?.sizes :  InsideAdSdk.shared.activeInsideAd?.fallback?.properties?.sizes {
            for size in sizes {
                let customSize = GADAdSizeFromCGSize(CGSize(width: size.width ?? 320, height: size.height ?? 50))
                adSizes.append(NSValueFromGADAdSize(customSize))
            }
        } else {
            adSizes.append(NSValueFromGADAdSize(GADAdSizeBanner))
        }
    }
}

extension BannerAdViewController: GADBannerViewDelegate, GADAdSizeDelegate {
    func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
        print("bannerViewDidRecordImpression willChangeAdSizeTo size: GADAdSize \(size)")
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        let startAfterSeconds:Double = InsideAdSdk.shared.activeInsideAd?.adType != .FULLSCREEN_NATIVE ? Double(InsideAdSdk.shared.activePlacement?.properties?.startAfterSeconds ?? 0) : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + startAfterSeconds) {
            self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertEventType(type: .LOADED))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(InsideAdSdk.shared.activeInsideAd?.properties?.durationInSeconds ?? 10 + Int(startAfterSeconds))) {
            bannerView.removeFromSuperview()
            self.adRequestStatus = .adRequested
            self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertEventType(type: .ALL_ADS_COMPLETED))
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        if adRequestStatus == .fallbackRequested {
            setupBannerView()
            loadBannerAd()
        } else {
            NotificationCenter.post(name: .AdsContentView_startTimer)
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: error.localizedDescription ))
            adRequestStatus = .adRequested
        }
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewDidDismissScreen")
    }
}
