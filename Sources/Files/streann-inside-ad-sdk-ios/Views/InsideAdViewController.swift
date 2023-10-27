//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import Foundation
import GoogleInteractiveMediaAds

class InsideAdViewController: UIViewController, ObservableObject {
    private var videoView: UIView!
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private let adsLoader = IMAAdsLoader(settings: nil)
    private var adsManager: IMAAdsManager?
    private var geoModel: GeoIp?
    private var insideAdHelper = InsideAdHelper()
    
    var screen = ""
    var viewSize: CGSize
    
    //Delegates
    let insideAdCallbackDelegate: InsideAdCallbackDelegate
    
    init(insideAdCallbackDelegate: InsideAdCallbackDelegate, size: CGSize) {
        self.insideAdCallbackDelegate = insideAdCallbackDelegate
        self.viewSize = size
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        videoView = UIView(frame: CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height))
        self.view.addSubview(videoView)
        adsLoader.delegate = self
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        requestAds(screen: self.screen)
    }
    
    //Setup the new constraints on device rotation
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        videoView.frame = CGRect(origin: .zero, size: view.bounds.size)
    }
    
    //View constraints setup
    private func setupView() {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: IMA integration methods
    func requestAds(screen: String) {
        if Constants.ResellerInfo.apiKey == "" {
            print(Logger.log("Api Key is required. Please implement the initializeSdk method."))
            return
        }
        
        if Constants.ResellerInfo.baseUrl == "" {
            print(Logger.log("Base Url is required. Please implement the initializeSdk method."))
          return
        }
        
        SDKAPI.getGeoIpUrl { geoIpUrl, error in
            if let geoIpUrl {
                SDKAPI.getGeoIp(fromUrl: geoIpUrl.geoIpUrl) { geoIp, error in
                    if let geoIp {
                        SDKAPI.getCampaign(countryCode: geoIp.countryCode ?? "", screen: screen) { campaignAppModel, error in
                            if let campaignAppModel {
                                DispatchQueue.main.async {
                                    if let url = campaignAppModel.url {
                                        //Populate macros
                                        let adTagUrl = self.insideAdHelper.populateVastFrom(adUrl: url, geoModel: geoIp, playerSize: CGSize(width: self.videoView.frame.width, height: self.videoView.frame.height))
                                        
                                        // Create ad display container for ad rendering.
                                        let adDisplayContainer = IMAAdDisplayContainer(
                                            adContainer: self.videoView, viewController: self, companionSlots: nil)
                                        
                                        // Create an ad request with our ad tag, display container, and optional user context.
                                        let request = IMAAdsRequest(
                                            adTagUrl: adTagUrl,
                                            adDisplayContainer: adDisplayContainer,
                                            contentPlayhead: self.contentPlayhead,
                                            userContext: nil)
                                        self.adsLoader.requestAds(with: request)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

//IMA Delegate methods
extension InsideAdViewController:IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    // MARK: - IMAAdsLoaderDelegate
    func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager) {
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
        print(Logger.log("\(adErrorData.adError.message ?? "Unknown error")"))
    }
    
    // MARK: - IMAAdsManagerDelegate
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == IMAAdEventType.LOADED {
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
        print(Logger.log("\(error.message ?? "Unknown error")"))
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause the content.
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // The SDK is done playing ads (at least for now), so resume the content.
    }
}

//Convert IMAAdEventType to InsideAdCallbackTypeModel
extension InsideAdViewController {
    private func convertEventType(type: IMAAdEventType) -> InsideAdCallbackType {
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
        return errorType
    }
}
