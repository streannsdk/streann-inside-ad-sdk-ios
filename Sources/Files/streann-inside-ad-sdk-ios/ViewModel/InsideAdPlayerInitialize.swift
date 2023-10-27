//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 29.9.23.
//

import Foundation
import SwiftUI

//Initiliaze the InsideAdPlayer with reseller and user data
public class StreannInsideAdSdk {
    public static func initializeSdk(baseUrl: String, apiKey: String,
                              siteUrl: String? = nil,
                              storeUrl: String? = nil,
                              descriptionUrl: String? = nil,
                              userBirthYear: Int64? = nil,
                              userGender: UserGender? = nil) {
      Constants.ResellerInfo.baseUrl = baseUrl
      Constants.ResellerInfo.apiKey = apiKey
      Constants.ResellerInfo.siteUrl = siteUrl ?? ""
      Constants.ResellerInfo.storeUrl = storeUrl ?? ""
      Constants.ResellerInfo.descriptionUrl = descriptionUrl ?? ""
      Constants.UserInfo.userBirthYear = userBirthYear
      Constants.UserInfo.userGender = userGender ?? .unknown
    }
    
    @ViewBuilder
    public func requestAd(screen: String, insideAdCallback: Binding<InsideAdCallbackType>) -> some View {
        InsideAdView(screen: screen, insideAdCallback: insideAdCallback)
    }
    
    public init() {}
}
