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
    
    @State var loadingAdError = false
    @State var reload = false
    @StateObject var viewModel: InsideAdViewModel
    
    init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>) {
         _insideAdCallback = insideAdCallback
         self._viewModel = StateObject(wrappedValue: InsideAdViewModel(screen: screen,
                                                                       insideAdCallback: insideAdCallback))
    }
    
    public var body: some View {
         VStack {
              if let activeInsideAd = viewModel.activeInsideAd {
                   switch activeInsideAd.adType {
                   case .VAST:
                        InsideAdViewWrapper(parent: self, insideAd: activeInsideAd,
                                            activePlacement: viewModel.activePlacement,
                                            geoIp: CampaignManager.shared.geoIp)
                        
                   case .LOCAL_IMAGE:
                        LocalImageView(activeInsideAd: activeInsideAd, viewModel: viewModel, insideAdCallback: $insideAdCallback)
                        
                   case .LOCAL_VIDEO:
                        LocalVideoPlayerView(insideAd: activeInsideAd,
                                             insideAdCallback: $insideAdCallback)
                        
                   case .BANNER:
                        BannerView(activeInsideAd: activeInsideAd, parent: self)
                        
                   case .FULLSCREEN_NATIVE:
                        // NativeAdView()
                       EmptyView()
                        
                   case .unsupported:
                        EmptyView()
                        
                   case .none:
                        EmptyView()
                   }
              } else {
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
              
              insideAdCallback = value

              if case let .IMAAdError(string) = insideAdCallback {
                   if !string.isEmpty {
                       loadingAdError = true
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
