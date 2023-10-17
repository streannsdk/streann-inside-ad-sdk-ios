//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import SwiftUI

struct InsideAdViewWrapper: UIViewControllerRepresentable {
    var screen: String
    let parent: InsideAdView
    var viewSize: CGSize
    
    func makeUIViewController(context: Context) -> InsideAdViewController {
        let controller = InsideAdViewController(insideAdCallbackDelegate: parent, size: viewSize)
        controller.screen = screen
        return controller
    }
    
    func updateUIViewController(_ uiViewController: InsideAdViewController, context: Context) {
        //
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: InsideAdViewWrapper
        
        init(parent: InsideAdViewWrapper) {
            self.parent = parent
        }
    }
}
