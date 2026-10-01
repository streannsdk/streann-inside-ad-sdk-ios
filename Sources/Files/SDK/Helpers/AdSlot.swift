//
//  AdSlot.swift
//  streann-inside-ad-sdk-ios
//
//  Holds all state belonging to ONE ad placement on screen.
//
//  The SDK used to keep this state as single values on CampaignManager/AdsManager,
//  which meant two ad views alive at the same time (e.g. Multiview's canvas and its
//  right bar) would overwrite each other's ad, size and callbacks. State that belongs
//  to a placement lives here instead; CampaignManager keeps one AdSlot per screen name
//  and only genuinely global state (campaign list, geoIp, fetch status) stays on it.
//

import UIKit
import SwiftUI

public final class AdSlot: ObservableObject {

    /// Screen/tag name this slot resolves ads for. `nil` matches placements without tags.
    public let screen: String?

    /// Registry key. Slots are identified by their screen name; `nil` uses `defaultKey`.
    static let defaultKey = "__insideAd_default__"
    let key: String

    // MARK: - Request inputs

    var targetModel: TargetModel?
    var rotateVolumeButton: Bool? = false
    var isAdMuted: Bool = false

    /// How many ad views for this placement are currently mounted.
    ///
    /// Normally one, but a host can hand a placement from one view to another — Multiview
    /// swaps its whole layout on rotation, and the canvas grid exists in both — and the two
    /// can overlap: the incoming view is mounted before the outgoing one goes away. The ad
    /// must only be torn down once the last view has gone, or the teardown pulls the
    /// player out from under a view that is still on screen.
    var mountedViewCount = 0

    /// Whether this slot serves a preroll. A finished preroll keeps its resolved ad and
    /// starts no interval: the host moves straight on to its content instead.
    var isPrerollAd = false

    /// True while the click-through ("Learn more") browser covers the app, so the ad view
    /// going away is not mistaken for the viewer leaving the screen.
    var isClickThroughPresented = false

    /// Host-side override for the ad's own close button. When false the ad is never
    /// dismissable, whatever the placement configures — for hosts that present the ad as
    /// part of their own layout (Multiview's grid tile and camera list).
    var showsCloseButton: Bool = true

    /// Number of players currently visible in the Multiview canvas.
    /// Only meaningful for `MULTIVIEW_CANVAS` — see `isEligibleForAd`.
    var activePlayersCount: Int?

    /// Size of the container this slot renders into. When set, the ad is sized to fit it
    /// instead of assuming it spans the full device width.
    var containerSize: CGSize?

    // MARK: - Resolved ad

    @Published var activeCampaign: CampaignAppModel?
    @Published var activePlacement: Placement?
    @Published var activeInsideAd: InsideAd? {
        didSet {
            // A new ad (or a fallback, or none) starts a new reporting cycle.
            didReportRequest = false
            didReportDisplay = false
            // Kept for backwards compatibility: the public `InsideAdSdk.activeInsideAd`
            // reflects the default slot only, which is what single-slot hosts expect.
            if key == AdSlot.defaultKey {
                InsideAdSdk.shared.activeInsideAd = activeInsideAd
            }
        }
    }

    // MARK: - Playback state

    @Published var adViewWidth: CGFloat = 0
    @Published var adViewHeight: CGFloat = 0
    @Published var timerNextAd: Timer?

    /// When the resolved ad is due to start — `startAfterSeconds` after it was resolved.
    ///
    /// The schedule belongs to the placement, not to the view showing it. It used to be
    /// re-armed by every view that mounted, so a host that removed the view and put it back
    /// (Multiview's landscape side panel) restarted the full `startAfterSeconds` wait, and
    /// skipped the interval between ads altogether.
    var adStartDate: Date?

    /// Seconds left until the resolved ad is due. Players wait this long, not the full
    /// `startAfterSeconds`, so a view that mounts partway through only waits the remainder.
    var remainingStartDelay: Double {
        guard let adStartDate else { return startAfterSeconds }
        return max(0, adStartDate.timeIntervalSinceNow)
    }

    /// True while the interval between two ads is running. Nothing may be served until it
    /// fires, whichever view is or isn't mounted in the meantime.
    var isWaitingForNextAd: Bool { timerNextAd?.isValid == true }

    /// Whether the close button is on screen right now. Driven by the placement's
    /// `showCloseButtonAfterSeconds` once the ad starts.
    @Published var isCloseButtonVisible = false
    private var closeButtonTimer: Timer?
    @Published var localImageManager = LocalImageManager()
    @Published var localVideoManager = LocalVideoManager()

    var vastController: VastViewController?

    /// Containers currently showing this slot's VAST ad, oldest first. The IMA view can
    /// only have one superview, so it lives in the newest one; when that goes it moves back
    /// to whichever is still mounted.
    private var vastHosts: [WeakView] = []
#if os(iOS)
    var bannerAdViewController: BannerAdViewController?
#endif

    @Published var insideAdCallback: InsideAdCallbackType = .UNKNOWN {
        didSet {
            switch insideAdCallback {
            case .STARTED:
                if activeInsideAd?.adType != .BANNER {
                    setFullSize()
                }
                scheduleCloseButton()
                reportDisplayed()
            case .ALL_ADS_COMPLETED:
                clearPlayback()
                // A preroll keeps its resolved ad and runs no interval — the host takes
                // over as the ad ends.
                if !isPrerollAd {
                    clearResolvedAd()
                    startTimerForNextAd()
                }
            case .TRIGGER_FALLBACK:
                clearPlayback()
                if activeInsideAd?.fallback != nil {
                    setFallbackAdAsActive()
                } else {
                    // No fallback to try: treat the failed ad as done so the interval runs
                    // and the next ad is still served. Without this the slot kept the
                    // failed ad and never served again.
                    clearResolvedAd()
                    startTimerForNextAd()
                }
            case .AD_VIEW_DISAPPEARED:
                endAdForMissingView()
            case .ON_ERROR(let message):
                // Reporting only. Every sender follows this with TRIGGER_FALLBACK, which
                // decides what happens next — clearing the ad here would destroy the
                // fallback before that case could use it.
                print(Logger.log("Ad error occurred [\(key)]: \(message)"))
            default:
                break
            }
        }
    }

    init(screen: String?) {
        self.screen = screen
        self.key = screen ?? AdSlot.defaultKey
        self.localImageManager.slot = self
        self.localVideoManager.slot = self
    }

    // MARK: - Reporting

    /// Receives `insideAdRequested` / `insideAdDisplayed`: the newest view mounted for this
    /// placement. During a handoff two views overlap, and each event must reach the host
    /// once, not once per view.
    var eventDelegate: InsideAdCallbackDelegate?
    private var didReportRequest = false
    private var didReportDisplay = false

    /// Called by each player just before it requests its ad. Repeat requests for the same
    /// ad — a VAST ad re-requested after a handoff — are not reported again.
    func reportRequested() {
        guard !didReportRequest, let ad = activeInsideAd else { return }
        didReportRequest = true
        print(Logger.log("Ad requested [\(key)]: \(ad.name ?? "-") \(ad.adType.map { "\($0)" } ?? "-")"))
        eventDelegate?.insideAdRequested(screen: screen, ad: ad)
    }

    private func reportDisplayed() {
        guard !didReportDisplay, let ad = activeInsideAd else { return }
        didReportDisplay = true
        print(Logger.log("Ad displayed [\(key)]: \(ad.name ?? "-") \(ad.adType.map { "\($0)" } ?? "-")"))
        eventDelegate?.insideAdDisplayed(screen: screen, ad: ad)
    }

    // MARK: - Eligibility

    /// Multiview shows the canvas ad as a 4th tile, so it may only run when 1–3 players
    /// are visible. Every other screen is always eligible.
    var isEligibleForAd: Bool {
        guard screen == InsideAdScreenLocations.multiviewCanvas.rawValue else { return true }
        guard let count = activePlayersCount else { return false }
        return (1...3).contains(count)
    }

    // MARK: - Resolution

    func findActiveAd() {
        guard isEligibleForAd else {
            clearResolvedAd()
            return
        }

        DispatchQueue.main.async {
            // `init` runs on every host render and `onAppear` can queue another lookup
            // before this one runs. Only the first may resolve: a second would re-pick the
            // campaign — possibly one the ad isn't in, losing its placement's start delay
            // and interval — and reset the start date.
            guard self.activeInsideAd == nil, !self.isWaitingForNextAd, self.isEligibleForAd else { return }

            // Prerolls are their own inventory: a preroll slot serves only PREROLL
            // placements, and every other slot serves everything else.
            let candidates = self.isPrerollAd
                ? CampaignManager.shared.allActiveCampaigns.filterCampaignsByViewType(viewType: AdSlot.prerollViewType)
                : CampaignManager.shared.allActiveCampaigns.excludeCampaignsByViewType(viewType: AdSlot.prerollViewType)

            let campaign = candidates
                .findActiveCampaignFromScreenAndTargetModel(screen: self.screen, targetModel: self.targetModel)
            self.activeCampaign = campaign
            self.activeInsideAd = campaign?.placements?.activeAdFromPlacement(for: self)
            self.activePlacement = campaign?.placements?.findBy(adId: self.activeInsideAd?.id ?? "")
            self.adStartDate = self.activeInsideAd == nil ? nil : Date().addingTimeInterval(self.startAfterSeconds)

            if self.activeInsideAd == nil {
                print(Logger.log("No ad resolved [\(self.key)]"))
                // A preroll host waits on the callback before starting its content, so it
                // must hear something even when nothing resolved.
                if self.isPrerollAd {
                    self.insideAdCallback = .TRIGGER_FALLBACK
                }
            }
        }
    }

    /// Placements that serve before a host's content, kept out of every other slot.
    static let prerollViewType = "PREROLL"

    func setFallbackAdAsActive() {
        if let fallbackAd = activeInsideAd?.fallback {
            activeInsideAd = fallbackAd
            adStartDate = Date().addingTimeInterval(startAfterSeconds)
        }
    }

    func clearResolvedAd() {
        activeInsideAd = nil
        activePlacement = nil
        adStartDate = nil
    }

    // MARK: - Sizing

    /// True once an ad has started and been given a size; false while the slot is empty.
    var hasSizedAd: Bool { adViewWidth != 0 || adViewHeight != 0 }

    /// Size the ad should render at right now. When the host supplied a container we use
    /// it live rather than the value captured at `.STARTED`, so the ad follows its
    /// container when the layout changes under it — on rotation the host rebuilds with a
    /// new container size but the ad is already started, so `setFullSize()` never runs
    /// again and the ad would otherwise keep its old dimensions.
    var currentAdSize: CGSize {
        adSize(fitting: containerSize)
    }

    /// Size the ad should render at inside one particular view's container.
    ///
    /// Each view passes its own container rather than relying on `containerSize`, which is
    /// shared by every view of the placement and holds whichever one wrote it last. During
    /// a rotation both layouts' views exist and each is re-rendered with the other's
    /// geometry on the way in or out, so the last write can be the wrong layout's size —
    /// Multiview's canvas ad then stayed half its tile's size in landscape until the next
    /// rotation.
    func adSize(fitting container: CGSize?) -> CGSize {
        guard hasSizedAd else { return .zero }
        if let container, container.width > 0, container.height > 0 {
            return container
        }
        return CGSize(width: adViewWidth, height: adViewHeight)
    }

    func setFullscreenSize() {
        adViewHeight = .infinity
        adViewWidth = .infinity
    }

    func setFullSize() {
        // Prefer the size the host gave us; only fall back to "full device width, 16:9"
        // when this slot renders standalone (the historical behaviour).
        if let containerSize, containerSize.width > 0, containerSize.height > 0 {
            adViewWidth = containerSize.width
            adViewHeight = containerSize.height
        } else {
            adViewHeight = UIScreen.main.bounds.width / 16 * 9
            adViewWidth = .infinity
        }
    }

    func setZeroSize() {
        adViewHeight = 0
        adViewWidth = 0
    }

    // MARK: - Teardown

    /// Applies the placement's `showCloseButtonAfterSeconds`: 0 (or unset) shows the
    /// button immediately, a positive value delays it by that many seconds. A host that
    /// passed `showsCloseButton: false` never gets one.
    private func scheduleCloseButton() {
        closeButtonTimer?.invalidate()
        closeButtonTimer = nil

        guard showsCloseButton else {
            isCloseButtonVisible = false
            return
        }

        let delay = activePlacement?.properties?.showCloseButtonAfterSeconds ?? 0
        guard delay > 0 else {
            isCloseButtonVisible = true
            return
        }

        isCloseButtonVisible = false
        closeButtonTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delay), repeats: false) { [weak self] _ in
            self?.isCloseButtonVisible = true
        }
    }

    func clearPlayback() {
        closeButtonTimer?.invalidate()
        closeButtonTimer = nil
        isCloseButtonVisible = false
        vastController?.destroy()
        vastController = nil
#if os(iOS)
        bannerAdViewController = nil
#endif
        localVideoManager.destroy()
        localImageManager.reset()
        setZeroSize()
        // Deliberately leaves `timerNextAd` running: the interval between ads belongs to
        // the placement and must survive the view that showed the last ad going away.
    }

    /// The last view showing this placement has gone.
    ///
    /// An ad that was on screen counts as shown: the interval starts now, so putting the
    /// view back does not serve a fresh ad straight away. An ad that had not started yet is
    /// kept, along with its start date, so the next view picks up the remaining wait. A
    /// running interval is left alone in both cases.
    private func endAdForMissingView() {
        let wasOnScreen = activeInsideAd != nil && hasSizedAd
        clearPlayback()
        if wasOnScreen {
            clearResolvedAd()
            startTimerForNextAd()
        }
    }

    /// The placement stopped being eligible — for Multiview's canvas, the viewer went to
    /// 0 or 4 players. Same rule as a missing view: an ad on screen counts as shown.
    func endAdForIneligibility() {
        let wasOnScreen = activeInsideAd != nil && hasSizedAd
        clearPlayback()
        clearResolvedAd()
        if wasOnScreen {
            startTimerForNextAd()
        }
    }

    // MARK: - VAST hosting

    /// Shows the VAST ad in `container`, taking it from whichever container had it.
    func attachVastView(to container: UIView) {
        vastHosts.removeAll { $0.view == nil || $0.view === container }
        vastHosts.append(WeakView(container))
        moveVastView(into: container)
    }

    /// Called when `container` is dismantled. If it was showing the ad, the ad goes back
    /// to the newest container still mounted, so the view that stays keeps playing it.
    func detachVastView(from container: UIView) {
        vastHosts.removeAll { $0.view == nil || $0.view === container }
        guard let adView = vastController?.imaadPlayerView,
              adView.superview == nil || adView.superview === container,
              let next = vastHosts.last?.view else { return }
        moveVastView(into: next)
    }

    private func moveVastView(into container: UIView) {
        guard let adView = vastController?.imaadPlayerView,
              adView.superview !== container else { return }
        adView.frame = container.bounds
        adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(adView)
    }

    func startTimerForNextAd() {
        timerNextAd?.invalidate()
        timerNextAd = nil

        let intervalInMinutes = activeCampaign?.properties?.intervalInMinutes

        if let intervalInMinutes, intervalInMinutes > 0 {
            print(Logger.log("Timer started for next ad [\(key)] - intervalInMinutes \(intervalInMinutes)"))
            timerNextAd = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalInMinutes.convertMinutesToSeconds()), repeats: false) { [weak self] _ in
                // Resolves even with no view mounted; the ad then waits for the next view.
                self?.timerNextAd = nil
                self?.findActiveAd()
            }
        } else {
            print(Logger.log("Timer not started [\(key)] - intervalInMinutes \(intervalInMinutes ?? 0)"))
        }
    }

    // MARK: - Derived

    var startAfterSeconds: Double {
        if activeInsideAd?.adType != .FULLSCREEN_NATIVE &&
            screen != InsideAdScreenLocations.reels.rawValue {
            return Double(activePlacement?.properties?.startAfterSeconds ?? 5)
        } else {
            return 0
        }
    }
}

/// Holds a view without keeping it alive, so the slot never outlives SwiftUI's hierarchy.
struct WeakView {
    weak var view: UIView?
    init(_ view: UIView) { self.view = view }
}
