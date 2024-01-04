//
//  Extensions.swift
//  TestTheLibrary
//
//  Created by Fani on 28.12.23.
//

import Foundation

extension DateFormatter {
    static let cc_dateFormater_server: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }()
    
    static let cc_dateFormater_server_short: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    static let cc_dateFormater_local_time: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()
}

extension Date {
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
    
    func secondsFromBeginningOfTheDay() -> TimeInterval {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: self)
        let dateSeconds = dateComponents.hour! * 3600 + dateComponents.minute! * 60 + dateComponents.second!
        return TimeInterval(dateSeconds)
    }
}

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategyFormatters = [DateFormatter.cc_dateFormater_server, DateFormatter.cc_dateFormater_server_short, DateFormatter.cc_dateFormater_local_time]
        return decoder
    }()
    
    var dateDecodingStrategyFormatters: [DateFormatter]? {
        @available(*, unavailable, message: "This variable is meant to be set only")
        get { return nil }
        set {
            guard let formatters = newValue else { return }
            self.dateDecodingStrategy = .custom { decoder in

                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                print("Cannot decode date string \(dateString)")
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
        }
    }
}

extension Bundle {
    func decode<T: Codable>(_ file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else{
            fatalError("Failed to locate \(file) in bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else{
            fatalError("Failed to load \(file) in bundle")
        }
        
        let decoder = JSONDecoder.shared
        
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(file) in bundle")
        }
        
        return loaded
    }
}
