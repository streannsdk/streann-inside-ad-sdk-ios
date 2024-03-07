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
    var viewModel: InsideAdViewModel
    var activeInsideAd: InsideAd
    @State var hideControls = true
    
    public init(activeInsideAd: InsideAd, viewModel: InsideAdViewModel, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
        self.activeInsideAd = activeInsideAd
        self.viewModel = viewModel
        self._imageLoader = StateObject(wrappedValue: ImageLoaderService(insideAdCallback: insideAdCallback, activeInsideAd: activeInsideAd, viewModel: viewModel))
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
        if let url = activeInsideAd.properties?.clickThroughUrl {
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
    var viewModel: InsideAdViewModel
    var activeInsideAd: InsideAd
    
    private var adRequestStatus: AdRequestStatus = .adRequested
    
    init(insideAdCallback: Binding<InsideAdCallbackType>, activeInsideAd: InsideAd, viewModel: InsideAdViewModel) {
        self._insideAdCallback = insideAdCallback
        self.activeInsideAd = activeInsideAd
        self.viewModel = viewModel
    }
    
    func loadImage() {
        
        guard let url = URL(string: (adRequestStatus == .adRequested ? activeInsideAd.url : activeInsideAd.fallback?.url) ?? "") else { return }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(self?.viewModel.activePlacement?.properties?.startAfterSeconds ?? 1)) {
                self?.image = UIImage(data: data)
                NotificationCenter.post(name: .AdsContentView_setFullSize)
                self?.insideAdCallback = .LOADED
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self?.activeInsideAd.properties?.durationInSeconds ?? 1)) {
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
