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
    public var id: String?
    public var name: String?
    public var description: String?
    var weight: Int?
    public  var adType: AdType?
    var resellerID: String?
    var fallBackID: String?
    public var url: String?
    var properties: AdProperties?
    var fallback: InsideAd?
    var contentTargeting: [Targeting]?
}

class Targeting: Codable {
    let id: String?
    let version: Int?
    let createdOn: String? 
    let modifiedOn: String? 
    let name: String?
    let resellerId: String?
    let targets: [Target]?
    
    // Helper computed properties to get dates when needed
    var createdOnDate: Date? {
        guard let createdOn = createdOn else { return nil }
        return parseDate(from: createdOn)
    }
    
    var modifiedOnDate: Date? {
        guard let modifiedOn = modifiedOn else { return nil }
        return parseDate(from: modifiedOn)
    }
    
    private func parseDate(from string: String) -> Date? {
        let formatters = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()
        ] as [Any]
        
        for formatter in formatters {
            if let date = (formatter as AnyObject).date(from: string) {
                return date
            }
        }
        
        return nil
    }
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
    var startTime: String? 
    var endTime: String?
    var daysOfWeek: [String]?

    init(startTime: String, endTime: String, daysOfWeek: [String]) {
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
    }
}

public struct TargetModel {
    public var contentId: String?
    public var contentType: String?
    public var contentTitle: String?
    public var seriesId: String?
    public var contentProviderId: String?
    public var categoryIds: [String]?
    
    public init(contentId: String? = nil, contentType: String? = nil, contentTitle: String? = nil, seriesId: String? = nil, contentProviderId: String? = nil, categoryIds: [String]? = nil) {
        self.contentId = contentId
        self.contentType = contentType
        self.contentTitle = contentTitle
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
    
    func filterCampaignsByTimePeriod() -> [CampaignAppModel]? {
        return self.filter { campaign in
            if let periods = campaign.timePeriods {
                return periods.filterByTimeAndWeekDay().count > 0
            } else {
                // Add default timePeriods if missing
                let defaultPeriod = TimePeriod(
                    startTime: "00:00:00",
                    endTime: "23:59:59",
                    daysOfWeek: ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
                )
                let modifiedCampaign = campaign
                modifiedCampaign.timePeriods = [defaultPeriod]
                return true
            }
        }
    }
    
    func findActiveCampaignFromScreenAndTargetModel(screen: String?, targetModel: TargetModel?) -> CampaignAppModel? {
        var campaigns = CampaignManager.shared.allActiveCampaigns
        campaigns = campaigns.filterCampaignsByPlacementTags(tag: screen ?? "")
        campaigns = TargetManager.shared.filterCampaignsByContentTargeting(campaigns: campaigns, targetingObject: targetModel)
        if campaigns.count > 1 {
            return TargetManager.shared.selectObjectWithWeight(objects: campaigns)
        } else {
            return campaigns.first
        }
    }
    
    //Filter campaigns by placement tags
    func filterCampaignsByPlacementTags(tag: String) -> [CampaignAppModel] {
        //Filter campaigns by placement tags
        var allCampaigns = [CampaignAppModel]()

        //Check the placements of the campaigns and if the placement tags contain the screen name, then add the campaign to the list
        for campaign in self{
            if let placements = campaign.placements{
                var plmnts = [Placement]()
                for placement in placements {
                    if let tags = placement.tags, !tags.isEmpty{
                        if tags.contains(tag){
                            plmnts.append(placement)
                        }
                    }else{
                        //If the placement doesn't have any tags, then add the placement to the list
                        if tag == ""{
                            plmnts.append(placement)
                        }
                    }
                }
                if plmnts.count > 0{
                    campaign.placements = plmnts
                    allCampaigns.append(campaign)
                }
            }
        }
        return allCampaigns
    }

    //Filter campaigns by placement viewType
    func filterCampaignsByViewType(viewType: String) -> [CampaignAppModel] {
        var allCampaigns = [CampaignAppModel]()

        for campaign in self {
            if let placements = campaign.placements {
                var plmnts = [Placement]()
                for placement in placements {
                    if placement.viewType == viewType {
                        plmnts.append(placement)
                    }
                }
                campaign.placements = plmnts
                allCampaigns.append(campaign)
            }
        }
        return allCampaigns
    }

    //Exclude campaigns by placement viewType
    func excludeCampaignsByViewType(viewType: String) -> [CampaignAppModel] {
        var allCampaigns = [CampaignAppModel]()

        for campaign in self {
            if let placements = campaign.placements {
                var plmnts = [Placement]()
                for placement in placements {
                    if placement.viewType != viewType {
                        plmnts.append(placement)
                    }
                }
                campaign.placements = plmnts
                allCampaigns.append(campaign)
            }
        }
        return allCampaigns
    }
}

extension Array where Array.Element == TimePeriod{
    
    func filterByTime() -> [TimePeriod] {
        let periods = self.filter { $0.startTime != nil && $0.endTime != nil }
        let activePeriods = periods.filter {
            $0.startTime!.secondsFromBeginningOfTheDayFromString() <= Int(Date().secondsFromBeginningOfTheDay()) &&
            $0.endTime!.secondsFromBeginningOfTheDayFromString() >= Int(Date().secondsFromBeginningOfTheDay())
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
        //in case of rotation, the view gets redrawn, do not return another ad if there's ad already shown
        if CampaignManager.shared.activeInsideAd != nil && (AdsManager.shared.insideAdCallback != .UNKNOWN || AdsManager.shared.insideAdCallback != .ALL_ADS_COMPLETED){
            return CampaignManager.shared.activeInsideAd
        }
        
        var allAdsFromPlacement = [InsideAd]()
        
        // List of all ads in all placements that belong to the campaign that match the location.
        self.forEach({ allAdsFromPlacement.append(contentsOf: $0.ads ?? []) })
        
        return TargetManager.shared.selectObjectWithWeight(objects: allAdsFromPlacement)
    }
}

extension Array where Array.Element == InsideAd{
    func findBy(adId: String) -> InsideAd?{
        return self.filter { $0.id == adId }.first
    }
}

extension String {
    func secondsFromBeginningOfTheDayFromString() -> Int {
        var seconds = 0
        let timeComponents = self.split(separator: ":").map { String($0) }
        
        if let hours = Int(timeComponents[0]),
           let minutes = Int(timeComponents[1]),
           let seconds = Int(timeComponents[2]) {
            return (hours * 3600) + (minutes * 60) + seconds
        } else {
            return seconds
        }
    }
}
