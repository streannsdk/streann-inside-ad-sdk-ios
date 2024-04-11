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
     
     public var body: some View {
          Group {
               if let activeInsideAd = InsideAdSdk.shared.activeInsideAd {
                    switch activeInsideAd.adType {
                    case .VAST:
                         VastViewWrapper(insideAdCallback: $insideAdCallback)
                              .task {
                                   if !InsideAdSdk.shared.campaignManager.vastRequested {
                                        InsideAdSdk.shared.vastController.requestAds()
                                        InsideAdSdk.shared.campaignManager.vastRequested = true
                                   }
                              }
                         
                    case .LOCAL_IMAGE:
                         LocalImageView(insideAdCallback: $insideAdCallback)
                         
                    case .LOCAL_VIDEO:
                         LocalVideoPlayerView(insideAdCallback: $insideAdCallback)
                         
                    case .BANNER:
                         BannerAdViewWrapper(insideAdCallback: self)
                         
                    case .FULLSCREEN_NATIVE:
                         NativeAdView()
                         
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
               print("insideCallBack \(value)")
               if value == .STARTED {
                    NotificationCenter.post(name: .AdsContentView_setFullSize)
               }
               else if value == .ALL_ADS_COMPLETED {
                    NotificationCenter.post(name: .AdsContentView_setZeroSize)
                    NotificationCenter.post(name: .AdsContentView_startTimer)
                    InsideAdSdk.shared.campaignManager.vastRequested = false
                    InsideAdSdk.shared.campaignManager.adLoaded = true
               }
                              
               if case let .IMAAdError(string) = insideAdCallback {
                    if !string.isEmpty {
                         loadingAdError = true
                    }
               }
          })
          .task {
            InsideAdSdk.shared.campaignManager.adLoaded = false
          }
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
