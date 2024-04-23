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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let volumeButton = volumeButton{
            view.bringSubviewToFront(volumeButton)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        volumeButton?.removeFromSuperview()
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
        print(Logger.log(" Volume changed to: \(adsManager?.volume ?? 0)"))
        setImmadVolume()
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
            }
        }
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
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: adErrorData.adError.message ?? ""))
        //TODO: - request fallback logic to be implemented
        
            // Start the timer to call the next ad interval
//            volumeButton?.removeFromSuperview()
            print(Logger.log("\(adErrorData.adError.message ?? "Unknown error")"))
//        }
    }
    
    // MARK: - IMAAdsManagerDelegate
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == IMAAdEventType.LOADED {
            // When the SDK notifies us that ads have been loaded, play them.
            adsManager.start()
            
        }
        
        if event.type == IMAAdEventType.STARTED {
            //Add the volume button only when ads is started
            addVolumeButton()
        }
        
        if event.type == IMAAdEventType.TAPPED {
            if !adsManager.adPlaybackInfo.isPlaying {
                adsManager.resume()
            }
        }
        
        if event.type == IMAAdEventType.RESUME {
            NotificationCenter.post(name: .AdsContentView_restoreSize)
            adsManager.resume()
        }
        
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertEventType(type: event.type))
        print(Logger.log(event.typeString))
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        // Something went wrong with the ads manager after ads were loaded. Log the error and play the
        // content.
        //TODO: - request fallback logic to be implemented
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: error.message ?? ""))
        print(Logger.log("\(error.message ?? "Unknown error")"))
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause the content.
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // The SDK is done playing ads (at least for now), so resume the content.
        
        //Remove the volume button when ads finishes do not be visible on the view
        volumeButton?.removeFromSuperview()
    }
    
    func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager) {
        //
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
