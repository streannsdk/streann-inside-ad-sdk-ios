//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 27.9.23.
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
