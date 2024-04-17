//
//  EventTypeHandler.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 14.2.24.
//

import Foundation
import GoogleInteractiveMediaAds

struct EventTypeHandler {
    static func convertEventType(type: IMAAdEventType) -> InsideAdCallbackType {
        switch type {
        case .ALL_ADS_COMPLETED: return InsideAdCallbackType.ALL_ADS_COMPLETED
        case .CLICKED: return InsideAdCallbackType.CLICKED
        case .COMPLETE: return InsideAdCallbackType.COMPLETE
        case .ICON_FALLBACK_IMAGE_CLOSED: return InsideAdCallbackType.ICON_FALLBACK_IMAGE_CLOSED
        case .ICON_TAPPED: return InsideAdCallbackType.ICON_TAPPED
        case .LOADED: return InsideAdCallbackType.LOADED
        case .PAUSE: return InsideAdCallbackType.PAUSE
        case .RESUME: return InsideAdCallbackType.RESUME
        case .STARTED: return InsideAdCallbackType.STARTED
        case .TAPPED: return InsideAdCallbackType.TAPPED
            
        default:
            return InsideAdCallbackType.UNKNOWN
        }
    }
    
    static func convertErrorType(message: String) -> InsideAdCallbackType{
        let errorType = InsideAdCallbackType.IMAAdError(message)
        NotificationCenter.post(name: .AdsContentView_setZeroSize)
        return errorType
    }
}
