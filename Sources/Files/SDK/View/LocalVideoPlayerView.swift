//
//  LocalVideoPlayerView.swift
//  TestTheLibrary
//
//  Created by Fani on 10.1.24.
//

import SwiftUI
import AVKit

struct LocalVideoPlayerView: View {
    @Environment(\.openURL) private var openURL
    @StateObject var playerManager: PlayerManager
    @State private var playerIsMuted = false
    @Binding var insideAdCallback: InsideAdCallbackType
    
    var insideAd: InsideAd
    
    public init(insideAd: InsideAd, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._playerManager = StateObject(wrappedValue: PlayerManager(url:URL(string: insideAd.url ?? "")!,
                                                                      insideAdCallback: insideAdCallback, insideAd: insideAd))
        self.insideAd = insideAd
        self._insideAdCallback = insideAdCallback
    }
    
    var body: some View {
        ZStack{
            AVPlayerControllerWrapper(player: playerManager.player)
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
            .onAppear{
                playerManager.play()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                playerManager.play()
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            }
        }
        .hide(if: playerManager.player.currentItem?.status != .readyToPlay || insideAdCallback == .ALL_ADS_COMPLETED)
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
            playerManager.stop()
        } label: {
            Image(systemName: Constants.SystemImage.xMarkCircleFill)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var learnMoreButton: some View {
        if let url = insideAd.properties?.clickThroughUrl {
            Link(destination: URL(string: url)!,
                 label: {
                Text("Learn more")
                    .foregroundStyle(.white)
            })
        }
    }
    
    private var volumeButton: some View {
        Button {
            playerManager.player.isMuted.toggle()
            playerIsMuted.toggle()
        } label: {
            Image(systemName: playerIsMuted ? Constants.SystemImage.speakerSlashFill : Constants.SystemImage.speakerWaveTwoFill)
                .foregroundColor(.white)
        }
    }
}

class PlayerManager : ObservableObject {
    var player: AVPlayer
    var insideAd: InsideAd
    
    @Published private var playing = false
    @Binding var insideAdCallback: InsideAdCallbackType
    
    private var observer: NSKeyValueObservation? = nil
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    init(url: URL, insideAdCallback:Binding<InsideAdCallbackType>, playing: Bool = false, insideAd: InsideAd) {
        self.playing = playing
        self._insideAdCallback = insideAdCallback
        self.insideAd = insideAd
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
            self.playerItemStatusChanged(playerItem.status)
        })
    }
    
    func play() {
        player.play()
        playing = true
    }
    
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        playing = false
        
        insideAdCallback = .ALL_ADS_COMPLETED
    }
    
    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            NotificationCenter.post(name: .AdsContentView_setFullSize)
            insideAdCallback = .STARTED
            
            if let item = player.currentItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + CMTimeGetSeconds(item.duration)) {
                    self.insideAdCallback = .ALL_ADS_COMPLETED
                }
            }
        } else if status == .failed {
            if adRequestStatus == .adRequested {
                adRequestStatus = .fallbackRequested
                if let url = URL(string: insideAd.fallback?.url ?? "") {
                    preparePlayer(url: url)
                    player.play()
                }
            } else {
                insideAdCallback = .IMAAdError("AVPlayer.status.failed")
                NotificationCenter.post(name: .AdsContentView_startTimer)
                print("playerStatus IMAAdError: \(insideAdCallback)")
            }
        } else{
            insideAdCallback = .UNKNOWN
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

struct AVPlayerControllerWrapper : UIViewControllerRepresentable {
    var player : AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}

extension AVPlayerViewController{
    func stopPlayer(){
        player?.replaceCurrentItem(with: nil)
    }
}
