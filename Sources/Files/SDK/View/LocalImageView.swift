//
//  LocalImageView.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.2.24.
//

import SwiftUI

struct LocalImageView: View {
    var insideAd: InsideAd
    @Binding var insideAdCallback: InsideAdCallbackType
    
    public init(insideAd: InsideAd, insideAdCallback: Binding<InsideAdCallbackType>) {
        self._insideAdCallback = insideAdCallback
        self.insideAd = insideAd
    }
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: insideAd.url ?? "")) { phase in
                if let image = phase.image {
                    image
                        .frame(maxWidth: UIScreen.main.bounds.width)
                        .scaledToFit()
                        .onAppear(perform: {
                            insideAdCallback = .LOADED
                        })
                }
            }
            
            VStack{
                topView
                Spacer()
            }
            .padding(2)
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
