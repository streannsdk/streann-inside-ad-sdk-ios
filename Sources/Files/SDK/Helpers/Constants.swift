//
//  Constants.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import Foundation
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
        static var intervalInMinutes: Double?
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
        return ("STREANN-InsideAdSDK LOG: \(string)")
    }
}

public enum InsideAdCallbackType: Equatable, CaseIterable {
    case ALL_ADS_COMPLETED
    case CLICKED
    case COMPLETE
    case ICON_FALLBACK_IMAGE_CLOSED
    case ICON_TAPPED
    case LOADED
    case PAUSE
    case RESUME
    case STARTED
    case TAPPED
    case UNKNOWN
    case IMAAdError(String)
    
    public static var allCases: [InsideAdCallbackType] {
        return [
            .ALL_ADS_COMPLETED,
            .CLICKED,
            .COMPLETE,
            .ICON_FALLBACK_IMAGE_CLOSED,
            .ICON_TAPPED,
            .LOADED,
            .PAUSE,
            .RESUME,
            .STARTED,
            .TAPPED,
            .UNKNOWN,
            .IMAAdError("")
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
