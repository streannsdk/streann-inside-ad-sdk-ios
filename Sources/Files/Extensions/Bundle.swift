//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 25.9.23.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var appName: String?{
        return infoDictionary?["CFBundleDisplayName"] as? String
    }
}
