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
    private let adsLoader = IMAAdsLoader(settings: VastViewController.imaSettings())
    private var adsManager: IMAAdsManager?
    private var volumeButton: UIButton?
    private let button = UIButton(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
    private var insideAdHelper = InsideAdHelper()
    var imaadPlayerView: UIView?

    var viewSize: CGSize = CGSize(width: 300, height: 250)

    // Retry logic for VAST requests
    private var retryCount = 0
    private let maxRetries = 1
    private let retryDelay: TimeInterval = 2.0  // seconds between retries

    /// The placement this controller belongs to. All ad state is read from and written
    /// back to this slot, so two VAST ads on screen at once stay independent.
    private unowned let slot: AdSlot
    
    //Delegates
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
        
    init(slot: AdSlot) {
        self.slot = slot
        super.init(nibName: nil, bundle: nil)
        adsLoader.delegate = self
        addImmadPlayerView()

        NotificationCenter.default.addObserver(self, selector: #selector(self.changeAdVolume(notification:)), name: Notification.Name(Constants.Notifications.changeInsideAdSdkAdVolume), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidEnterBackground() {
        adsManager?.pause()
    }

    @objc private func appDidBecomeActive() {
        //The in-app browser also triggers didBecomeActive - resuming there is handled by
        //linkOpenerDidClose once the browser is dismissed
        guard !slot.isClickThroughPresented else { return }
        if adsManager?.adPlaybackInfo.isPlaying == false {
            adsManager?.resume()
        }
    }
    
    /// IMA's own settings. Debug mode makes IMA log the full request it sends, including
    /// the signals it appends to the tag — what to compare when the same tag fills on one
    /// platform and not another.
    private static func imaSettings() -> IMASettings {
        let settings = IMASettings()
        settings.enableBackgroundPlayback = false
        settings.autoPlayAdBreaks = true
        settings.language = "en"
        settings.playerType = "ios-video-player"
        settings.playerVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        settings.enableDebugMode = InsideAdSdk.imaDebugLoggingEnabled
        return settings
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

#if os(iOS)
        // tvOS has no device rotation, so the button never needs flipping there.
        if UIDevice.current.orientation.isLandscape && slot.rotateVolumeButton ?? false {
            button.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        } else {
            button.transform = CGAffineTransform(rotationAngle: 0)
        }
#endif
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

    /// Set once the ad has been torn down, so a request still waiting out
    /// `startAfterSeconds` doesn't fire for an ad nobody is showing any more.
    private var isDestroyed = false

    /// Removes the ad's views. Kept for callers that only want the UI gone; `destroy()`
    /// is what releases IMA.
    func cleanup() {
        volumeButton?.removeFromSuperview()
        volumeButton = nil
        removeImmadPlayerView()
    }

    /// Stops the ad and releases IMA. Must run before the controller is dropped: releasing
    /// an `IMAAdsManager` mid-playback without `destroy()` leaves IMA running against a
    /// deallocated delegate and display container.
    func destroy() {
        isDestroyed = true
        adsLoader.delegate = nil
        let manager = adsManager
        manager?.delegate = nil
        adsManager = nil
        volumeButton?.removeFromSuperview()
        volumeButton = nil
        removeImmadPlayerView()

        // Usually reached from inside one of IMA's own callbacks — ALL_ADS_COMPLETED, or a
        // failed load. Let that call return first: destroy the manager afterwards, and keep
        // this controller and its loader alive until then, since the slot drops its only
        // reference right after this and IMA is still inside the loader's method.
        let loader = adsLoader
        DispatchQueue.main.async {
            manager?.destroy()
            withExtendedLifetime((self, loader)) {}
        }
    }
    
    private func addVolumeButton(){
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setImage(UIImage(systemName: slot.isAdMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerFill), for: .normal)
        button.addTarget(self, action: #selector(volumeButtonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        view.bringSubviewToFront(button)
        volumeButton = button
    }
    
    @objc private func volumeButtonAction(_ sender: UIButton) {
        slot.isAdMuted.toggle()
       
        setImmadVolume()
        
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .VOLUME_CHANGED(Int(adsManager?.volume ?? 0)))
        
        print(Logger.log("Volume changed to: \(adsManager?.volume ?? 0)"))
    }

    @objc func changeAdVolume(notification: Notification) {
        if let notification = notification.userInfo?[Constants.Notifications.isAdMuted] as? Bool {
            slot.isAdMuted = !notification
            setImmadVolume()
        }
    }
    
    private func setImmadVolume(){
        adsManager?.volume = slot.isAdMuted ? 0 : 1
        volumeButton?.setImage(UIImage(systemName: slot.isAdMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerFill), for: .normal)
    }
    
    // MARK: IMA integration methods
    func requestAds() {
        let activeInsideAd = slot.activeInsideAd
        let url = activeInsideAd?.url
        
        if let url = url, let geoIp = CampaignManager.shared.geoIp {
            //Populate macros
            // Report the size the host actually renders the ad at, so an ad server using the
            // player-size macros can pick a creative that fits. `viewSize` (300×250) is only
            // the fallback for hosts that don't pass a container size.
            let playerSize: CGSize
            if let containerSize = slot.containerSize, containerSize.width > 0, containerSize.height > 0 {
                playerSize = containerSize
            } else {
                playerSize = self.viewSize
            }
            let adTagUrl = self.insideAdHelper.populateVastFrom(adUrl: url, geoModel: geoIp, playerSize: playerSize, targetModel: slot.targetModel)
            InsideAdSdk.shared.vastTagUrl = adTagUrl
            // The full tag, macros filled in — what to compare against another platform's
            // request when one fills and the other doesn't.
            print(Logger.logVast("AD TAG [\(slot.key)]: \(adTagUrl)"))

            // Create ad display container for ad rendering.
            // Deliberately the initialiser without companionSlots: IMACompanionAdSlot is
            // declared in the tvOS headers but not built into the tvOS binary, so naming it
            // fails to link on Apple TV. We never used companion slots anyway.
            let adDisplayContainer = IMAAdDisplayContainer(
                adContainer: self.imaadPlayerView!, viewController: self)
            
            // Create an ad request with our ad tag, display container, and optional user context.
            let request = IMAAdsRequest(
                adTagUrl: adTagUrl,
                adDisplayContainer: adDisplayContainer,
                contentPlayhead: self.contentPlayhead,
                userContext: nil)

            //timeout in milliseconds - 30sec (increased to handle multiple VAST wrappers)
            request.vastLoadTimeout = 30000
            
            DispatchQueue.main.asyncAfter(deadline: .now() + slot.remainingStartDelay) {[weak self] in
                guard let self, !self.isDestroyed else { return }
                self.adsLoader.requestAds(with: request)
                print(Logger.logVast("AD REQUESTED"))
            }
        }
    }

    //Topmost controller in the key window's hierarchy, used to present the click-through browser
    static func topPresentingViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.Notifications.changeInsideAdSdkAdVolume), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
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
        // The browser must be presented from a controller that is actually installed in the
        // window's hierarchy — presenting from this controller (whose view SwiftUI hosts
        // directly) makes UIKit re-attach our view fullscreen when the browser is dismissed.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.linkOpenerPresentingController = Self.topPresentingViewController() ?? self
        adsRenderingSettings.linkOpenerDelegate = self

        // IMA gives up on the media file after 8s by default. Multiview requests its canvas
        // ad about a second after the screen opens, while the grid player and the camera
        // previews are all loading DRM streams, and the ad reliably timed out there.
        adsRenderingSettings.loadVideoTimeout = 20
        
        // Initialize the ads manager.
        adsManager?.initialize(with: adsRenderingSettings)
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        let errorMessage = adErrorData.adError.message ?? "Unknown error"
        let errorCode = adErrorData.adError.code

        print(Logger.log("VAST Error [\(slot.key)] - Message: \(errorMessage), Code: \(errorCode.rawValue)"))
        print(Logger.log("VAST Tag URL: \(InsideAdSdk.shared.vastTagUrl ?? "N/A")"))

        // 303 is "no ads in the VAST response", which is often transient; retry once.
        if errorCode.rawValue == 303 && retryCount < maxRetries && !isDestroyed {
            retryCount += 1
            print(Logger.logVast("Error 303 — retrying (attempt \(retryCount) of \(maxRetries))"))
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                guard let self, !self.isDestroyed else { return }
                self.requestAds()
            }
            return
        }

        InsideAdSdk.shared.vastErrorMessage = errorMessage
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ON_ERROR(errorMessage))
        slot.insideAdCallback = .TRIGGER_FALLBACK
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

        else if event.type == .CLICKED {
            //The click-through browser is about to cover the app - the ad view will disappear
            //but must not be torn down
            slot.isClickThroughPresented = true
        }

        else if event.type == .RESUME {
            slot.isClickThroughPresented = false
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

// MARK: - IMALinkOpenerDelegate
extension VastViewController: IMALinkOpenerDelegate {
    func linkOpenerWillOpen(inAppLink linkOpener: NSObject) {
        //The click-through browser is about to cover the app - the ad view will disappear
        //but must not be torn down
        slot.isClickThroughPresented = true
    }

    func linkOpenerDidClose(inAppLink linkOpener: NSObject) {
        slot.isClickThroughPresented = false
        //IMA pauses the ad for the click-through and doesn't reliably auto-resume when the
        //browser was presented from another controller, so resume explicitly
        adsManager?.resume()
    }
}

struct VastViewWrapper: UIViewRepresentable, InsideAdCallbackDelegate {
    let slot: AdSlot

    final class Coordinator {
        let slot: AdSlot
        init(slot: AdSlot) { self.slot = slot }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(slot: slot)
    }

    // Each wrapper gets its own empty container and the one IMA view is moved into it.
    // Returning the IMA view itself broke as soon as two wrappers existed at once — a host
    // handing a placement from one panel to another — because both SwiftUI hosts then
    // claimed the same UIView, and the outgoing one pulled it out of the incoming one as
    // it was dismantled, leaving the ad playing nowhere.
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        if slot.vastController == nil {
            let controller = VastViewController(slot: slot)
            controller.insideAdCallbackDelegate = self
            slot.vastController = controller
            controller.requestAds()
        }
        slot.attachVastView(to: container)
        return container
    }
    
    func updateUIView(_ uiViewController: UIView, context: Context) {
        //
    }

    static func dismantleUIView(_ container: UIView, coordinator: Coordinator) {
        coordinator.slot.detachVastView(from: container)
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        slot.insideAdCallback = data
    }
}
