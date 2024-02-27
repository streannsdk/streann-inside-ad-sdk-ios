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
    var insideAd: InsideAd
    
    public init(insideAd: InsideAd, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._playerManager = StateObject(wrappedValue: PlayerManager(url: URL(string: insideAd.url ?? "")!,
                                                                      insideAdCallback: insideAdCallback))
        self.insideAd = insideAd
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
        .hide(if: playerManager.player.currentItem?.status != .readyToPlay)
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
            Image(systemName: "xmark.circle.fill")
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
            Image(systemName: playerIsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .foregroundColor(.white)
        }
    }
}

class PlayerManager : ObservableObject {
    var player: AVPlayer
    @Published private var playing = false
    @Binding var insideAdCallback: InsideAdCallbackType
    private var observer: NSKeyValueObservation? = nil
    
    init(url: URL, insideAdCallback:Binding<InsideAdCallbackType>, playing: Bool = false) {
        self.playing = playing
        self._insideAdCallback = insideAdCallback
        
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
        NotificationCenter.post(name: .AdsContentView_setZeroSize)
        insideAdCallback = .STOP
    }
    
    func playerItemStatusChanged(_ status: AVPlayerItem.Status){
        if status == .readyToPlay {
            NotificationCenter.post(name: .AdsContentView_setFullSize)
            insideAdCallback = .STREAM_LOADED
        }else if status == .failed {
            NotificationCenter.post(name: .AdsContentView_setZeroSize)
            insideAdCallback = .IMAAdError("AVPlayer.status.falied")
        }else{
            insideAdCallback = .UNKNOWN
        }
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

