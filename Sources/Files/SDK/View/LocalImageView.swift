//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    @EnvironmentObject var localImageManager: LocalImageManager
    @Binding var insideAdCallback: InsideAdCallbackType
    
    var body: some View {
        ZStack {
            if let image = localImageManager.image {
                Image(uiImage: image)
                    .resizable()
                    .overlay {
                        VStack{
                            topView
                            Spacer()
                        }
                        .padding(2)
                    }
            }
        }
        .onChange(of: localImageManager.image) { image in
            if image != nil {
                insideAdCallback = .STARTED
            } else {
                insideAdCallback = .ALL_ADS_COMPLETED
            }
        }
        .task {
            localImageManager.loadImage()
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
            localImageManager.closeAdAndResetImage()
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

class LocalImageManager: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage() {
        if image != nil{
            return
        }
        guard let url = URL(string: (CampaignManager.shared.activeInsideAd?.url) ?? "") else { return }

        let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            guard let data = data else {
                //If the image is not loaded, trigger fallback
                DispatchQueue.main.async {
                    AdsManager.shared.insideAdCallback = .TRIGGER_FALLBACK
                }
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + CampaignManager.shared.startAfterSeconds) {
                self?.image = UIImage(data: data)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(CampaignManager.shared.activeInsideAd?.properties?.durationInSeconds ?? 1)) {
                    self?.closeAdAndResetImage()
                }
            }
        }
        task.resume()
    }
    
    func closeAdAndResetImage() {
        DispatchQueue.main.async {[weak self] in
            self?.image = nil
        }
    }
}
