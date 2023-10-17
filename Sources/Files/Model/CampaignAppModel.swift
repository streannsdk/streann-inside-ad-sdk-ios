//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 27.9.23.
//

import Foundation

class CampaignAppModel: Codable {
    var properties: [Properties]?
    var adType: String?
    var url: String?
    var campaignId: String?
    var adId: String?
    var placementId: String?
}

class Properties: Codable {
    var additionalProp1: String?
    var additionalProp2: String?
    var additionalProp3: String?
}
