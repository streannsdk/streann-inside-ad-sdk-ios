//
//  LocalVideoPlayerView.swift
//  TestTheLibrary
//
//  Created by Fani on 10.1.24.
//

import SwiftUI
import AVKit

struct LocalVideoPlayerView: View {
    @EnvironmentObject var playerManager: LocalVideoManager
    @ObservedObject var slot: AdSlot

    private var insideAdCallback: InsideAdCallbackType { slot.insideAdCallback }
    
    var body: some View {
        ZStack{
            if insideAdCallback == .STARTED || insideAdCallback == .VOLUME_CHANGED(0) ||  insideAdCallback == .VOLUME_CHANGED(1) {
                VideoPlayer(player: playerManager.player)
                    .disabled(true)
                    .overlay(alignment: .top){
                        ZStack(alignment: .top){
                            LinearGradient(colors: [.black.opacity(0.4), .clear],
                                           startPoint: .top,
                                           endPoint: .center)
                            .frame(maxWidth: .infinity, maxHeight: 110)
                            
                            topView
                                .padding(8)
                        }
                    }
            }
        }
        .task {
            slot.localVideoManager.loadAsset()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(rawValue: Constants.Notifications.changeInsideAdSdkAdVolume)), perform: { notification in
            if let notification = notification.userInfo?[Constants.Notifications.isAdMuted] as? Bool {
                slot.localVideoManager.playerIsMuted = !notification
            }
        })
    }
}

//Views
extension LocalVideoPlayerView {
    @ViewBuilder
    private var topView: some View {
        HStack{
            closeButton
            Spacer()
            learnMoreButton
            volumeButton
        }
    }
    
    @ViewBuilder
    private var closeButton: some View {
        if slot.isCloseButtonVisible {
        Button {
            slot.localVideoManager.stop()
        } label: {
            Image(systemName: Constants.SystemImage.xMarkCircleFill)
                .foregroundColor(.white)
        }
        }
    }
    
    @ViewBuilder
    private var learnMoreButton: some View {
        if let urlString = slot.activeInsideAd?.properties?.clickThroughUrl,
           let url = URL(string: urlString) {
            Link(destination: url,
                 label: {
                Text("Learn more")
                    .foregroundStyle(.white)
            })
        }
    }
    
    private var volumeButton: some View {
        Button {
            slot.localVideoManager.playerIsMuted.toggle()
            slot.insideAdCallback = .VOLUME_CHANGED(slot.localVideoManager.playerIsMuted ? 0 : 1)
        } label: {
            Image(systemName: slot.localVideoManager.playerIsMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerWaveTwoFill)
                .foregroundColor(.white)
        }
    }
}

class LocalVideoManager: ObservableObject {
    /// Slot this manager belongs to. Set by AdSlot on creation.
    weak var slot: AdSlot?

    @Published var player = AVPlayer()
    @Published var playerIsMuted = Constants.ResellerInfo.isAdMuted {
        didSet{
            self.player.isMuted = playerIsMuted
            slot?.isAdMuted = self.player.isMuted
        }
    }
    
    var observer: NSKeyValueObservation? = nil

    // Everything below belongs to the current item and is cancelled in `destroy()`. Left
    // running, a start scheduled for an ad that was torn down could start the *next* ad
    // early, and each appearance of the view used to add another foreground observer.
    private var startWork: DispatchWorkItem?
    private var endObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    /// The ad is `STARTED` only once it is both loaded and past its start delay. It used to
    /// report `STARTED` as soon as the item was ready, so for the whole `startAfterSeconds`
    /// the host sized the tile, took a player slot and muted its cameras for a frozen
    /// first frame.
    private var isItemReady = false
    private var hasReportedStart = false

    func loadAsset() {
        if let url = URL(string: slot?.activeInsideAd?.url ?? "") {
            if player.currentItem == nil {
                //prepare the asset
                let asset = AVAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: playerItem)
                playerIsMuted = slot?.isAdMuted ?? Constants.ResellerInfo.isAdMuted
                
                //add observers
                // KVO can fire off the main thread; the start bookkeeping and the slot's
                // published state are main-thread only.
                self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
                    let status = playerItem.status
                    DispatchQueue.main.async {
                        guard self?.player.currentItem === playerItem else { return }
                        self?.playerItemStatusChanged(status)
                    }
                })
                endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
                    self?.stop()
                }

                // Resume after the app comes back, but only once the ad is due to be playing.
                foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                    guard let self, self.player.currentItem != nil, self.startWork == nil else { return }
                    self.play()
                }

                let work = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.startWork = nil
                    self.play()
                    self.reportStartIfDue()
                }
                startWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + (slot?.remainingStartDelay ?? 0), execute: work)
            }
        }
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        destroy()
        slot?.insideAdCallback = .ALL_ADS_COMPLETED
    }
    
    func destroy(){
        startWork?.cancel()
        startWork = nil
        isItemReady = false
        hasReportedStart = false
        [endObserver, foregroundObserver].compactMap { $0 }.forEach(NotificationCenter.default.removeObserver)
        endObserver = nil
        foregroundObserver = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        observer = nil
    }
    
    /// Reports `STARTED` once the item is ready and its start delay has passed, whichever
    /// comes last. `startWork` is nil once the delay has run.
    private func reportStartIfDue() {
        guard isItemReady, startWork == nil, !hasReportedStart, player.currentItem != nil else { return }
        hasReportedStart = true
        slot?.insideAdCallback = .STARTED
    }

    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            isItemReady = true
            reportStartIfDue()
        } else if status == .failed {
            print(Logger.log("Local Video Player Status Failed"))
            self.destroy()
            slot?.insideAdCallback = .TRIGGER_FALLBACK
        }
    }
}

