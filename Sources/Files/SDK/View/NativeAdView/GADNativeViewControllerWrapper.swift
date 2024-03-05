//
//  GADNativeViewWrapper.swift
//  AdmobNativeSample
//
//

import UIKit
import SwiftUI

struct GADNativeViewControllerWrapper : UIViewControllerRepresentable {

  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = GADNativeViewController()
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

}

struct NativeAdView: View {
    
    public var body: some View {
        GADNativeViewControllerWrapper()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .ignoresSafeArea()
    }
}
