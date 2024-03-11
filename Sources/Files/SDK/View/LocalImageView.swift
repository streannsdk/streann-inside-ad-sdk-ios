//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    @StateObject var imageLoader: ImageLoaderService
    @Binding var insideAdCallback: InsideAdCallbackType
        
    public init(insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
        self._imageLoader = StateObject(wrappedValue: ImageLoaderService(insideAdCallback: insideAdCallback))
    }
    
    var body: some View {
        ZStack {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                
                VStack{
                    topView
                    Spacer()
                }
                .padding(2)
                .hide(if: imageLoader.image == nil)
            }
        }
        .onReceive(imageLoader.$image) { image in
            if image != nil {
                insideAdCallback = .LOADED
            }
        }
        .task {
            imageLoader.loadImage()
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
            imageLoader.closeAdAndResetImage()
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
}

class ImageLoaderService: ObservableObject {
    @Published var image: UIImage?
    @Binding var insideAdCallback: InsideAdCallbackType
    
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    init(insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
    }
    
    func loadImage() {
        
        guard let url = URL(string: (adRequestStatus == .adRequested ? CampaignManager.shared.activeInsideAd?.url : CampaignManager.shared.activeInsideAd?.fallback?.url) ?? "") else { return }
        print("ImageViewDidRecordImpression URL \(url)")
        let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            guard let data = data else {
                if self?.adRequestStatus == .adRequested {
                    self?.adRequestStatus = .fallbackRequested
                    self?.loadImage()
                    print("ImageViewDidRecordImpression self?.adRequestStatus == .adRequested \(url)")
                    return
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.post(name: .AdsContentView_startTimer)
                        self?.insideAdCallback = .IMAAdError(error?.localizedDescription ?? "")
                        print("ImageViewDidRecordImpression NotificationCenter.post")
                    }
                    return
                }
            }
            
            let startAfterSeconds:Double = CampaignManager.shared.activeInsideAd?.adType != .FULLSCREEN_NATIVE ? Double(CampaignManager.shared.activePlacement?.properties?.startAfterSeconds ?? 0) : 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + startAfterSeconds) {
                self?.image = UIImage(data: data)
                NotificationCenter.post(name: .AdsContentView_setFullSize)
                self?.insideAdCallback = .LOADED
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(CampaignManager.shared.activeInsideAd?.properties?.durationInSeconds ?? 1)) {
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
