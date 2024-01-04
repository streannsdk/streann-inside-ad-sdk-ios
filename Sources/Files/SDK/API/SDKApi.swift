//
//  SDKApi.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
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

    static func getCampaigns(countryCode: String, completionHandler: @escaping(_ campaignAppModel: [CampaignAppModel]?, _ error: Error?) -> Void) {
        let queryItems = [
            //URLQueryItem(name: "platform", value: "IOS"),
                          URLQueryItem(name: "country", value: countryCode)//,
                          //URLQueryItem(name: "resellerId", value: Constants.ResellerInfo.apiKey)
        ]
        var urlComps = URLComponents(string: Constants.ResellerInfo.baseUrl + "/v1/r/" + Constants.ResellerInfo.apiKey +  "/campaigns/IOS")!
        urlComps.queryItems = queryItems
        let url = urlComps.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("ApiToken \(Constants.ResellerInfo.apiToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil, response != nil else {
                print("getCampaign URLSession.shared.dataTask Error")
                completionHandler(nil, nil)
                return
            }
            do {
                let dataString = String(data: data, encoding: .utf8)
                print("getCampaign json \(dataString)")
                
                let campaignAppModel = try JSONDecoder.shared.decode([CampaignAppModel].self, from: data)
                completionHandler(campaignAppModel, nil)
            } catch {
                print(error)
                completionHandler(nil, error)
            }
        }
        task.resume()
    }
}
