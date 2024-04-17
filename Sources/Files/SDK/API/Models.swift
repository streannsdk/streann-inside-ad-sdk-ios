//
//  Models.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import Foundation

class GeoIp: Codable {
    var asName: String?
    var asNumber: Int?
    var areaCode: Int?
    var city: String?
    var connectionSpeed: String?
    var connectionType: String?
    var continentCode: String?
    var countryCode: String?
    var countryCode3: String?
    var country: String?
    var latitude: String?
    var longitude: String?
    var metroCode:Int?
    var postalCode: String?
    var proxyDescription: String?
    var proxyType: String?
    var region: String?
    var ip: String?
    var UTCOffset: Int?
    
    enum CodingKeys: String, CodingKey {
        case asName = "AsName"
        case asNumber = "AsNumber"
        case areaCode = "AreaCode"
        case city
        case connectionSpeed = "ConnSpeed"
        case connectionType = "ConnType"
        case continentCode = "ContinentCode"
        case countryCode
        case countryCode3 = "CountryCode3"
        case country
        case latitude
        case longitude
        case metroCode = "MetroCode"
        case postalCode = "PostalCode"
        case proxyDescription = "ProxyDescription"
        case proxyType = "ProxyType"
        case region = "Region"
        case ip
        case UTCOffset
    }
}

class GeoIpUrl: Codable {
  var geoIpUrl: String
    
    init(geoIpUrl: String) {
        self.geoIpUrl = geoIpUrl
    }
}

public class CampaignAppModel: Codable, WeightedObjectProtocol {
    var id: String?
    var name: String?
    var startDate: Date?
    var endDate: Date?
    var platforms: [String]?
    var allowedCountries: [String]?
    var restrictedCountries: [String]?
    var weight: Int?
    var timePeriods: [TimePeriod]?
    var placements: [Placement]?
    var properties: CampaignAppModelProperties?
    var targeting: [Targeting]?
}

public class Placement: Codable {
    var id: String?
    var name: String?
    var viewType: String?
    var tags: [String]?
    public var ads: [InsideAd]?
    public var properties: PlacementProperties?
}

public class PlacementProperties: Codable {
    var startAfterSeconds: Int?
    var showCloseButtonAfterSeconds: Int?
    var webSettings: WebSettings?
    public var intervalForReels: Int?
}

public class InsideAd: Codable, WeightedObjectProtocol {
    var id: String?
    var name: String?
    var description: String?
    var weight: Int?
    public  var adType: AdType?
    var resellerID: String?
    var fallBackID: String?
    var url: String?
    var properties: AdProperties?
    var fallback: Fallback?
    var contentTargeting: [Targeting]?
}

class Fallback: Codable {
    var id: String?
    var name: String?
    var description: String?
    var weight: Int?
    public var adType: AdType?
    var resellerID: String?
    var fallbackID: String?
    var url: String?
    var properties: AdProperties?
}

class Targeting: Codable {
    let id: String?
    let version: Int?
    let createdOn: Date?
    let modifiedOn: Date?
    let name: String?
    let resellerId: String?
    let targets: [Target]?
}

class Target: Codable {
    let ids: [String]?
    let type: String?
}

class CampaignAppModelProperties: Codable {
    var intervalInMinutes: Double?
}

class AdProperties: Codable {
    var durationInSeconds: Int?
    var sizes: [Size]?
    var clickThroughUrl: String?
}

class Size: Codable {
    var width: Int?
    var height: Int?
}

class WebSettings: Codable {
    var advancedScript: String?
    var styles: String?
    var screen: [String]?
}

public enum AdType: String, Codable {
    case VAST
    case LOCAL_IMAGE
    case LOCAL_VIDEO
    case BANNER
    case FULLSCREEN_NATIVE
    case unsupported
    
    init(fromRawValue: String) {
        self = AdType(rawValue: fromRawValue) ?? .unsupported
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = AdType(rawValue: string) ?? .unsupported
    }
}

class TimePeriod: Codable {
    var startTime: Date? //00:00:00
    var endTime: Date? //23:30:45
    var daysOfWeek: [String]? //MONDAY, WEDNESDAY
}

public struct TargetModel {
    public var contentId: String?
    public var contentType: String?
    public var seriesId: String?
    public var contentProviderId: String?
    public var categoryIds: [String]?
    
    public init(contentId: String? = nil, contentType: String? = nil, seriesId: String? = nil, contentProviderId: String? = nil, categoryIds: [String]? = nil) {
        self.contentId = contentId
        self.contentType = contentType
        self.seriesId = seriesId
        self.contentProviderId = contentProviderId
        self.categoryIds = categoryIds
    }
}

extension CampaignAppModel: Comparable {
    
    public static func == (lhs: CampaignAppModel, rhs: CampaignAppModel) -> Bool {
        if lhs.id != rhs.id {
            return true
        } else {
            return false
        }
    }
    
    public static func < (lhs: CampaignAppModel, rhs: CampaignAppModel) -> Bool {
        if (lhs.weight ?? -1000) < (rhs.weight ?? -1000) {
            return true
        } else {
            return false
        }
    }
}

extension Array where Array.Element == CampaignAppModel{
    
    func sortActiveCampaign() -> [CampaignAppModel]?{
        let activeCampaigns = self.filterCampaignsByTimePeriod() ?? self
        return activeCampaigns
    }
    
    func filterCampaignsByTimePeriod() -> [CampaignAppModel]?{
        let activeCampaigns = self.filter { $0.timePeriods == nil || ($0.timePeriods?.filterByTimeAndWeekDay().count ?? 0) > 0 }
        return activeCampaigns
    }
    
    func findActiveCampaignFromScreenAndTargetModel(screen: String, targetModel: TargetModel?) -> CampaignAppModel? {
        var campaigns = CampaignManager.shared.allActiveCampaigns
        campaigns = campaigns.filterCampaignsByPlacementTags(tags: screen)
        campaigns = TargetManager.shared.filterCampaignsByContentTargeting(campaigns: campaigns, targetingObject: targetModel)
        if campaigns.count > 1 {
            return TargetManager.shared.selectObjectWithWeight(objects: campaigns)
        } else {
            return campaigns.first
        }
    }
    
    //Filter campaigns by placement tags
    func filterCampaignsByPlacementTags(tags: String) -> [CampaignAppModel] {
        return self.filter { $0.placements?.contains(where: { $0.tags?.contains(where: { tags.contains($0) }) ?? false }) ?? false }
    }
}

extension Array where Array.Element == TimePeriod{
    
    func filterByTime() -> [TimePeriod] {
        let periods = self.filter { $0.startTime != nil && $0.endTime != nil }
        let activePeriods = periods.filter {
            $0.startTime!.secondsFromBeginningOfTheDay() <= Date().secondsFromBeginningOfTheDay() &&
            $0.endTime!.secondsFromBeginningOfTheDay() >= Date().secondsFromBeginningOfTheDay()
        }
        return activePeriods
    }
    
    func filterByTimeAndWeekDay() -> [TimePeriod]{
        var activePeriods = self.filterByTime()
        let datOfWeek = Date().dayOfWeek().uppercased()
        activePeriods = activePeriods.filter { $0.daysOfWeek?.contains(datOfWeek) ?? false }
        return activePeriods
    }
}

extension Array where Array.Element == Placement{
    
    func findBy(adId: String) -> Placement? {
        self.filter { ($0.ads ?? []).findBy(adId: adId) != nil }.first
    }
    
    func activeAdFromPlacement() -> InsideAd? {
        var allAdsFromPlacement = [InsideAd]()
        
        //All placements from the activeCampaign
        CampaignManager.shared.allActiveCampaigns.forEach { CampaignManager.shared.allPlacements.append(contentsOf: $0.placements ?? []) }
        
        // List of all ads in all placements that belong to the campaign that match the location.
        InsideAdSdk.shared.activeCampaign?.placements?.forEach({ allAdsFromPlacement.append(contentsOf: $0.ads ?? []) })
        
        return TargetManager.shared.selectObjectWithWeight(objects: allAdsFromPlacement)
    }
}

extension Array where Array.Element == InsideAd{
    func findBy(adId: String) -> InsideAd?{
        return self.filter { $0.id == adId }.first
    }
}
