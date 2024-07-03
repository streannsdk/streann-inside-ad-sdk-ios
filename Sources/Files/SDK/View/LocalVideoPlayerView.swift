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
    
    @Binding var insideAdCallback: InsideAdCallbackType
    
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(rawValue: Constants.Notifications.changeInsideAdSdkAdVolume)), perform: { notification in
            if let notification = notification.userInfo?[Constants.Notifications.isAdMuted] as? Bool {
                adsManager.localVideoManager.playerIsMuted = !notification
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
            adsManager.localVideoManager.playerIsMuted.toggle()
            insideAdCallback =  .VOLUME_CHANGED(adsManager.localVideoManager.playerIsMuted ? 0 : 1)
        } label: {
            Image(systemName: adsManager.localVideoManager.playerIsMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerWaveTwoFill)
                .foregroundColor(.white)
        }
    }
}

class LocalVideoManager: ObservableObject {
    @Published var player = AVPlayer()
    @Published var playerIsMuted = Constants.ResellerInfo.isAdMuted {
        didSet{
            self.player.isMuted = playerIsMuted
            Constants.ResellerInfo.isAdMuted = self.player.isMuted
        }
    }
    
    var observer: NSKeyValueObservation? = nil
    
    func loadAsset() {
        if let url = URL(string: CampaignManager.shared.activeInsideAd?.url ?? "") {
            if player.currentItem == nil {
                //prepare the asset
                let asset = AVAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: playerItem)
                playerIsMuted = Constants.ResellerInfo.isAdMuted
                
                //add observers
                self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { [weak self] (playerItem, change) in
                    self?.playerItemStatusChanged(playerItem.status)
                })
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                    self.stop()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + CampaignManager.shared.startAfterSeconds) {[weak self] in
                    //play
                    self?.play()
                }
            }
        }
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        destroy()
        AdsManager.shared.insideAdCallback = .ALL_ADS_COMPLETED
    }
    
    func destroy(){
        player.pause()
        player.replaceCurrentItem(with: nil)
        observer = nil
    }
    
    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            AdsManager.shared.insideAdCallback = .STARTED
        } else if status == .failed {
            print(Logger.log("Local Video Player Status Failed"))
            self.destroy()
            AdsManager.shared.insideAdCallback = .TRIGGER_FALLBACK
        }
    }
}

