//
//  GADNativeViewWrapper.swift
//  AdmobNativeSample
//
//

import UIKit
import SwiftUI
import GoogleMobileAds

struct GADNativeViewControllerWrapper : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GADNativeViewController {
        let viewController = GADNativeViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GADNativeViewController, context: Context) {
        if let nativeAd = CampaignManager.shared.adLoader?.nativeAd {
            uiViewController.displayLoadedAd(nativeAd: nativeAd)
        }
    }
    
}

struct NativeAdView: View {
    public var body: some View {
        GADNativeViewControllerWrapper()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .ignoresSafeArea()
    }
}


class NativeAdLoaderViewModel: NSObject, ObservableObject {
    @Published var nativeAd: GADNativeAd?
    private var adLoader: GADAdLoader?
    private var unitId = ""
    
    init(unitAd: String) {
        super.init()
        self.unitId = unitAd
        loadAd()
    }
    
    func loadAd() {
        let options = GADNativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .any
        adLoader = GADAdLoader(adUnitID: unitId, rootViewController: createRootController(), adTypes: [.native], options: [options])
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }
}

extension NativeAdLoaderViewModel: GADNativeAdLoaderDelegate, GADAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        DispatchQueue.main.async {
            self.nativeAd = nativeAd
            print(Logger.log("Native ad loaded"))
        }
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print(Logger.log("\(adLoader) failed with error: \(error.localizedDescription)"))
    }
    
    private func createRootController() -> UIViewController {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        guard let rootViewController = window?.rootViewController else {
            print(Logger.log("Native add root controller creation failed"))
            return UIViewController()
        }
        return rootViewController
    }
}
