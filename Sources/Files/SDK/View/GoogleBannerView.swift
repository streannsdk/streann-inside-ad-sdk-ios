//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 8.2.24.
//

// Google Mobile Ads ships no tvOS slice, so banner ads are iOS-only.
#if os(iOS)

import UIKit
import SwiftUI
import GoogleMobileAds

struct BannerAdViewWrapper: UIViewRepresentable, InsideAdCallbackDelegate {
    let slot: AdSlot
    
    func makeUIView(context: Context) -> UIView {
        if slot.bannerAdViewController == nil {
            let controller = BannerAdViewController(slot: slot)
            controller.insideAdCallbackDelegate = self
            slot.bannerAdViewController = controller
            controller.setupBannerView()
        }
        return slot.bannerAdViewController!.bannerView
    }
    
    func updateUIView(_ uiViewController: UIView, context: Context) {
        //
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        slot.insideAdCallback = data
        print("delegateState \(data)")
    }
}

class BannerAdViewController: UIViewController, ObservableObject {
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
    var adSizes = [NSValue]()
    var bannerView: GAMBannerView = GAMBannerView(adSize: GADAdSizeBanner)

    /// The placement this banner belongs to.
    private unowned let slot: AdSlot

    init(slot: AdSlot) {
        self.slot = slot
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        
    }

    func setupBannerView() {
        bannerView.adUnitID = slot.activeInsideAd?.url
        bannerView.rootViewController = self
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
        
        
        slot.reportRequested()
        self.bannerView.load(GADRequest())
        self.view.addSubview(self.bannerView)
    }

    private func addValidSizesToBannerView() {
        if let sizes = slot.activeInsideAd?.properties?.sizes {
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
        print("bannerView willChangeAdSizeTo size: GADAdSize \(size)")
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: .STARTED)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(slot.activeInsideAd?.properties?.durationInSeconds ?? 10 + Int(slot.startAfterSeconds))) {
            bannerView.removeFromSuperview()
            self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ALL_ADS_COMPLETED)
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(error.localizedDescription))
        slot.insideAdCallback = .TRIGGER_FALLBACK
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

#endif
