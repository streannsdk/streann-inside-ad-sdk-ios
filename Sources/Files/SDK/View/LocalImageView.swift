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
    var insideAd: InsideAd
    @Binding var insideAdCallback: InsideAdCallbackType
    
    public init(insideAd: InsideAd, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
        self.insideAd = insideAd
        self._imageLoader = StateObject(wrappedValue: ImageLoaderService(insideAdCallback: insideAdCallback))
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width)
                .onReceive(imageLoader.$image) { image in
                    self.image = image
                    insideAdCallback = .LOADED
                }
                .onAppear {
                    if let url = insideAd.url {
                        imageLoader.loadImage(for: url)
                    }
                }
            VStack{
                topView
                Spacer()
            }
            .padding(2)
        }
        .hide(if: insideAdCallback == .ALL_ADS_COMPLETED)
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
    
    init(insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
    }
    
    func loadImage(for urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                self.insideAdCallback = .IMAAdError(error?.localizedDescription ?? "")
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data) ?? UIImage()
            }
        }
        task.resume()
    }
}
