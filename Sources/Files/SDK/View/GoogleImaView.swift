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

class InsideAdViewController: UIViewController, ObservableObject {

    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private let adsLoader = IMAAdsLoader(settings: nil)
    private var adsManager: IMAAdsManager?
    let imaSettings = IMASettings()
    private var volumeButton: UIButton?
    private var imaadPlayerView: UIView?

    private var geoModel: GeoIp?
    private var insideAdHelper = InsideAdHelper()
    
    var screen = ""
    var viewSize: CGSize = CGSize(width: 300, height: 250)
    
    
    //Delegates
    var insideAdCallbackDelegate: InsideAdCallbackDelegate
    
    var insideAd: InsideAd?
    var activePlacement: Placement?
    var geoIp: GeoIp?
    
//    let insideAdPlayerErrorStateDelegate: InsideAdPlayerErrorStateDelegate
//    @Published var errorLoadingAds = false
    
    init(insideAdCallbackDelegate: InsideAdCallbackDelegate) {
        self.insideAdCallbackDelegate = insideAdCallbackDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods
    override func viewDidLoad() {
         super.viewDidLoad()
         
         addImmadPlayerView()
//         addVolumeButton()
         adsLoader.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.requestAds(screen: self.screen)
    }
     
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
          button.setImage(UIImage(systemName: Constants.ResellerInfo.isAdMuted ? "speaker.slash.fill" : "speaker.fill"), for: .normal)
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
          volumeButton?.setImage(UIImage(systemName: Constants.ResellerInfo.isAdMuted ? "speaker.slash.fill" : "speaker.fill"), for: .normal)
     }

    // MARK: IMA integration methods
    func requestAds(screen: String) {
        
        let activeInsideAd = insideAd
        let url = activeInsideAd?.url
        
        if let url = url, let geoIp = geoIp{
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
            
            let startAfterSeconds:Double = Double(activePlacement?.properties?.startAfterSeconds ?? 0) 
            
            DispatchQueue.main.asyncAfter(deadline: .now() + startAfterSeconds) {[weak self] in
                self?.adsLoader.requestAds(with: request)
            }
        }
    }
}

//IMA Delegate methods
extension InsideAdViewController:IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
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
        insideAdCallbackDelegate.insideAdCallbackReceived(data: convertErrorType(message: adErrorData.adError.message ?? ""))
        //        self.view.removeFromSuperview()
        print(Logger.log("\(adErrorData.adError.message ?? "Unknown error")"))
    }
    
    // MARK: - IMAAdsManagerDelegate
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == IMAAdEventType.LOADED {
            //Add the volume button only when ads is loaded
            addVolumeButton()
            // When the SDK notifies us that ads have been loaded, play them.
            adsManager.start()
        }
        insideAdCallbackDelegate.insideAdCallbackReceived(data: convertEventType(type: event.type))
        print(Logger.log(event.typeString))
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        // Something went wrong with the ads manager after ads were loaded. Log the error and play the
        // content.
        insideAdCallbackDelegate.insideAdCallbackReceived(data: convertErrorType(message: error.message ?? ""))
        //        self.view.removeFromSuperview()
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
        print("buffering started")
    }
    
    func convertEventType(type: IMAAdEventType) -> InsideAdCallbackType {
        switch type {
        case .AD_BREAK_READY: return InsideAdCallbackType.AD_BREAK_READY
        case .AD_BREAK_FETCH_ERROR: return InsideAdCallbackType.AD_BREAK_FETCH_ERROR
        case .AD_BREAK_ENDED: return InsideAdCallbackType.AD_BREAK_ENDED
        case .AD_BREAK_STARTED: return InsideAdCallbackType.AD_BREAK_STARTED
        case .AD_PERIOD_ENDED: return InsideAdCallbackType.AD_PERIOD_ENDED
        case .AD_PERIOD_STARTED: return InsideAdCallbackType.AD_PERIOD_STARTED
        case .ALL_ADS_COMPLETED: return InsideAdCallbackType.ALL_ADS_COMPLETED
        case .CLICKED: return InsideAdCallbackType.CLICKED
        case .COMPLETE: return InsideAdCallbackType.COMPLETE
        case .CUEPOINTS_CHANGED: return InsideAdCallbackType.CUEPOINTS_CHANGED
        case .ICON_FALLBACK_IMAGE_CLOSED: return InsideAdCallbackType.ICON_FALLBACK_IMAGE_CLOSED
        case .ICON_TAPPED: return InsideAdCallbackType.ICON_TAPPED
        case .FIRST_QUARTILE: return InsideAdCallbackType.FIRST_QUARTILE
        case .LOADED: return InsideAdCallbackType.LOADED
        case .LOG: return InsideAdCallbackType.LOG
        case .MIDPOINT: return InsideAdCallbackType.MIDPOINT
        case .PAUSE: return InsideAdCallbackType.PAUSE
        case .RESUME: return InsideAdCallbackType.RESUME
        case .SKIPPED: return InsideAdCallbackType.SKIPPED
        case .STARTED: return InsideAdCallbackType.STARTED
        case .STREAM_LOADED: return InsideAdCallbackType.STREAM_LOADED
        case .STREAM_STARTED: return InsideAdCallbackType.STREAM_STARTED
        case .TAPPED: return InsideAdCallbackType.TAPPED
        case .THIRD_QUARTILE: return InsideAdCallbackType.THIRD_QUARTILE
            
        @unknown default:
            return InsideAdCallbackType.UNKNOWN
        }
    }
    
    private func convertErrorType(message: String) -> InsideAdCallbackType{
        let errorType = InsideAdCallbackType.IMAAdError(message)
        NotificationCenter.post(name: .AdsContentView_setZeroSize)
//        print(errorType)
        return errorType
    }
}

struct InsideAdViewWrapper: UIViewControllerRepresentable {
//    @Binding var errorLoadingAds: Bool
    var screen: String
    let parent: InsideAdView
    var viewSize: CGSize
    
    @Binding var insideAd: InsideAd?
    @Binding var activePlacement: Placement?
    @Binding var geoIp: GeoIp?
    
//    @Binding var callback: InsideAdCallbackType
    
    func makeUIViewController(context: Context) -> InsideAdViewController {
        let controller = InsideAdViewController(insideAdCallbackDelegate: parent)
        controller.screen = screen
        controller.viewSize = viewSize
        controller.insideAd = insideAd
        controller.activePlacement = activePlacement
        controller.geoIp = geoIp
        return controller
    }
    
    func updateUIViewController(_ uiViewController: InsideAdViewController, context: Context) {
        //
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: InsideAdViewWrapper
        
        init(parent: InsideAdViewWrapper) {
            self.parent = parent
        }
    }
}
