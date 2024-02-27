//
//  InsideAdView].swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import SwiftUI

public protocol InsideAdCallbackDelegate {
    func insideAdCallbackReceived(data: InsideAdCallbackType)
}

public struct InsideAdView: View, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    var screen: String
    @State var loadingAderror = false
    @State var reload = false
     
    @StateObject var viewModel: InsideAdViewModel

     public init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>) {
        _insideAdCallback = insideAdCallback
        self.screen = screen
        self._viewModel = StateObject(wrappedValue: InsideAdViewModel(screen: screen,
                                                                        insideAdCallback: insideAdCallback,
                                                                        apiProtocolType: SDKAPI.self))
    }
    
     public var body: some View {
          VStack {
               if let activeInsideAd = viewModel.activeInsideAd {
                    if activeInsideAd.adType == .VAST {
                        InsideAdViewWrapper(screen: screen, parent: self,
                                            insideAd: activeInsideAd,
                                            activePlacement: $viewModel.activePlacement,
                                            geoIp: $viewModel.geoIp) //geo.size
                    }
                   else if activeInsideAd.adType == .LOCAL_VIDEO{
                        LocalVideoPlayerView(insideAd: activeInsideAd,
                                             insideAdCallback: $insideAdCallback)
                   }
                    else if activeInsideAd.adType == .BANNER {
                         BannerView(insideAdViewModel: viewModel, parent: self)
                    }
                    else if activeInsideAd.adType == .LOCAL_IMAGE{
                        LocalImageView(insideAd: activeInsideAd, insideAdCallback: $insideAdCallback)
                    }
                    else{
                         EmptyView()
                    }
               }else{
                    EmptyView()
               }
          }
          .onChange(of: insideAdCallback, perform: { value in
               if value == .STARTED {
                    NotificationCenter.post(name: .AdsContentView_setFullSize)
               }
               else if value == .ALL_ADS_COMPLETED {
                    NotificationCenter.post(name: .AdsContentView_setZeroSize)
                    NotificationCenter.post(name: .AdsContentView_startTimer)
               }
               print("insideAdCallback \(value)")
               insideAdCallback = value
               
               if case let .IMAAdError(string) = insideAdCallback {
                    if !string.isEmpty {
                         loadingAderror = true
                    }
               }
          })
     }
}

extension InsideAdView {
    //Delegate method to show the state of the insideAd player
     public func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}

// modifier
struct HideViewModifier: ViewModifier {
    let isHidden: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if isHidden {
            EmptyView()
        } else {
            content
        }
    }
}

// Extending on View to apply to all Views
extension View {
    func hide(if isHiddden: Bool) -> some View {
        ModifiedContent(content: self,
                        modifier: HideViewModifier(isHidden: isHiddden)
        )
    }
}
