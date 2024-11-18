//
//  InsideAdSdk.swift
//  TestTheLibrary
//
//  Created by Fani on 3.1.24.
//

import SwiftUI

public protocol InsideAdCallbackDelegate {
    func insideAdCallbackReceived(data: InsideAdCallbackType)
}

public class InsideAdSdk {
    public static let shared = InsideAdSdk()
    
    public var hasAdForReels: Bool = false
    public var intervalForReels: Int?
    public var activeInsideAd: InsideAd?
    public var vastTagUrl: String?

    public init(baseUrl: String,
                apiKey: String,
                apiToken: String,
                siteUrl: String? = nil,
                storeUrl: String? = nil,
                descriptionUrl: String? = nil,
                userBirthYear: Int64? = nil,
                userGender: UserGender? = nil) {
        Constants.ResellerInfo.baseUrl = baseUrl
        Constants.ResellerInfo.apiKey = apiKey
        Constants.ResellerInfo.apiToken = apiToken
        Constants.ResellerInfo.siteUrl = siteUrl ?? ""
        Constants.ResellerInfo.storeUrl = storeUrl ?? ""
        Constants.ResellerInfo.descriptionUrl = descriptionUrl ?? ""
        Constants.UserInfo.userBirthYear = userBirthYear
        Constants.UserInfo.userGender = userGender ?? .unknown
        CampaignManager.shared.getAllCampaigns()
    }
    
    public init() { }
    
    @ViewBuilder
    public func insideAdView(delegate: InsideAdCallbackDelegate, screen: String? = nil, isAdMuted: Bool = false, contentTargeting: TargetModel? = nil, rotateVolumeButton: Bool? = false) -> some View {
        AdsContentView(delegate: delegate, screen: screen, isAdMuted: isAdMuted, targetModel: contentTargeting, rotateVolumeButton: rotateVolumeButton)
    }

    public func removeAdView() {
        CampaignManager.shared.clearAll()
    }

    public func removeLocalVideoAdView(){
        AdsManager.shared.localVideoManager.stop()
    }

    public func removeVastAdView(){
        AdsManager.shared.clearAll()
    }
}
