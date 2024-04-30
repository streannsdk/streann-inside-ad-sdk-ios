//
//  GADNativeViewController.swift
//  AdmobNativeSample
//
//  Created by Sakura on 2021/05/07.
//

import UIKit
import GoogleMobileAds

class GADNativeViewController: UIViewController {
    
    /// The native ad view that is being presented.
    var nativeAdView: GADNativeAdView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let nibObjects = Bundle.module.loadNibNamed("NativeAdView", owner: nil, options: nil),
            let adView = nibObjects.first as? GADNativeAdView
        else {
            print("Could not load nib file for adView")
            return
        }
        self.setAdView(adView)
    }
    
    func setAdView(_ view: GADNativeAdView) {
        nativeAdView = view
        nativeAdView.frame = self.view.bounds
        self.view.addSubview(nativeAdView)
        nativeAdView.callToActionView?.isHidden = true
        
        DispatchQueue.main.async { [weak self] in
            // Populate the native ad view with the native ad assets.
            // The headline and mediaContent are guaranteed to be present in every native ad.
            (self?.nativeAdView.headlineView as? UILabel)?.text = CampaignManager.shared.adLoader?.nativeAd?.headline
            self?.nativeAdView.mediaView?.mediaContent = CampaignManager.shared.adLoader?.nativeAd?.mediaContent
            
            // Some native ads will include a video asset, while others do not. Apps can use the
            // GADVideoController's hasVideoContent property to determine if one is present, and adjust their
            // UI accordingly.
            let mediaContent = CampaignManager.shared.adLoader?.nativeAd?.mediaContent
            if ((mediaContent?.hasVideoContent) != nil) {
                // By acting as the delegate to the GADVideoController, this ViewController receives messages
                // about events in the video lifecycle.
                mediaContent?.videoController.delegate = self
                print("Ad contains a video asset.")
            } else {
                print("Ad does not contain a video.")
            }
            
            let color = CampaignManager.shared.adLoader?.nativeAd?.mediaContent.mainImage?.averageColor
            self?.setGradientBackground(averageColor: color ?? .black)
            
            // These assets are not guaranteed to be present. Check that they are before
            // showing or hiding them.
            (self?.nativeAdView.bodyView as? UILabel)?.text = CampaignManager.shared.adLoader?.nativeAd?.body
            self?.nativeAdView.bodyView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.body == nil
            
            (self?.nativeAdView.callToActionView as? UIButton)?.setTitle(CampaignManager.shared.adLoader?.nativeAd?.callToAction, for: .normal)
            self?.nativeAdView.callToActionView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.callToAction == nil
            
            (self?.nativeAdView.iconView as? UIImageView)?.image = CampaignManager.shared.adLoader?.nativeAd?.icon?.image
            self?.nativeAdView.iconView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.icon == nil
            
            (self?.nativeAdView.starRatingView as? UIImageView)?.image = self?.imageOfStars(from: CampaignManager.shared.adLoader?.nativeAd?.starRating)
            self?.nativeAdView.starRatingView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.starRating == nil
            
            (self?.nativeAdView.storeView as? UILabel)?.text = CampaignManager.shared.adLoader?.nativeAd?.store
            self?.nativeAdView.storeView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.store == nil
            
            (self?.nativeAdView.priceView as? UILabel)?.text = CampaignManager.shared.adLoader?.nativeAd?.price
            self?.nativeAdView.priceView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.price == nil
            
            (self?.nativeAdView.advertiserView as? UILabel)?.text = CampaignManager.shared.adLoader?.nativeAd?.advertiser
            self?.nativeAdView.advertiserView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.advertiser == nil
            
            // In order for the SDK to process touch events properly, user interaction should be disabled.
            self?.nativeAdView.callToActionView?.isUserInteractionEnabled = false
            self?.nativeAdView.callToActionView?.isHidden = CampaignManager.shared.adLoader?.nativeAd?.store == nil
            self?.nativeAdView.callToActionView?.sizeToFit()
        }
    }
    
    func displayLoadedAd(nativeAd: GADNativeAd) {
        nativeAdView.nativeAd = nativeAd
    }
    
    /// Returns a `UIImage` representing the number of stars from the given star rating; returns `nil`
    /// if the star rating is less than 3.5 stars.
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}

extension GADNativeViewController: GADVideoControllerDelegate {
    func videoControllerDidEndVideoPlayback(_ videoController: GADVideoController) {
        print("Video playback has ended.")
    }
}

extension GADNativeViewController {
    
    private func setGradientBackground(averageColor: UIColor) {
        let colorTop =  averageColor.cgColor
        let colorBottom = averageColor.cgColor
        let colorMiddle = UIColor(.white).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorMiddle, colorBottom]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = self.view.bounds
        
        nativeAdView.mediaView?.layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - GADNativeAdDelegate implementation
extension GADNativeViewController: GADNativeAdDelegate {
    
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdIsMuted(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        
        let parameters = [kCIInputExtentKey: CIVector(cgRect: inputImage.extent)]
        guard let averageFilter = CIFilter(name: "CIAreaAverage", parameters: parameters) else { return nil }
        
        averageFilter.setValue(inputImage, forKey: kCIInputImageKey)
        guard let outputImage = averageFilter.outputImage else { return nil }
        
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(pixel[0]) / 255, green: CGFloat(pixel[1]) / 255, blue: CGFloat(pixel[2]) / 255, alpha: CGFloat(pixel[3]) / 255)
    }
}
