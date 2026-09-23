//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    @EnvironmentObject var localImageManager: LocalImageManager
    @ObservedObject var slot: AdSlot
    
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
                slot.insideAdCallback = .STARTED
            } else {
                slot.insideAdCallback = .ALL_ADS_COMPLETED
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
    
    @ViewBuilder
    private var closeButton: some View {
        if slot.isCloseButtonVisible {
            Button {
                localImageManager.closeAdAndResetImage()
            } label: {
                Image(systemName: Constants.SystemImage.xMarkCircleFill)
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private var learnMoreButton: some View {
        if let urlString = slot.activeInsideAd?.properties?.clickThroughUrl, let url = URL(string: urlString) {
            Link(destination: url,
                 label: {
                Text("Learn more")
                    .foregroundStyle(.white)
            })
        }
    }
}

class LocalImageManager: ObservableObject {
    /// Slot this manager belongs to. Set by AdSlot on creation.
    weak var slot: AdSlot?

    @Published var image: UIImage?

    // The pending download, show and close for the current ad, all cancelled by `reset()`.
    // Left running, a view mounted again started a second load, and the first load's close
    // timer then ended the second ad early.
    private var loadTask: URLSessionDataTask?
    private var showWork: DispatchWorkItem?
    private var closeWork: DispatchWorkItem?

    func loadImage() {
        // Already showing, or on its way.
        if image != nil || loadTask != nil || showWork != nil {
            return
        }
        guard let url = URL(string: (slot?.activeInsideAd?.url) ?? "") else { return }

        let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadTask = nil
                guard let data = data else {
                    //If the image is not loaded, trigger fallback
                    self.slot?.insideAdCallback = .TRIGGER_FALLBACK
                    return
                }

                let show = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.showWork = nil
                    self.image = UIImage(data: data)

                    let close = DispatchWorkItem { [weak self] in
                        self?.closeWork = nil
                        self?.image = nil
                    }
                    self.closeWork = close
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.slot?.activeInsideAd?.properties?.durationInSeconds ?? 1), execute: close)
                }
                self.showWork = show
                DispatchQueue.main.asyncAfter(deadline: .now() + (self.slot?.remainingStartDelay ?? 0), execute: show)
            }
        }
        loadTask = task
        task.resume()
    }
    
    func closeAdAndResetImage() {
        DispatchQueue.main.async {[weak self] in
            self?.closeWork?.cancel()
            self?.closeWork = nil
            self?.image = nil
        }
    }

    /// Drops the current ad and anything still scheduled for it.
    func reset() {
        loadTask?.cancel()
        loadTask = nil
        showWork?.cancel()
        showWork = nil
        closeWork?.cancel()
        closeWork = nil
        image = nil
    }
}

