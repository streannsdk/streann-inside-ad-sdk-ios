//
//  AdsNotifications.swift
//  TestTheLibrary
//
//  Created by Fani on 27.12.23.
//

import Foundation

import Foundation

extension NSNotification.Name {
    static let AdsContentView_restoreSize = Notification.Name("AdsContentView_restoreSize")
}

extension NotificationCenter{
    static func post(name: NSNotification.Name){
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    static func post(name: NSNotification.Name, data:[String:Any]){
        NotificationCenter.default.post(name: name, object: nil, userInfo: data)
    }
}
