//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 8.2.24.
//

import UIKit
import SwiftUI
import GoogleMobileAds

struct BannerAdViewWrapper: UIViewRepresentable, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    
    func makeUIView(context: Context) -> UIView {
        if AdsManager.shared.bannerAdViewController == nil {
            AdsManager.shared.bannerAdViewController = BannerAdViewController()
            AdsManager.shared.bannerAdViewController?.insideAdCallbackDelegate = self
            AdsManager.shared.bannerAdViewController?.setupBannerView()
        }

        return AdsManager.shared.bannerAdViewController!.bannerView
    }
    
    func updateUIView(_ uiViewController: UIView, context: Context) {
        //
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
        print("delegateState \(data)")
    }
}

class BannerAdViewController: UIViewController, ObservableObject {
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
    var adSizes = [NSValue]()
    var bannerView: GAMBannerView = GAMBannerView(adSize: GADAdSizeBanner)

    override func viewDidLoad() {
        
    }

    func setupBannerView() {
        bannerView.adUnitID = CampaignManager.shared.activeInsideAd?.url
        bannerView.rootViewController = AdsManager.shared.bannerAdViewController
        bannerView.delegate = self
        bannerView.adSizeDelegate = self
        
        loadBannerAd()
    }

    func loadBannerAd() {
        let frame = view.frame.inset(by: view.safeAreaInsets)
        let viewWidth = frame.size.width
        
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        addValidSizesToBannerView()
        bannerView.validAdSizes = adSizes
        
        
        self.bannerView.load(GADRequest())
        self.view.addSubview(self.bannerView)
    }

    private func addValidSizesToBannerView() {
        if let sizes = CampaignManager.shared.activeInsideAd?.properties?.sizes {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(CampaignManager.shared.activeInsideAd?.properties?.durationInSeconds ?? 10 + Int(CampaignManager.shared.startAfterSeconds))) {
            bannerView.removeFromSuperview()
            self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertEventType(type: .ALL_ADS_COMPLETED))
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: error.localizedDescription ))
        // Handle fallback
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
