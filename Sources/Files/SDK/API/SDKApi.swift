//
//  SDKApi.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import Foundation
import Alamofire

class SDKAPI {
    
    // Get GeoIpUrl
    static func getGeoIpUrl(completionHandler: @escaping (_ geoIpUrl: GeoIpUrl?, _ error: Error?) -> Void) {
        let urlString = Constants.ResellerInfo.baseUrl + "/v1/geo-ip-config"
        
        AF.request(urlString).responseDecodable(of: GeoIpUrl.self) { response in
            switch response.result {
            case .success(let geoIpUrl):
                completionHandler(geoIpUrl, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }

    // Get GeoIp
    static func getGeoIp(fromUrl: String, completionHandler: @escaping (_ geoModel: GeoIp?, _ error: Error?) -> Void) {
        AF.request(fromUrl).responseDecodable(of: GeoIp.self) { response in
            switch response.result {
            case .success(let geoModel):
                completionHandler(geoModel, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }

    // Get Campaigns
    static func getCampaigns(countryCode: String, completionHandler: @escaping (_ campaignAppModel: [CampaignAppModel]?, _ error: Error?) -> Void) {
        var urlComponents = URLComponents(string: Constants.ResellerInfo.baseUrl + "/v1/r/\(Constants.ResellerInfo.apiKey)/campaigns/IOS")!
        urlComponents.queryItems = [
            URLQueryItem(name: "country", value: countryCode)
        ]
        
        guard let url = urlComponents.url else {
            completionHandler(nil, nil)
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "ApiToken \(Constants.ResellerInfo.apiToken)"
        ]
        
        AF.request(url, method: .get, headers: headers).responseDecodable(of: [CampaignAppModel].self, decoder: {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()) { response in
            switch response.result {
            case .success(let campaignModels):
                completionHandler(campaignModels, nil)
            case .failure(let error):
                print("getCampaign error: \(error)")
                completionHandler(nil, error)
            }
        }
    }
}
