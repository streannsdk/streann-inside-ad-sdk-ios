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
        if InsideAdSdk.shared.localVideoPlayerManager.player.currentItem?.status == .readyToPlay || insideAdCallback != .ALL_ADS_COMPLETED {
            ZStack{
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
    var player = AVPlayer()
    
    @Published var playing = false
    var insideAdCallbackDelegate: InsideAdCallbackDelegate?
    
    var observer: NSKeyValueObservation? = nil
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    func loadAsset() {
        if player.currentItem == nil {
            let asset = AVAsset(url: URL(string: InsideAdSdk.shared.activeInsideAd?.url ?? "")!)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
            //        player = AVPlayer(playerItem: playerItem)
            self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                self.playerItemStatusChanged(playerItem.status)
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + InsideAdSdk.shared.campaignManager.startAfterSeconds) {[weak self] in
                self?.player.play()
                self?.playing = true
            }
            
        }
    }
    
    func play() {
        player.play()
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
                DispatchQueue.main.asyncAfter(deadline: .now() + CMTimeGetSeconds(item.duration)) {
                    self.insideAdCallbackDelegate?.insideAdCallbackReceived(data: .ALL_ADS_COMPLETED)
                    self.playing = false
                    InsideAdSdk.shared.localVideoPlayerManager.player.replaceCurrentItem(with: nil)
                    NotificationCenter.post(name: .AdsContentView_startTimer)
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
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
            self.playerItemStatusChanged(playerItem.status)
        })
    }
}

struct AVPlayerControllerWrapper : UIViewControllerRepresentable, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AVPlayerControllerWrapper>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player =  InsideAdSdk.shared.localVideoPlayerManager.player
        controller.showsPlaybackControls = false
        InsideAdSdk.shared.localVideoPlayerManager.loadAsset()
        InsideAdSdk.shared.localVideoPlayerManager.insideAdCallbackDelegate = self
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<AVPlayerControllerWrapper>) {
        
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}
