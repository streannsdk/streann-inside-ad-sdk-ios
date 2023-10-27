//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import SwiftUI

public struct InsideAdView: View, InsideAdCallbackDelegate {
    @Binding var insideAdCallback: InsideAdCallbackType
    var screen: String
    
    public init(screen: String, insideAdCallback: Binding<InsideAdCallbackType>) {
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
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}

struct InsideAdView_Previews: PreviewProvider {
    struct Test: View {
        var body: some View {
            InsideAdView(screen: "Screen", insideAdCallback: .constant(.UNKNOWN))
        }
    }
    
    static var previews: some View {
        Test()
    }
}
