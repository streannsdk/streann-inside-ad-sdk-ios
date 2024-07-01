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
    private let adsLoader = IMAAdsLoader(settings: nil)
    private var adsManager: IMAAdsManager?
    private var volumeButton: UIButton?
    
    private var insideAdHelper = InsideAdHelper()
    var imaadPlayerView: UIView?
    
    var viewSize: CGSize = CGSize(width: 300, height: 250)
    
    //Delegates
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
        
    init() {
        super.init(nibName: nil, bundle: nil)
        adsLoader.delegate = self
        addImmadPlayerView()

        NotificationCenter.default.addObserver(self, selector: #selector(self.changeAdVolume(notification:)), name: Notification.Name("changeInsideAdSdkAdVolume"), object: nil)
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
    
    private func addImmadPlayerView(){
        let newView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        //Make the view's background color to clear do not be visible when incative
        newView.backgroundColor = .clear
        view.addSubview(newView)
        imaadPlayerView = view
    }
    
    private func addVolumeButton(){
        let button = UIButton(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
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
        if let notification = notification.userInfo?["isAdMuted"] as? Bool {
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
        let url = activeInsideAd?.url
        
        if let url = url, let geoIp = CampaignManager.shared.geoIp {
            //Populate macros
            let adTagUrl = self.insideAdHelper.populateVastFrom(adUrl: url, geoModel: geoIp, playerSize: self.viewSize)
            
            // Create ad display container for ad rendering.
            let adDisplayContainer = IMAAdDisplayContainer(
                adContainer: self.imaadPlayerView!, viewController: self, companionSlots: nil)
            
            // Create an ad request with our ad tag, display container, and optional user context.
            let request = IMAAdsRequest(
                adTagUrl: adTagUrl,
                adDisplayContainer: adDisplayContainer,
                contentPlayhead: self.contentPlayhead,
                userContext: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + CampaignManager.shared.startAfterSeconds) {[weak self] in
                self?.adsLoader.requestAds(with: request)
                print(Logger.logVast("AD REQUESTED"))
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("changeInsideAdSdkAdVolume"), object: nil)
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
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerPresentingController = self
        
        // Initialize the ads manager.
        adsManager?.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(adErrorData.adError.message ?? ""))
        
        AdsManager.shared.insideAdCallback = .TRIGGER_FALLBACK
        
        print(Logger.log("\(adErrorData.adError.message ?? "Unknown error")"))
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
        }
        
        print(Logger.logVast(event.typeString))
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(error.message ?? ""))
       
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .TRIGGER_FALLBACK)
        
        print(Logger.logVast("\(error.message ?? "unknown error")"))
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
