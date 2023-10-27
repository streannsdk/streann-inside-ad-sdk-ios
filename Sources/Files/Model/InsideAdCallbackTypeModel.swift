//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 27.10.23.
//

import Foundation

public enum InsideAdCallbackType: Equatable, CaseIterable {
    case AD_BREAK_READY
    case AD_BREAK_FETCH_ERROR
    case AD_BREAK_ENDED
    case AD_BREAK_STARTED
    case AD_PERIOD_ENDED
    case AD_PERIOD_STARTED
    case ALL_ADS_COMPLETED
    case CLICKED
    case COMPLETE
    case CUEPOINTS_CHANGED
    case ICON_FALLBACK_IMAGE_CLOSED
    case ICON_TAPPED
    case FIRST_QUARTILE
    case LOADED
    case LOG
    case MIDPOINT
    case PAUSE
    case RESUME
    case SKIPPED
    case STARTED
    case STREAM_LOADED
    case STREAM_STARTED
    case TAPPED
    case THIRD_QUARTILE
    case UNKNOWN
    case IMAAdError(String)
    
    public static var allCases: [InsideAdCallbackType] {
        return [
            .AD_BREAK_ENDED,
            .AD_BREAK_FETCH_ERROR,
            .AD_BREAK_ENDED,
            .AD_BREAK_STARTED,
            .AD_PERIOD_ENDED,
            .AD_PERIOD_STARTED,
            .ALL_ADS_COMPLETED,
            .CLICKED,
            .COMPLETE,
            .CUEPOINTS_CHANGED,
            .ICON_FALLBACK_IMAGE_CLOSED,
            .ICON_TAPPED,
            .FIRST_QUARTILE,
            .LOADED,
            .LOG,
            .MIDPOINT,
            .PAUSE,
            .RESUME,
            .SKIPPED,
            .STARTED,
            .STREAM_LOADED,
            .STREAM_STARTED,
            .TAPPED,
            .THIRD_QUARTILE,
            .UNKNOWN,
            .IMAAdError("")
        ]
    }
}


