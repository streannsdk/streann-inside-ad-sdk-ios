//
//  GoogleImaView.swift
//  TestTheLibrary
//
//  Created by Fani on 9.1.24.
//

import SwiftUI
import GoogleInteractiveMediaAds
import UIKit
import AVFoundation

class VastViewController: UIViewController, ObservableObject {
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private let adsLoader: IMAAdsLoader = {
        let settings = IMASettings()
        settings.enableBackgroundPlayback = false
        settings.autoPlayAdBreaks = true
        settings.language = "en"
        settings.playerType = "ios-video-player"
        settings.playerVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return IMAAdsLoader(settings: settings)
    }()
    private var adsManager: IMAAdsManager?
    private var volumeButton: UIButton?
    private let button = UIButton(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
    private var insideAdHelper = InsideAdHelper()
    var imaadPlayerView: UIView?

    var viewSize: CGSize = CGSize(width: 300, height: 250)

    // Retry logic for VAST requests
    private var retryCount = 0
    private let maxRetries = 5
    private let retryDelay: TimeInterval = 2.0  // seconds between retries

    //Delegates
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
        
    init() {
        super.init(nibName: nil, bundle: nil)
        adsLoader.delegate = self
        addImmadPlayerView()

        NotificationCenter.default.addObserver(self, selector: #selector(self.changeAdVolume(notification:)), name: Notification.Name(Constants.Notifications.changeInsideAdSdkAdVolume), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let volumeButton = volumeButton{
            view.bringSubviewToFront(volumeButton)
        }
    }

    // in some cases when the device is rotated the volume button is in an opposite direction, so this condition can modify the image if necessary
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if UIDevice.current.orientation.isLandscape && CampaignManager.shared.rotateVolumeButton ?? false {
            button.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        } else {
            button.transform = CGAffineTransform(rotationAngle: 0)
        }
    }
    
    private func addImmadPlayerView(){
        let newView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        //Make the view's background color to clear do not be visible when incative
        newView.backgroundColor = .clear
        view.addSubview(newView)
        imaadPlayerView = view
    }
    
     private func removeImmadPlayerView() {
        imaadPlayerView?.removeFromSuperview()
        imaadPlayerView = nil
    }

    func cleanup() {
        volumeButton?.removeFromSuperview()
        volumeButton = nil
        removeImmadPlayerView()
    }
    
    private func addVolumeButton(){
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setImage(UIImage(systemName: Constants.ResellerInfo.isAdMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerFill), for: .normal)
        button.addTarget(self, action: #selector(volumeButtonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        view.bringSubviewToFront(button)
        volumeButton = button
    }
    
    @objc private func volumeButtonAction(_ sender: UIButton) {
        Constants.ResellerInfo.isAdMuted = !Constants.ResellerInfo.isAdMuted
       
        setImmadVolume()
        
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .VOLUME_CHANGED(Int(adsManager?.volume ?? 0)))
        
        print(Logger.log("Volume changed to: \(adsManager?.volume ?? 0)"))
    }

    @objc func changeAdVolume(notification: Notification) {
        if let notification = notification.userInfo?[Constants.Notifications.isAdMuted] as? Bool {
            Constants.ResellerInfo.isAdMuted = !notification
            setImmadVolume()
        }
    }
    
    private func setImmadVolume(){
        adsManager?.volume = Constants.ResellerInfo.isAdMuted ? 0 : 1
        volumeButton?.setImage(UIImage(systemName: Constants.ResellerInfo.isAdMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerFill), for: .normal)
    }
    
    // MARK: IMA integration methods
    func requestAds() {
        let activeInsideAd = CampaignManager.shared.activeInsideAd
        guard let url = activeInsideAd?.url, let geoIp = CampaignManager.shared.geoIp else {
            print(Logger.log("No active ad or GeoIP data available"))
            return
        }

        //Populate macros
        let adTagUrl = self.insideAdHelper.populateVastFrom(adUrl: url, geoModel: geoIp, playerSize: self.viewSize)
        InsideAdSdk.shared.vastTagUrl = adTagUrl

        // Create ad display container for ad rendering.
        let adDisplayContainer = IMAAdDisplayContainer(
            adContainer: self.imaadPlayerView!, viewController: self, companionSlots: nil)

        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: adTagUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: self.contentPlayhead,
            userContext: nil)

        //timeout in milliseconds - 30sec (increased to handle multiple VAST wrappers)
        request.vastLoadTimeout = 30000

        DispatchQueue.main.asyncAfter(deadline: .now() + CampaignManager.shared.startAfterSeconds) {[weak self] in
            self?.adsLoader.requestAds(with: request)
            print(Logger.logVast("AD REQUESTED"))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.Notifications.changeInsideAdSdkAdVolume), object: nil)
    }
}

//IMA Delegate methods
extension VastViewController:IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    // MARK: - IMAAdsLoaderDelegate
    func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager) {
        setImmadVolume()
        adsManager.start()
    }
    
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self

        print(Logger.logVast("✅ VAST loaded successfully"))
        if retryCount > 0 {
            print(Logger.logVast("✅ Success after \(retryCount) retries!"))
        }

        // Reset retry count on success
        retryCount = 0

        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerPresentingController = self

        // Initialize the ads manager.
        adsManager?.initialize(with: adsRenderingSettings)
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        let errorMessage = adErrorData.adError.message ?? "Unknown error"
        let errorCode = adErrorData.adError.code
        let errorType = adErrorData.adError.type

        print(Logger.log("VAST Error - Message: \(errorMessage), Code: \(errorCode.rawValue), Type: \(errorType.rawValue)"))
        print(Logger.log("VAST Tag URL: \(InsideAdSdk.shared.vastTagUrl ?? "N/A")"))

        // Retry logic for error 303 (No Ads VAST response after wrappers)
        if errorCode.rawValue == 303 && retryCount < maxRetries {
            retryCount += 1
            print(Logger.logVast("⚠️ Error 303 detected. Retrying... (Attempt \(retryCount) of \(maxRetries))"))

            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                self?.requestAds()
            }
            return
        }

        // Max retries reached or different error - trigger fallback
        print(Logger.log("❌ Max retries reached or non-retryable error. Triggering fallback."))
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(errorMessage))
        AdsManager.shared.insideAdCallback = .TRIGGER_FALLBACK
        InsideAdSdk.shared.vastErrorMessage = errorMessage
    }
    
    // MARK: - IMAAdsManagerDelegate
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == .LOADED {
            adsManager.start()
        }
        
        else if event.type == .STARTED {
            //Add the volume button only when ads is started
            addVolumeButton()
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: .STARTED)
        }
        
        else if event.type == .TAPPED {
            if !adsManager.adPlaybackInfo.isPlaying {
                adsManager.resume()
            }
        }
        
        else if event.type == .RESUME {
            NotificationCenter.post(name: .AdsContentView_restoreSize)
            adsManager.resume()
        }
        
        else if event.type == .ALL_ADS_COMPLETED{
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ALL_ADS_COMPLETED)
            removeImmadPlayerView()
        }
        
        print(Logger.logVast(event.typeString))
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(error.message ?? ""))
       
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .TRIGGER_FALLBACK)
        
        print(Logger.logVast("\(error.message ?? "unknown error")"))
        InsideAdSdk.shared.vastErrorMessage = "\(error.message ?? "unknown error")"
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause the content.
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // The SDK is done playing ads (at least for now), so resume the content.
    }
    
    func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager) {
    }
}

struct VastViewWrapper: UIViewRepresentable, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType

    func makeUIView(context: Context) -> UIView {
        if AdsManager.shared.vastController == nil {
            AdsManager.shared.vastController = VastViewController()
            AdsManager.shared.vastController?.insideAdCallbackDelegate = self
            AdsManager.shared.vastController?.requestAds()
        }
        return AdsManager.shared.vastController!.imaadPlayerView!
    }
    
    func updateUIView(_ uiViewController: UIView, context: Context) {
        //
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}
