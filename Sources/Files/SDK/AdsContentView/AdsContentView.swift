//
//  AdsContentView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadziev on 19.4.24.
//

import SwiftUI

struct AdsContentView: View {
    @ObservedObject var campaignManager = CampaignManager.shared
    @ObservedObject var slot: AdSlot
    
    var delegate: InsideAdCallbackDelegate?
    private let activePlayersCount: Int?
    /// This view's own container. The ad is sized to it, not to the slot's shared
    /// `containerSize` — see `AdSlot.adSize(fitting:)`.
    private let containerSize: CGSize?
    
    public init(delegate: InsideAdCallbackDelegate,
                screen: String?,
                isAdMuted: Bool,
                targetModel: TargetModel?,
                rotateVolumeButton: Bool? = false,
                isPrerollAd: Bool = false,
                activePlayersCount: Int? = nil,
                containerSize: CGSize? = nil,
                showsCloseButton: Bool = true) {
        
        self.delegate = delegate
        self.activePlayersCount = activePlayersCount
        self.containerSize = containerSize

        // State for this placement lives on its own slot, keyed by screen name, so a second
        // ad view elsewhere on screen can't overwrite this one's ad, size or callbacks.
        let slot = CampaignManager.shared.slot(for: screen)
        // A slot that switches between preroll and regular inventory must drop whatever it
        // resolved under the old setting.
        if slot.isPrerollAd != isPrerollAd {
            slot.clearResolvedAd()
        }
        slot.isPrerollAd = isPrerollAd
        slot.targetModel = targetModel
        slot.isAdMuted = isAdMuted
        slot.activePlayersCount = activePlayersCount
        slot.containerSize = containerSize
        slot.showsCloseButton = showsCloseButton

        // in some cases when the device is rotated the volume button is in an opposite direction, so this condition can modify the image if necessary
        slot.rotateVolumeButton = rotateVolumeButton

        self.slot = slot

        Constants.ResellerInfo.isAdMuted = isAdMuted

        //If adLoaded is true, set the activeCampaign, activeInsideAd and activePlacement otherwise don't initialize them
        if CampaignManager.shared.fetchCompleted {
            Self.findActiveAdForScreen(slot: slot)
        }
    }
    
    var body: some View {
        ZStack {
            if let activeInsideAd = slot.activeInsideAd {
                Group {
                    switch activeInsideAd.adType {
                    case .VAST:
                        VastViewWrapper(slot: slot)
                        
                    case .LOCAL_IMAGE:
                        LocalImageView(slot: slot)
                            .environmentObject(slot.localImageManager)
                        
                    case .LOCAL_VIDEO:
                        LocalVideoPlayerView(slot: slot)
                            .environmentObject(slot.localVideoManager)
                        
                    case .BANNER:
#if os(iOS)
                        BannerAdViewWrapper(slot: slot)
#else
                        // Google Mobile Ads has no tvOS build, so banners can't render there.
                        EmptyView()
#endif
                        
                    case .FULLSCREEN_NATIVE:
#if os(iOS)
                        NativeAdView()
#else
                        // Google Mobile Ads has no tvOS build, so native ads can't render there.
                        EmptyView()
#endif
                        
                    case .unsupported, .none:
                        EmptyView()
                    }
                }
                // A new ad needs a new player. Without this a fallback of the same type
                // (VAST → VAST) kept the old wrapper, so nothing ever requested it.
                .id(activeInsideAd.id ?? "")
            }
        }
        .frame(maxWidth: slot.adSize(fitting: containerSize).width,
               maxHeight: slot.adSize(fitting: containerSize).height)
        .onChange(of: campaignManager.fetchCompleted) { _ in
            Self.findActiveAdForScreen(slot: slot)
        }
        .onChange(of: activePlayersCount) { newValue in
            // The canvas ad only runs while 1–3 players are visible, so re-evaluate
            // whenever the host adds or removes a player.
            slot.activePlayersCount = newValue
            if slot.isEligibleForAd {
                Self.findActiveAdForScreen(slot: slot)
            } else {
                slot.endAdForIneligibility()
                // No callback fires for this, so tell the host directly or it keeps the
                // tile reserved and its players ducked.
                delegate?.insideAdCallbackReceived(data: .AD_VIEW_DISAPPEARED)
            }
        }
        .onChange(of: slot.insideAdCallback) { newValue in
            print(Logger.log("AdsContentView INSIDE AD CALLBACK RECEIVED [\(slot.key)]: \(newValue)"))
            //Send the callback to the delegate
            self.delegate?.insideAdCallbackReceived(data: newValue)
        }
        .onAppear(perform: {
            slot.mountedViewCount += 1
            slot.eventDelegate = delegate
            print(Logger.log("AdsContentView APPEARED [\(slot.key)] mounted=\(slot.mountedViewCount)"))

            // Tell this view's delegate what the slot is doing *now*. `onChange` only
            // reports later changes, so a view mounted mid-flight — rotation swaps the
            // whole layout — hears nothing about callbacks sent while it did not exist.
            // A host that reserves space for the ad would then go on reserving it for an
            // ad that had already finished during the rotation.
            let isAdOnScreen = slot.activeInsideAd != nil && slot.hasSizedAd
            delegate?.insideAdCallbackReceived(data: isAdOnScreen ? .STARTED : .AD_VIEW_DISAPPEARED)

            // A previous view may have torn the slot down after this one was initialised,
            // in which case the lookup in `init` saw a busy slot and skipped it.
            if slot.activeInsideAd == nil {
                Self.findActiveAdForScreen(slot: slot)
            }
        })
        .onDisappear{
            // The click-through browser covers the app rather than the viewer leaving, so
            // the ad stays as it is and resumes when the browser closes.
            guard !slot.isClickThroughPresented else {
                print(Logger.log("AdsContentView DISAPPEARED [\(slot.key)] behind click-through — keeping ad"))
                return
            }

            slot.mountedViewCount = max(0, slot.mountedViewCount - 1)

            // Another view for this placement is still on screen — the host is handing the
            // slot from one panel to another and their transitions overlap. Tearing the ad
            // down now would kill it underneath that view; let the last one out do it.
            guard slot.mountedViewCount == 0 else {
                print(Logger.log("AdsContentView DISAPPEARED [\(slot.key)], \(slot.mountedViewCount) view(s) still mounted — keeping ad"))
                return
            }

            // Wait one runloop before tearing down. SwiftUI does not promise that the
            // incoming view's onAppear runs before the outgoing view's onDisappear, so in a
            // handoff — a rotation swapping the whole layout, say — the count can touch zero
            // for a moment with the next view on its way. That replaces the old rotation
            // flag, which was set by any orientation event (face up, back from background)
            // and, left set, skipped the next real teardown: the ad kept playing unseen,
            // even after the viewer left the screen.
            let slot = slot
            let delegate = delegate
            DispatchQueue.main.async {
                guard slot.mountedViewCount == 0 else {
                    print(Logger.log("AdsContentView DISAPPEARED [\(slot.key)], another view took over — keeping ad"))
                    return
                }

                slot.insideAdCallback = .AD_VIEW_DISAPPEARED
                // This view has gone, so its onChange will never deliver the callback above.
                // Tell the host directly, or it goes on reserving space and ducking its
                // players for an ad that is no longer there.
                delegate?.insideAdCallbackReceived(data: .AD_VIEW_DISAPPEARED)
            }
        }
    }
    
    private static func findActiveAdForScreen(slot: AdSlot){
        // Only resolve when the slot is idle: nothing resolved yet, and no interval running.
        // Both belong to the slot, not the view, so a view that is mounted again — a side
        // panel reopened, a rotation — cannot skip the interval or restart a pending ad.
        // (It used to also require a particular last callback, which left the slot shut
        // for good after a failure with no interval to reopen it.)
        if slot.activeInsideAd == nil && !slot.isWaitingForNextAd {
            
            slot.findActiveAd()
        }
    }
}
