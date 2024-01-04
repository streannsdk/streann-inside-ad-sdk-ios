//
//  InsideAdView].swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import SwiftUI
import GoogleInteractiveMediaAds
import UIKit
import AVFoundation
import WebKit

protocol InsideAdCallbackDelegate {
    func insideAdCallbackReceived(data: InsideAdCallbackType)
}

public struct InsideAdView: View, InsideAdCallbackDelegate {
//    @Environment(\.dismiss) var dismiss
    
    @Binding var insideAdCallback: InsideAdCallbackType
    var campaignDelegate: CampaignDelegate?
    var insideAdsPlayerIntervalInMinutes: Int
    var screen: String
    var viewSize: CGSize
    @StateObject var insideAdsPlayerTimer = InsideAdsPlayerTimer(insideAdsPlayerIntervalInMinutes: 15)
    
    @State var loadingAderror = false
    @State var reload = false

     public init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, campaignDelegate: CampaignDelegate? = nil, insideAdsPlayerIntervalInMinutes: Int, viewSize:CGSize) {
        _insideAdCallback = insideAdCallback
        self.campaignDelegate = campaignDelegate
        self.screen = screen
        self.viewSize = viewSize
        self.insideAdsPlayerIntervalInMinutes = insideAdsPlayerIntervalInMinutes
    }
    
    public var body: some View {
        //        if insideAdsPlayerTimer.counter == insideAdsPlayerIntervalInMinutes {
//        if insideAdCallback != .ALL_ADS_COMPLETED && !loadingAderror || insideAdsPlayerTimer.showAd {
            //            if showAd {
            GeometryReader { geo in
                InsideAdViewWrapper(screen: screen, parent: self, viewSize: viewSize) //geo.size
                //            if case let .IMAAdError(string) = insideAdCallback {
                        //              //              insideAdsPlayerTimer.showAd = false
                        //              insideAdsPlayerTimer.stop()
                        //              insideAdsPlayerTimer.start()
                        //              print(“errorString value \(string)“)
                        //            }
                        //          })
            }
            .onAppear(perform: {
                insideAdsPlayerTimer.start()
            })
//            .onReceive(insideAdsPlayerTimer.$showAd, perform: { timer in
//                print("timer publisher \(timer)")
//                insideAdsPlayerTimer.reset()
//                insideAdsPlayerTimer.start()
//                loadingAderror = false
//                insideAdsPlayerTimer.showAd = false
//            })
            .onChange(of: insideAdCallback, perform: { value in
                if value == .STARTED {
                    NotificationCenter.post(name: .AdsContentView_setFullSize)
                }
                else if value == .ALL_ADS_COMPLETED {
                    NotificationCenter.post(name: .AdsContentView_setZeroSize)
                    insideAdsPlayerTimer.showAd = false
//                    self.dismiss()
                }
                print("STARTED \(value)")
                insideAdCallback = value
                //            }
                if case let .IMAAdError(string) = insideAdCallback {
                    if !string.isEmpty {
                        loadingAderror = true
                        insideAdsPlayerTimer.showAd = false
//                        self.dismiss()
                    }
                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        loadingAderror = false
//                        print("STARTED \(value)RELOADED")
//                    }
                }
            })
//            .task {
//                if case let .IMAAdError(string) = insideAdCallback {
//                    if !string.isEmpty {
//                        insideAdsPlayerTimer.showAd = false
//                    }
//                }
//            }
//        }
    }
}

extension InsideAdView {
    //Delegate method to show the state of the insideAd player
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }

}

struct InsideAdViewWrapper: UIViewControllerRepresentable {
//    @Binding var showAd: Bool
//    @Binding var errorLoadingAds: Bool
    var screen: String
    let parent: InsideAdView
    var viewSize: CGSize
    
//    @Binding var callback: InsideAdCallbackType
    
    func makeUIViewController(context: Context) -> InsideAdViewController {
        let controller = InsideAdViewController(insideAdCallbackDelegate: parent)
        controller.campaignDelegate = parent.campaignDelegate
        controller.screen = screen
        controller.viewSize = viewSize
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


class InsideAdViewController: UIViewController, ObservableObject {
//    private var videoView: UIView!
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private let adsLoader = IMAAdsLoader(settings: nil)
    private var adsManager: IMAAdsManager?
    let imaSettings = IMASettings()

    private var geoModel: GeoIp?
    private var insideAdHelper = InsideAdHelper()
    
    var screen = ""
    var viewSize: CGSize = CGSize(width: 300, height: 250)
    
//    @Published var showAd: Bool = true
    
    //Delegates
    var insideAdCallbackDelegate: InsideAdCallbackDelegate
    var campaignDelegate: CampaignDelegate? = nil
    
//    let insideAdPlayerErrorStateDelegate: InsideAdPlayerErrorStateDelegate
    
//    @Published var errorLoadingAds = false
    
    init(insideAdCallbackDelegate: InsideAdCallbackDelegate) {
        self.insideAdCallbackDelegate = insideAdCallbackDelegate
//        self.view = size
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
//        videoView = UIView(frame: CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height))
//        self.view.addSubview(videoView)
        adsLoader.delegate = self
//        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.requestAds(screen: self.screen)
    }
    
    //Setup the new constraints on device rotation
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        videoView.frame = CGRect(origin: .zero, size: view.bounds.size)
//    }
    
    //View constraints setup
//    private func setupView() {
//        videoView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            videoView.topAnchor.constraint(equalTo: view.topAnchor),
//            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }

    // MARK: IMA integration methods
    func requestAds(screen: String) {
        if Constants.ResellerInfo.apiKey == "" {
            let errorMsg = "Api Key is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            insideAdCallbackDelegate.insideAdCallbackReceived(data: .IMAAdError(errorMsg))
        }
        
        if Constants.ResellerInfo.baseUrl == "" {
            let errorMsg = "Base Url is required. Please implement the initializeSdk method."
            print(Logger.log(errorMsg))
            insideAdCallbackDelegate.insideAdCallbackReceived(data: .IMAAdError(errorMsg))
        }
        
        SDKAPI.getGeoIpUrl { geoIpUrl, error in
            if let geoIpUrl {
                SDKAPI.getGeoIp(fromUrl: geoIpUrl.geoIpUrl) { geoIp, error in
                    if let geoIp {
                        SDKAPI.getCampaigns(countryCode: geoIp.countryCode ?? "") {campaigns, error in
                            if let campaigns {
                                self.campaignDelegate?.onSuccess(campaigns: campaigns)
                                
                                DispatchQueue.main.async {
                                    //TESTING
//                                    let url = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="
     
                                    let activeCampaign = campaigns.getActiveCampaign()
                                    let activeInsideAd = activeCampaign?.placements?.getInsideAdByPlacement(screen: screen)
                                    let url = activeInsideAd?.url
                                    
                                    if let url = url{
                                        if activeInsideAd?.adType == "VAST" {
                                            //Populate macros
                                             let adTagUrl = self.insideAdHelper.populateVastFrom(adUrl: url, geoModel: geoIp, playerSize: self.viewSize)
                                            
                                            // Create ad display container for ad rendering.
                                            let adDisplayContainer = IMAAdDisplayContainer(
                                                adContainer: self.view, viewController: self, companionSlots: nil)
                                            
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
                            }else{
                                let errorMsg = "Error while getting AD."
                                self.campaignDelegate?.onError(error: errorMsg)
                                self.insideAdCallbackDelegate.insideAdCallbackReceived(data: .IMAAdError(errorMsg))
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
        //        self.view.removeFromSuperview()
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
        //        self.view.removeFromSuperview()
        print(Logger.log("\(error.message ?? "Unknown error")"))
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause the content.
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // The SDK is done playing ads (at least for now), so resume the content.
//        self.view.removeFromSuperview()
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


// modifier
struct HideViewModifier: ViewModifier {
    let isHidden: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if isHidden {
            EmptyView()
        } else {
            content
        }
    }
}

// Extending on View to apply to all Views
extension View {
    func hide(if isHiddden: Bool) -> some View {
        ModifiedContent(content: self,
                        modifier: HideViewModifier(isHidden: isHiddden)
        )
    }
}
