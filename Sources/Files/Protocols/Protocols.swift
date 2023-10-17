//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 26.9.23.
//

import Foundation

//Send the InsideAdCallback events
protocol InsideAdCallbackDelegate {
  func insideAdCallbackReceived(data: String)
}
