//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 8.2.24.
//

import UIKit
import SwiftUI
import GoogleMobileAds

struct BannerView: View, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    
    var insideAdViewModel: InsideAdViewModel
    
    var body: some View {
        GeometryReader { geo in
            GoogleBannerViewWrapper(insideAdViewModel: insideAdViewModel, parent: self)
                .frame(width: 1, height: 1)
        }
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}

struct GoogleBannerViewWrapper: UIViewControllerRepresentable {
    var insideAdViewModel: InsideAdViewModel
    let parent: BannerView
    
    func makeUIViewController(context: Context) -> GoogleBannerViewModel {
        let controller = GoogleBannerViewModel(viewModel: insideAdViewModel, insideAdCallbackDelegate: parent)
//        controller.bannerView = GAMBannerView(adSize: GADAdSizeBanner)
//        controller.bannerView.rootViewController = controller
        return controller
    }
    
    func updateUIViewController(_ uiViewController: GoogleBannerViewModel, context: Context) {
        //
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: GoogleBannerViewWrapper
        
        init(parent: GoogleBannerViewWrapper) {
            self.parent = parent
        }
    }
}

class GoogleBannerViewModel: UIViewController {
    var viewModel: InsideAdViewModel
    var bannerView: GAMBannerView!
    var adSizes = [NSValue]()
    var insideAdCallbackDelegate: InsideAdCallbackDelegate
    
    init(viewModel: InsideAdViewModel, insideAdCallbackDelegate: InsideAdCallbackDelegate) {
        self.viewModel = viewModel
        self.insideAdCallbackDelegate = insideAdCallbackDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       setupBannerView()
    }

    private func setupBannerView() {
        bannerView = GAMBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = viewModel.activeInsideAd?.url
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.adSizeDelegate = self
        bannerView.enableManualImpressions = true
        addValidSizesToBannerView()
        bannerView.validAdSizes = adSizes
        bannerView.load(GADRequest())
    }
    
    private func addBannerToView() {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        bannerView.recordImpression()

        view.addConstraints(
              [NSLayoutConstraint(item: bannerView!,
                                  attribute: .bottom,
                                  relatedBy: .equal,
                                  toItem: view.safeAreaLayoutGuide,
                                  attribute: .bottom,
                                  multiplier: 1,
                                  constant: 0),
               NSLayoutConstraint(item: bannerView!,
                                  attribute: .centerX,
                                  relatedBy: .equal,
                                  toItem: view,
                                  attribute: .centerX,
                                  multiplier: 1,
                                  constant: 0)
              ])
    }
    
    
    private func addValidSizesToBannerView() {
        if let sizes =  viewModel.activeInsideAd?.properties?.sizes {
            for size in sizes {
                let customSize = GADAdSizeFromCGSize(CGSize(width: size.width ?? 320, height: size.height ?? 50))
                adSizes.append(NSValueFromGADAdSize(customSize))
            }
        } else {
            adSizes.append(NSValueFromGADAdSize(GADAdSizeBanner))
        }
    }
}

// Delegate methods
extension GoogleBannerViewModel: GADBannerViewDelegate, GADAdSizeDelegate {
    func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
        print("bannerViewDidRecordImpression willChangeAdSizeTo size: GADAdSize \(size)")
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        addBannerToView()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(viewModel.activeInsideAd?.properties?.durationInSeconds ?? 10)) {
            bannerView.removeFromSuperview()
            print("bannerViewDidReceiveAd")
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        insideAdCallbackDelegate.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: error.localizedDescription ))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds((Int(viewModel.activeCampaign?.properties?.intervalInMinutes ?? "1") ?? 1 * 60) + (viewModel.activeInsideAd?.properties?.durationInSeconds ?? 1))) {
            NotificationCenter.post(name: .AdsContentView_startTimer)
            print("bannerViewErrorReceivedNewReqeustSent")
        }
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds((Int(viewModel.activeCampaign?.properties?.intervalInMinutes ?? "1") ?? 1 * 60) + (viewModel.activeInsideAd?.properties?.durationInSeconds ?? 1))) {
            NotificationCenter.post(name: .AdsContentView_startTimer)
            print("bannerViewDidRecordImpression")
        }
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
