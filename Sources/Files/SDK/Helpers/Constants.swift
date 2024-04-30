//
//  Constants.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import UIKit

struct Constants {
    struct DeviceInfo {
        static let manufacturer = "Apple"
        static let OS = "iOS"
        static let deviceType = UIDevice.current.userInterfaceIdiom == .phone ? "phone" : "tablet"
    }
    
    struct ResellerInfo {
        static var baseUrl = ""
        static var apiKey = ""
        static var apiToken = ""
        static var unitId = ""
        static var siteUrl = ""
        static var storeUrl = ""
        static var descriptionUrl = ""
        static var appDomain = ""
        static var isAdMuted: Bool = false
    }
    
    struct UserInfo {
        static var userBirthYear: Int64? = 0
        static var userGender: UserGender = .unknown
    }
    
    struct SystemImage {
        static let speakerFill = "speaker.fill"
        static let speakerSlashFill = "speaker.slash.fill"
        static let speakerWaveTwoFill = "speaker.wave.2.fill"
        static let xMarkCircleFill = "xmark.circle.fill"
    }
}

struct Logger {
    static func log(_ string: String) -> String {
        return ("InsideAdSDK LOG: \(string)")
    }
    static func logVast(_ string: String) -> String {
        return ("InsideAdSDK LOG Vast: \(string)")
    }
}

public enum InsideAdCallbackType: Equatable, CaseIterable {
    case UNKNOWN
    case STARTED
    case ALL_ADS_COMPLETED
    case AD_VIEW_DISAPPEARED
    case VOLUME_CHANGED(Int)
    case TRIGGER_FALLBACK
    case ON_ERROR(String)
    
    public static var allCases: [InsideAdCallbackType] {
        return [
            .UNKNOWN,
            .STARTED,
            .ALL_ADS_COMPLETED,
            .AD_VIEW_DISAPPEARED,
            .VOLUME_CHANGED(Constants.ResellerInfo.isAdMuted ? 0 : 1),
            .TRIGGER_FALLBACK,
            .ON_ERROR("")
        ]
    }
}

enum InsideAdScreenLocations: String {
    case splash
    case videoPlayer
    case reels
    
    var rawValue : String {
        switch self {
        case .splash: return "Splash"
        case .videoPlayer: return "Video Player"
        case .reels: return "Reels"
        }
    }
}

enum ContentType: String {
    case channel
    case radio
    case vod
    case category
    case series
    case contentProvider
}

