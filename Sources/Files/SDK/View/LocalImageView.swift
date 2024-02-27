//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    @StateObject var imageLoader: ImageLoaderService
    @State var image: UIImage = UIImage()
    @Binding var insideAdCallback: InsideAdCallbackType
    var insideAd: InsideAd
    var viewModel: InsideAdViewModel
    
    public init(insideAd: InsideAd, viewModel: InsideAdViewModel, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
        self.insideAd = insideAd
        self.viewModel = viewModel
        self._imageLoader = StateObject(wrappedValue: ImageLoaderService(insideAdCallback: insideAdCallback, activeInsideAd: insideAd, viewModel: viewModel))
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width)
                .clipped()
            
            VStack{
                topView
                Spacer()
            }
            .padding(2)
        }
        .hide(if: insideAdCallback == .ALL_ADS_COMPLETED)
        .onReceive(imageLoader.$image) { image in
            self.image = image
            insideAdCallback = .LOADED
        }
        .task {
            if let _ = insideAd.url {
                imageLoader.loadImage()
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
            insideAdCallback = .ALL_ADS_COMPLETED
            NotificationCenter.post(name: .AdsContentView_setZeroSize)
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
}


class ImageLoaderService: ObservableObject {
    @Published var image: UIImage = UIImage()
    @Binding var insideAdCallback: InsideAdCallbackType
    var viewModel: InsideAdViewModel
    var activeInsideAd: InsideAd
    
    init(insideAdCallback: Binding<InsideAdCallbackType>, activeInsideAd: InsideAd, viewModel: InsideAdViewModel) {
        self._insideAdCallback = insideAdCallback
        self.activeInsideAd = activeInsideAd
        self.viewModel = viewModel
    }
    
    func loadImage() {
        guard let url = URL(string: activeInsideAd.url ?? "") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.viewModel.activeCampaign?.properties?.intervalInMinutes?.convertMinutesToSeconds() ?? 1 + (self.viewModel.activeInsideAd?.properties?.durationInSeconds ?? 1))) {
                    NotificationCenter.post(name: .AdsContentView_startTimer)
                    self.insideAdCallback = .IMAAdError(error?.localizedDescription ?? "")
                }
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data) ?? UIImage()
                NotificationCenter.post(name: .AdsContentView_setFullSize)
                self.insideAdCallback = .LOADED
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.activeInsideAd.properties?.durationInSeconds ?? 1)) {
                    self.insideAdCallback = .ALL_ADS_COMPLETED
                    NotificationCenter.post(name: .AdsContentView_setZeroSize)
                    NotificationCenter.post(name: .AdsContentView_startTimer)
                }
            }
        }
        task.resume()
    }
}
