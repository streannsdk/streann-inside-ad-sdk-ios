//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    @Binding var insideAdCallback: InsideAdCallbackType
        
    public init(insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
    }
    
    var body: some View {
        ZStack {
            if let image = InsideAdSdk.shared.imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                
                VStack{
                    topView
                    Spacer()
                }
                .padding(2)
                .hide(if: InsideAdSdk.shared.imageLoader.image == nil)
            }
        }
        .onReceive(InsideAdSdk.shared.imageLoader.$image) { image in
            if image != nil {
                insideAdCallback = .LOADED
            } else {
                insideAdCallback = .ALL_ADS_COMPLETED
            }
        }
        .task {
            if InsideAdSdk.shared.imageLoader.image == nil {
                InsideAdSdk.shared.imageLoader.loadImage()
            }
        }
    }
}

//Views
extension LocalImageView {
    @ViewBuilder
    private var topView: some View {
        HStack{
            closeButton
            Spacer()
            learnMoreButton
        }
    }
    
    private var closeButton: some View {
        Button {
            InsideAdSdk.shared.imageLoader.closeAdAndResetImage()
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
}

class LocalImageLoaderManager: ObservableObject {
    @Published var image: UIImage?
    var insideAdCallback: InsideAdCallbackType?
    
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    func loadImage() {
        guard let url = URL(string: (adRequestStatus == .adRequested ? InsideAdSdk.shared.activeInsideAd?.url : InsideAdSdk.shared.activeInsideAd?.fallback?.url) ?? "") else { return }

        let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            guard let data = data else {
                if self?.adRequestStatus == .adRequested {
                    self?.adRequestStatus = .fallbackRequested
                    self?.loadImage()
                    return
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.post(name: .AdsContentView_startTimer)
                        self?.insideAdCallback = .IMAAdError(error?.localizedDescription ?? "")
                    }
                    return
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + InsideAdSdk.shared.campaignManager.startAfterSeconds) {
                self?.image = UIImage(data: data)
                NotificationCenter.post(name: .AdsContentView_setFullSize)
                self?.insideAdCallback = .LOADED
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(InsideAdSdk.shared.activeInsideAd?.properties?.durationInSeconds ?? 1)) {
                    self?.closeAdAndResetImage()
                }
            }
        }
        task.resume()
    }
    
    func closeAdAndResetImage() {
        DispatchQueue.main.async {[weak self] in
            self?.insideAdCallback = .ALL_ADS_COMPLETED
            self?.image = nil
        }
    }
}
