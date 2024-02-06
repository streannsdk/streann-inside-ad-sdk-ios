//
//  InsideAdView].swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import SwiftUI

protocol InsideAdCallbackDelegate {
    func insideAdCallbackReceived(data: InsideAdCallbackType)
}

public struct InsideAdView: View, InsideAdCallbackDelegate {
//    @Environment(\.dismiss) var dismiss
    
    @Binding var insideAdCallback: InsideAdCallbackType
    var screen: String
    var viewSize: CGSize
    
    @State var loadingAderror = false
    @State var reload = false
     
    @StateObject var viewModel: InsideAdViewModel

     public init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>, viewSize:CGSize) {
        _insideAdCallback = insideAdCallback
        self.screen = screen
        self.viewSize = viewSize
          self._viewModel = StateObject(wrappedValue: InsideAdViewModel(screen: screen, 
                                                                        insideAdCallback: insideAdCallback,
                                                                        apiProtocolType: SDKAPI.self)) // for mock data - SDKAPIMock.self
    }
    
    public var body: some View {

            GeometryReader { geo in
                 if let activeInsideAd = viewModel.activeInsideAd {
                      if activeInsideAd.adType == .VAST {
                           InsideAdViewWrapper(screen: screen, parent: self, viewSize: viewSize,
                                               insideAd: $viewModel.activeInsideAd,
                                               activePlacement: $viewModel.activePlacement,
                                               geoIp: $viewModel.geoIp) //geo.size
                      }
                      else if activeInsideAd.adType == .LOCAL_VIDEO{
                           LocalVideoPlayerView(url: URL(string: activeInsideAd.url!)!,
                                                insideAdCallback: $insideAdCallback)
                      }
                      else if activeInsideAd.adType == .LOCAL_IMAGE{
                           EmptyView()
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
//                    self.dismiss()
                }
                print("insideAdCallback \(value)")
                insideAdCallback = value
                 
                if case let .IMAAdError(string) = insideAdCallback {
                    if !string.isEmpty {
                        loadingAderror = true
                        //self.dismiss()
                    }
                }
            })
    }
}

extension InsideAdView {
    //Delegate method to show the state of the insideAd player
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
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
