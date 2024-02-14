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
        case .AD_BREAK_READY: return InsideAdCallbackType.AD_BREAK_READY
        case .AD_BREAK_FETCH_ERROR: return InsideAdCallbackType.AD_BREAK_FETCH_ERROR
        case .AD_BREAK_ENDED: return InsideAdCallbackType.AD_BREAK_ENDED
        case .AD_BREAK_STARTED: return InsideAdCallbackType.AD_BREAK_STARTED
        case .AD_PERIOD_ENDED: return InsideAdCallbackType.AD_PERIOD_ENDED
        case .AD_PERIOD_STARTED: return InsideAdCallbackType.AD_PERIOD_STARTED
        case .ALL_ADS_COMPLETED: return InsideAdCallbackType.ALL_ADS_COMPLETED
        case .CLICKED: return InsideAdCallbackType.CLICKED
        case .COMPLETE: return InsideAdCallbackType.COMPLETE
        case .CUEPOINTS_CHANGED: return InsideAdCallbackType.CUEPOINTS_CHANGED
        case .ICON_FALLBACK_IMAGE_CLOSED: return InsideAdCallbackType.ICON_FALLBACK_IMAGE_CLOSED
        case .ICON_TAPPED: return InsideAdCallbackType.ICON_TAPPED
        case .FIRST_QUARTILE: return InsideAdCallbackType.FIRST_QUARTILE
        case .LOADED: return InsideAdCallbackType.LOADED
        case .LOG: return InsideAdCallbackType.LOG
        case .MIDPOINT: return InsideAdCallbackType.MIDPOINT
        case .PAUSE: return InsideAdCallbackType.PAUSE
        case .RESUME: return InsideAdCallbackType.RESUME
        case .SKIPPED: return InsideAdCallbackType.SKIPPED
        case .STARTED: return InsideAdCallbackType.STARTED
        case .STREAM_LOADED: return InsideAdCallbackType.STREAM_LOADED
        case .STREAM_STARTED: return InsideAdCallbackType.STREAM_STARTED
        case .TAPPED: return InsideAdCallbackType.TAPPED
        case .THIRD_QUARTILE: return InsideAdCallbackType.THIRD_QUARTILE
            
        @unknown default:
            return InsideAdCallbackType.UNKNOWN
        }
    }
    
    static func convertErrorType(message: String) -> InsideAdCallbackType{
        let errorType = InsideAdCallbackType.IMAAdError(message)
        NotificationCenter.post(name: .AdsContentView_setZeroSize)
        return errorType
    }
}
