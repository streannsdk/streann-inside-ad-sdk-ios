//
//  LocalVideoPlayerView.swift
//  TestTheLibrary
//
//  Created by Fani on 10.1.24.
//

import SwiftUI
import AVKit
import Combine

struct LocalVideoPlayerView: View {
    
    @StateObject var playerManager: PlayerManager
    
    public init(url: URL, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._playerManager = StateObject(wrappedValue: PlayerManager(url: url,
                                                                      insideAdCallback: insideAdCallback))
    }
    
    var body: some View {
        ZStack{
            AVPlayerControllerWrapper(player: playerManager.player)
            
            VStack{
                HStack{
                    Button("X") {
                        playerManager.stop()
                    }
                    
                    Spacer()
                    
                    Button("Mute") {
                        //
                    }
                }
                Spacer()
            }
            .onAppear{
                playerManager.play()
            }
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
            print("AVPlayer - status - readyToPlay")
            NotificationCenter.post(name: .AdsContentView_setFullSize)
            insideAdCallback = .STREAM_LOADED
        }else if status == .failed {
            print("AVPlayer - status - falied")
            NotificationCenter.post(name: .AdsContentView_setZeroSize)
            insideAdCallback = .IMAAdError("AVPlayer.status.falied")
        }else{
            print("AVPlayer - status - \(status)")
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

