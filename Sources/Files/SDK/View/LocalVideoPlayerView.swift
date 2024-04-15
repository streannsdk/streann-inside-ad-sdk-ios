//
//  LocalVideoPlayerView.swift
//  TestTheLibrary
//
//  Created by Fani on 10.1.24.
//

import SwiftUI
import AVKit

struct LocalVideoPlayerView: View {
    @State private var playerIsMuted = false
    @Binding var insideAdCallback: InsideAdCallbackType
    
    public init(insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
    }
    
    var body: some View {
        ZStack{
            if InsideAdSdk.shared.localVideoPlayerManager.player.status == .readyToPlay || insideAdCallback != .STARTED {
                AVPlayerControllerWrapper(insideAdCallback: $insideAdCallback)
                    .overlay(alignment: .top){
                        LinearGradient(colors: [.black.opacity(0.4), .clear],
                                       startPoint: .top,
                                       endPoint: .center)
                        .frame(maxWidth: .infinity, maxHeight: 110)
                    }
                
                VStack{
                    topView
                    Spacer()
                }
                .padding(2)
                .hide(if: !InsideAdSdk.shared.localVideoPlayerManager.playing)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    InsideAdSdk.shared.localVideoPlayerManager.play()
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                    }
                }
            }
        }
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
    
    private var closeButton: some View {
        Button {
            InsideAdSdk.shared.localVideoPlayerManager.stop()
        } label: {
            Image(systemName: Constants.SystemImage.xMarkCircleFill)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var learnMoreButton: some View {
        if let url = InsideAdSdk.shared.activeInsideAd?.properties?.clickThroughUrl {
            Link(destination: URL(string: url)!,
                 label: {
                Text("Learn more")
                    .foregroundStyle(.white)
            })
        }
    }
    
    private var volumeButton: some View {
        Button {
            InsideAdSdk.shared.localVideoPlayerManager.player.isMuted.toggle()
            playerIsMuted.toggle()
        } label: {
            Image(systemName: playerIsMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerWaveTwoFill)
                .foregroundColor(.white)
        }
    }
}

class LocalVideoPlayerManager : ObservableObject {
    @Published var playing = false
    
    var player = AVPlayer()
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
    var observer: NSKeyValueObservation? = nil
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    func loadAsset() {
        if player.currentItem == nil {
            let asset = AVAsset(url: URL(string: InsideAdSdk.shared.activeInsideAd?.url ?? "")!)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
            self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
                self?.playerItemStatusChanged(playerItem.status)
            })
            
            let startAfterSeconds:Double = InsideAdSdk.shared.activeInsideAd?.adType != .FULLSCREEN_NATIVE ? Double(InsideAdSdk.shared.activePlacement?.properties?.startAfterSeconds ?? 0) : 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + startAfterSeconds) {[weak self] in
                self?.play()
            }
        }
    }
    
    func play() {
        player.play()
        playing = true
    }
    
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        playing = false
        insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ALL_ADS_COMPLETED)
    }
    
    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: .STARTED)
            
            if let item = player.currentItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + CMTimeGetSeconds(item.duration)) { [weak self] in
                    self?.insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ALL_ADS_COMPLETED)
                    self?.playing = false
                    InsideAdSdk.shared.localVideoPlayerManager.player.replaceCurrentItem(with: nil)
                }
            }
        } else if status == .failed {
            if adRequestStatus == .adRequested {
                adRequestStatus = .fallbackRequested
                if let url = URL(string: InsideAdSdk.shared.activeInsideAd?.fallback?.url ?? "") {
                    preparePlayer(url: url)
                    player.play()
                }
            } else {
                insideAdCallbackDelegate?.insideAdCallbackReceived(data: .IMAAdError("AVPlayer.status.failed"))
                NotificationCenter.post(name: .AdsContentView_startTimer)
                InsideAdSdk.shared.localVideoPlayerManager.player.replaceCurrentItem(with: nil)
            }
        } else{
            insideAdCallbackDelegate?.insideAdCallbackReceived(data: .UNKNOWN)
            InsideAdSdk.shared.localVideoPlayerManager.player.replaceCurrentItem(with: nil)
        }
    }
    
    private func preparePlayer(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
            self?.playerItemStatusChanged(playerItem.status)
        })
    }
}

struct AVPlayerControllerWrapper : UIViewControllerRepresentable, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AVPlayerControllerWrapper>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player =  InsideAdSdk.shared.localVideoPlayerManager.player
        controller.showsPlaybackControls = false
//        InsideAdSdk.shared.localVideoPlayerManager.loadAsset()
        InsideAdSdk.shared.localVideoPlayerManager.insideAdCallbackDelegate = self
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<AVPlayerControllerWrapper>) {
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}
