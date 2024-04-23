//
//  OtherFile.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 27.9.23.
//

import Foundation
import UIKit
import CoreLocation



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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        
        switch status {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        default: return "unknown"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        print(#function, statusString)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        print(#function, location)
    }
}
