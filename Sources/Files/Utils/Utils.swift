//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import UIKit

class Utils: NSObject {
    static func getCurrentDeviceName() -> String {
        return UIDevice.current.name
    }
    
    static func getCurrentOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func getDeviceType() -> String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
    }
    
    static func getAppVersionNumber() -> String {
        return Bundle.main.buildVersionNumber ?? ""
    }
    
    static func getReleaseVersionNumber() -> String {
        return Bundle.main.releaseVersionNumber ?? ""
    }
    
    static func getAppIdentifier() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }
}
