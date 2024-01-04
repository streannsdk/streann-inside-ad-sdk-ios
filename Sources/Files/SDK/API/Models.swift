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
}

public class CampaignAppModel: Codable {
    var id: String?
    var name: String?
    var startDate: Date?
    var endDate: Date?
    var intervalInMinutes: Int?
    var weight: Int?
    var timePeriods: [TimePeriod]?
    //var properties: [String : Int]?
    var placements: [Placement]?
}

class Placement: Codable {
    var id: String?
    var name: String?
    var viewType: String?
    var screens: [String]?
    var startAfterSeconds: Int?
    var showCloseButtonAfterSeconds: Int?
    var ads: [InsideAd]?
//    var properties: [String : Double]?
}

class InsideAd: Codable {
    var id: String?
    var name: String?
    var weight: Int?
    var adType: String?
    var url: String?
    //var durationInSeconds: Int?
}

class TimePeriod: Codable {
    var startTime: Date? //00:00:00
    var endTime: Date? //23:30:45
    var daysOfWeek: [String]? //MONDAY, WEDNESDAY
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
    
    func getActiveCampaign() -> CampaignAppModel?{
        var activeCampaigns = self.filterCampaignsByDate()
        activeCampaigns = activeCampaigns.filterCampaignsByTimePeriod()
        activeCampaigns = activeCampaigns.sortByWeignt()
        
        return activeCampaigns.first ?? nil
    }
    
    func filterCampaignsByDate(currentDate:Date = Date()) -> [CampaignAppModel]{
        let campaigns = self.filter { $0.startDate != nil && $0.endDate != nil }
        let activeCampaigns = campaigns.filter { $0.startDate! <= currentDate && $0.endDate! >= currentDate }
        return activeCampaigns
    }
    
    func filterCampaignsByTimePeriod() -> [CampaignAppModel]{
        let activeCampaigns = self.filter { $0.timePeriods == nil || ($0.timePeriods?.filterByTimeAndWeekDay().count ?? 0) > 0 }
        return activeCampaigns
    }
    
    func sortByWeignt() -> [CampaignAppModel]{
        return self.sorted(by: { ($0.weight ?? -1000) > ($1.weight ?? -1000) })
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
    
    func getInsideAdByPlacement(screen: String) -> InsideAd?{
        var activeInsideAd: InsideAd? = nil
        
        let filteredPlacements = self.filter{
            if screen.isEmpty {
                $0.screens?.isEmpty ?? true
            }else{
                $0.screens?.contains(screen) ?? false
            }
        }
        
        if !filteredPlacements.isEmpty {
            if filteredPlacements.count > 1 {
                let adsByMultiplePlacements = filteredPlacements.flatMap { $0.ads ?? [] }.sortByWeignt()
                activeInsideAd = adsByMultiplePlacements.first
            }else{
                activeInsideAd = filteredPlacements.first?.ads?.sortByWeignt().first
            }
        }
        
        return activeInsideAd
    }
}

extension Array where Array.Element == InsideAd{
    
    func sortByWeignt() -> [InsideAd]{
        return self.sorted(by: { ($0.weight ?? -1000) > ($1.weight ?? -1000) })
    }
}
