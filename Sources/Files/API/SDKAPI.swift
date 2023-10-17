//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 22.9.23.
//

import Foundation

class SDKAPI: NSObject {
    //Get GeoIpUrl
    static func getGeoIpUrl(completionHandler: @escaping(_ getGeoIpUrl: GeoIpUrl?, _ error: Error?) -> Void) {
        guard let url = URL(string: Constants.ResellerInfo.baseUrl + "/v1/geo-ip-config") else {
            completionHandler(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            let decoder = JSONDecoder()
            guard let data = data, let geoModel = try? decoder.decode(GeoIpUrl.self, from: data) else {
                completionHandler(nil, error)
                return
            }
            completionHandler(geoModel, nil)
        }
        task.resume()
    }
    
    //Get GeoModel
    static func getGeoIp(fromUrl: String, completionHandler: @escaping(_ geoModel: GeoIp?, _ error: Error?) -> Void) {
        guard let url = URL(string: fromUrl) else {
            completionHandler(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            let decoder = JSONDecoder()
            guard let data = data, let geoModel = try? decoder.decode(GeoIp.self, from: data) else {
                completionHandler(nil, error)
                return
            }
            completionHandler(geoModel, nil)
        }
        task.resume()
    }
    
    //Get Campaign Model
    static func getCampaign(countryCode: String, screen: String, completionHandler: @escaping(_ campaignAppModel: CampaignAppModel?, _ error: Error?) -> Void) {
        let queryItems = [URLQueryItem(name: "platform", value: "IOS"),
                          URLQueryItem(name: "country", value: countryCode),
                          URLQueryItem(name: "screen", value: screen),
                          URLQueryItem(name: "r", value: Constants.ResellerInfo.apiKey)]
        var urlComps = URLComponents(string: Constants.ResellerInfo.baseUrl + "/v1/campaigns/app")!
        urlComps.queryItems = queryItems
        let url = urlComps.url!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil, response != nil else {
                print("getCampaign URLSession.shared.dataTask Error")
                completionHandler(nil, nil)
                return
            }
            do {
                let campaignAppModel = try JSONDecoder().decode(CampaignAppModel.self, from: data)
                completionHandler(campaignAppModel, nil)
            } catch {
                print(Logger.log(error.localizedDescription))
                completionHandler(nil, error)
            }
        }
        task.resume()
    }
}
