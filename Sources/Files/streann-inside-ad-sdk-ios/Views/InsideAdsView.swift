//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import SwiftUI

public struct InsideAdView: View, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: String
    var screen: String
    
    public init(screen: String, insideAdCallback: Binding<String>) {
        self._insideAdCallback = insideAdCallback
        self.screen = screen
    }
    
    public var body: some View {
        GeometryReader { geo in
            InsideAdViewWrapper(screen: screen, parent: self, viewSize: geo.size)
                .padding(.horizontal)
        }
    }
}

extension InsideAdView {
    //Delegate method to show the state of the insideAd player
    func insideAdCallbackReceived(data: String) {
        insideAdCallback = data
        print(Logger.log(insideAdCallback))
    }
}

struct InsideAdView_Previews: PreviewProvider {
    struct Test: View {
        var body: some View {
            InsideAdView(screen: "Screen", insideAdCallback: .constant("Started"))
        }
    }
    
    static var previews: some View {
        Test()
    }
}
