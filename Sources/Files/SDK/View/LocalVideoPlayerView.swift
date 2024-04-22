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
    @ObservedObject var adsManager = AdsManager.shared
    
    @State private var playerIsMuted = false
    @Binding var insideAdCallback: InsideAdCallbackType
    
    var body: some View {
        ZStack{
            if insideAdCallback == .STARTED {
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
                    .onAppear {
                        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                            adsManager.localVideoManager.play()
                        }
                    }
            }
        }
        .task {
            adsManager.localVideoManager.loadAsset()
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
            adsManager.localVideoManager.stop()
        } label: {
            Image(systemName: Constants.SystemImage.xMarkCircleFill)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var learnMoreButton: some View {
        if let url = CampaignManager.shared.activeInsideAd?.properties?.clickThroughUrl {
            Link(destination: URL(string: url)!,
                 label: {
                Text("Learn more")
                    .foregroundStyle(.white)
            })
        }
    }
    
    private var volumeButton: some View {
        Button {
            adsManager.localVideoManager.player.isMuted.toggle()
            playerIsMuted.toggle()
        } label: {
            Image(systemName: playerIsMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerWaveTwoFill)
                .foregroundColor(.white)
        }
    }
}

class LocalVideoManager: ObservableObject {
    @Published var player = AVPlayer()
    var observer: NSKeyValueObservation? = nil
    
    func loadAsset() {
        if let url = URL(string: CampaignManager.shared.activeInsideAd?.url ?? "") {
            if player.currentItem == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + CampaignManager.shared.startAfterSeconds) {[weak self] in
                let asset = AVAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)
                    self?.player.replaceCurrentItem(with: playerItem)
                    self?.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
                    self?.playerItemStatusChanged(playerItem.status)
                })
                    self?.play()
                }
            }
        }
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        observer = nil
        AdsManager.shared.insideAdCallback = .ALL_ADS_COMPLETED
    }
    
    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            AdsManager.shared.insideAdCallback = .STARTED
            
            if let item = player.currentItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + CMTimeGetSeconds(item.duration)) { [weak self] in
                    AdsManager.shared.insideAdCallback = .ALL_ADS_COMPLETED
                    self?.player.replaceCurrentItem(with: nil)
                    self?.observer = nil
                }
            }
        } else if status == .failed {
            AdsManager.shared.insideAdCallback = .IMAAdError("AVPlayer.status.failed")
//                NotificationCenter.post(name: .AdsContentView_startTimer)
           player.replaceCurrentItem(with: nil)
            observer = nil
        } else{
            AdsManager.shared.insideAdCallback = .UNKNOWN
            player.replaceCurrentItem(with: nil)
            observer = nil
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
