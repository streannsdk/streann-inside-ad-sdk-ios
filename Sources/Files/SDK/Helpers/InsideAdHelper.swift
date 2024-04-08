//
//  InsideAdHelper.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 26.9.23.
//

import Foundation
import WebKit
import AdSupport
import AppTrackingTransparency
import CryptoKit
import CoreTelephony
import SystemConfiguration
import CoreLocation
import SwiftUI

class InsideAdHelper {
    var webView = WKWebView(frame: .zero)
    var userAgent = ""
    
    init() {
        getUserAgent()
    }
    
    // MARK: - Populate VAST URL
    //aer serv documentaiton - https://support.aerserv.com/hc/en-us/articles/202407154-VAST-Tag-Integration-Guide-aerVideo-Ad-Unit-#VASTTagIntegrationGuide-MacroDefinitions
    //req: appname, siteurl, bundleid, appdomain, cb, dnt, oid OR adid, ip, make, model, os, osv, ua
    //not req: appversion, network, lat, long, locationsource, type, carrier, dw, dh
    
    func populateVastFrom(adUrl: String,
                          geoModel: GeoIp,
                          playerSize: CGSize) -> String {
        
        var url = adUrl
        
        //Player height
        if url.contains("[STREANN-PLAYER-HEIGHT]") {
            url = url.replacingOccurrences(of:  "[STREANN-PLAYER-HEIGHT]", with: String(format:"%.f", playerSize.height))
        }
        
        //Player width
        if url.contains("[STREANN-PLAYER-WIDTH]") {
            url = url.replacingOccurrences(of:  "[STREANN-PLAYER-WIDTH]", with: String(format:"%.f", playerSize.width))
        }
        
        //App ID
        if url.contains("[STREANN-APP-BUNDLE-ID]") {
            url = url.replacingOccurrences(of: "[STREANN-APP-BUNDLE-ID]", with: Bundle.main.bundleIdentifier ?? "")
        }
        
        //App Name
        if url.contains("[STREANN-APP-NAME]") {
            url = url.replacingOccurrences(of: "[STREANN-APP-NAME]", with: Utils.getAppIdentifier())
        }
        
        //App Version
        if url.contains("[STREANN-APP-VERSION]") {
            url = url.replacingOccurrences(of: "[STREANN-APP-VERSION]", with: Bundle.main.releaseVersionNumber ?? "")
        }
        
        //App Domain and Site url
        if url.contains("[STREANN-APP-DOMAIN]") {
            url = url.replacingOccurrences(of: "[STREANN-APP-DOMAIN]", with: Constants.ResellerInfo.siteUrl)
        }
        
        //App Store URL
        if url.contains("[STREANN-APP-STORE-URL]") {
            url = url.replacingOccurrences(of: "[STREANN-APP-STORE-URL]", with: Constants.ResellerInfo.storeUrl)
        }
        
        //Site URL
        if url.contains("[STREANN-SITE-URL]") {
            url = url.replacingOccurrences(of: "[STREANN-SITE-URL]", with: Constants.ResellerInfo.descriptionUrl)
        }
        
        //Content ID
        if url.contains("[STREANN-CONTENT-ID]") {
            url = url.replacingOccurrences(of:  "[STREANN-CONTENT-ID]", with: "")
        }
        
        //Content Title
        if url.contains("[STREANN-CONTENT-TITLE]") {
            url = url.replacingOccurrences(of:  "[STREANN-CONTENT-TITLE]", with: "")
        }
        
        //Content Length (duration)
        if url.contains("[STREANN-CONTENT-LENGTH]") {
            url = url.replacingOccurrences(of:  "[STREANN-CONTENT-LENGTH]", with: "")
        }
        
        //Content URL
        if url.contains("[STREANN-CONTENT-URL]") {
            url = url.replacingOccurrences(of:  "[STREANN-CONTENT-URL]", with: "")
        }
        
        //Content URL, encoded
        if url.contains("[STREANN-CONTENT-ENCODED-URL]") {
            url = url.replacingOccurrences(of:  "[STREANN-CONTENT-ENCODED-URL]", with: "")
        }
        
        //Description URL
        if url.contains("[STREANN-DESCRIPTION-URL]") {
            url = url.replacingOccurrences(of:  "[STREANN-DESCRIPTION-URL]", with: Constants.ResellerInfo.descriptionUrl)
        }
        
        //Device ID
        if url.contains("[STREANN-DEVICE-ID]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-ID]", with: UIDevice.current.identifierForVendor?.uuidString ?? "")
        }
        
        //Device network type
        if url.contains("[STREANN-NETWORK]") {
            url = url.replacingOccurrences(of:  "[STREANN-NETWORK]", with: geoModel.connectionType ?? getConnectionType())
        }
        
        //Device Carrier
        //'CTCarrier' was deprecated in iOS 16.0: Deprecated with no replacement. The getNetworkProvider func returns "--"
        if url.contains("[STREANN-CARRIER]") {
            url = url.replacingOccurrences(of:  "[STREANN-CARRIER]", with: geoModel.asName ?? "")
        }
        
        //Device Manufacturer
        if url.contains("[STREANN-DEVICE-MANUFACTURER]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-MANUFACTURER]", with: Constants.DeviceInfo.manufacturer)
        }
        
        //Device Model
        if url.contains("[STREANN-DEVICE-MODEL]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-MODEL]", with: UIDevice.current.model)
        }
        
        //Device OS
        if url.contains("[STREANN-DEVICE-OS]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-OS]", with: Constants.DeviceInfo.OS)
        }
        
        //Device OS version
        if url.contains("[STREANN-DEVICE-OS-VERSION]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-OS-VERSION]", with: UIDevice.current.systemVersion)
        }
        
        //Device type
        if url.contains("[STREANN-DEVICE-TYPE]") {
            url = url.replacingOccurrences(of: "[STREANN-DEVICE-TYPE]", with: Constants.DeviceInfo.deviceType)
        }
        
        //Device IP address
        if url.contains("[STREANN-IP]") {
            url = url.replacingOccurrences(of: "[STREANN-IP]", with: geoModel.ip ?? "")
        }
        
        //Device User Agent
        if url.contains("[STREANN-UA]") {
            url = url.replacingOccurrences(of:  "[STREANN-UA]", with: userAgent)
        }
        
        //Device ID type
        if url.contains("[STREANN-IFA-TYPE]") {
            url = url.replacingOccurrences(of:  "[STREANN-IFA-TYPE]", with: "")
        }
        
        //Advertising ID
        if url.contains("[STREANN-ADVERTISING-ID]") {
            url = url.replacingOccurrences(of: "[STREANN-ADVERTISING-ID]", with: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
        }
        
        //Advertising ID HEX
        if url.contains("[STREANN-ADVERTISING-ID-HEX]") {
            url = url.replacingOccurrences(of: "[STREANN-ADVERTISING-ID-HEX]", with: hexToString(from: ASIdentifierManager.shared().advertisingIdentifier.uuidString))
        }
        
        //Advertising ID MD5
        if url.contains("[STREANN-ADVERTISING-ID-MD5]") {
            url = url.replacingOccurrences(of: "[STREANN-ADVERTISING-ID-MD5]", with: MD5String(from: ASIdentifierManager.shared().advertisingIdentifier.uuidString))
        }
        
        //IDFA
        if url.contains("[STREANN-IDFA]") {
            url = url.replacingOccurrences(of: "[STREANN-IDFA]", with: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
        }
        
        //IDFA MD5
        if url.contains("[STREANN-IDFA-MD5]") {
            url = url.replacingOccurrences(of: "[STREANN-IDFA-MD5]", with: MD5String(from: ASIdentifierManager.shared().advertisingIdentifier.uuidString))
        }
        
        //IDFA HEX
        if url.contains("[STREANN-IDFA-HEX]") {
            url = url.replacingOccurrences(of: "[STREANN-IDFA-HEX]", with: hexToString(from: ASIdentifierManager.shared().advertisingIdentifier.uuidString))
        }
        
        //Latitude
        if url.contains("[STREANN-LOCATION-LAT]") {
            if let latitude = geoModel.latitude {
                url = url.replacingOccurrences(of: "[STREANN-LOCATION-LAT]", with: "\(latitude)")
            }
        }
        
        //Longitude
        if url.contains("[STREANN-LOCATION-LONG]") {
            if let longitude = geoModel.longitude {
                url = url.replacingOccurrences(of: "[STREANN-LOCATION-LONG]", with: "\(longitude)")
            }
        }
        
        //Country Code
        if url.contains("[STREANN-COUNTRY-ID]") {
            if let countryCode = geoModel.countryCode {
                url = url.replacingOccurrences(of: "[STREANN-COUNTRY-ID]", with: countryCode)
            }
        }
        
        //Do Not Track
        if url.contains("[STREANN-DO-NOT-TRACK]") {
            url = url.replacingOccurrences(of: "[STREANN-DO-NOT-TRACK]", with: ATTrackingManager.trackingAuthorizationStatus == .authorized ? "1" : "0")
        }
        
        //GDPR
        if url.contains("[STREANN-GDPR]") {
            url = url.replacingOccurrences(of:  "[STREANN-GDPR]", with: "0")
        }
        
        //GDPR consent
        if url.contains("[STREANN-GDPR-CONSENT]") {
            url = url.replacingOccurrences(of:  "[STREANN-GDPR-CONSENT]", with: "")
        }
        
        //User birth year
        if url.contains("[STREANN-USER-BIRTHYEAR]") {
            if let userBirthYear = Constants.UserInfo.userBirthYear {
                url = url.replacingOccurrences(of:  "[STREANN-USER-BIRTHYEAR]", with: "\(userBirthYear)")
            }else{
                url = url.replacingOccurrences(of:  "[STREANN-USER-BIRTHYEAR]", with: "")
            }
        }
        
        //User gender
        if url.contains("[STREANN-USER-GENDER]") {
            url = url.replacingOccurrences(of:  "[STREANN-USER-GENDER]", with: String(format:"%@", Constants.UserInfo.userGender.rawValue))
        }
        
        //Cachebuster
        if url.contains("[STREANN-CACHEBUSTER]") {
            let date = Date()
            url = url.replacingOccurrences(of: "[STREANN-CACHEBUSTER]", with: "\(Int64(date.timeIntervalSince1970 * 1000))")
        }
        
        //Volume
        if url.contains("[STREANN-VOLUME]") {
            url = url.replacingOccurrences(of:  "[STREANN-VOLUME]", with: "0")
        }
        
        
        //Privacy
        if adUrl.contains("[STREANN-US-PRIVACY]") {
            url = url.replacingOccurrences(of:  "[STREANN-US-PRIVACY]", with: String(format:"1---"))
        }
        
        return url
    }
}

//MARK:- InsideAdHelper functions
extension InsideAdHelper {
    private func getUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { userAgent,error in
            if error == nil && userAgent != nil {
                self.userAgent = userAgent as? String ?? ""
            }
        }
    }

    //Concert MD5String to String
    private func MD5String(from: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(from.utf8))

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    //Convert HEX to String
    private func hexToString(from text: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(0x)?([0-9A-Fa-f]{2})", options: .caseInsensitive)
        let textNS = text as NSString
        let matchesArray = regex.matches(in: textNS as String, options: [], range: NSMakeRange(0, textNS.length))
        let characters = matchesArray.map {
            Character(UnicodeScalar(UInt32(textNS.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        return String(characters)
    }

    //Get connection type
    private func getConnectionType() -> String {
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.google.com") else { return "NO INTERNET" }

        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)

        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        if isReachable {
            if isWWAN {
                let networkInfo = CTTelephonyNetworkInfo()
                let carrierType = networkInfo.serviceCurrentRadioAccessTechnology

                guard let carrierTypeName = carrierType?.first?.value else {
                    return "UNKNOWN"
                }

                switch carrierTypeName {
                case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
                    return "2G"
                case CTRadioAccessTechnologyLTE:
                    return "4G"
                default:
                    return "3G"
                }
            } else { return "WiFi" }
        } else { return "NO INTERNET" }
    }
}

//User gender selection required for the vast parameters
public enum UserGender: String {
    case male = "m"
    case female = "f"
    case unknown = "u"
}

//Check he status of the requested ad to handle the fallbacks
enum AdRequestStatus {
    case adRequested
    case fallbackRequested
}
