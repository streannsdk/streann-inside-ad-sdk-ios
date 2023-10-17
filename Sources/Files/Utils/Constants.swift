//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 27.9.23.
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
      static var siteUrl = ""
      static var storeUrl = ""
      static var descriptionUrl = ""
      static var appDomain = ""
    }
    
    struct UserInfo {
        static var userBirthYear: Int64? = 0
        static var userGender: UserGender = .unknown
    }
}
