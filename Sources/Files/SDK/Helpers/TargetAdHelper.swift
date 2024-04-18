//
//  TargetAdHelper.swift
//  TestTheLibrary
//
//  Created by Igor Parnadjiev on 5.4.24.
//

import Foundation

protocol WeightedObjectProtocol {
    var weight: Int? { get }
}

class TargetManager {
    static let shared = TargetManager()
    
    // MARK: - Filter Campaigns by Content Targeting
    func filterCampaignsByContentTargeting(campaigns: [CampaignAppModel], targetingObject: TargetModel?) -> [CampaignAppModel] {

        guard let targetingFilters = targetingObject else {
            return campaigns
        }

        var activeCampaigns = [CampaignAppModel]()
        let contentId = targetingFilters.contentId
        let contentType = targetingFilters.contentType
        
        let seriesId = targetingFilters.seriesId
        let categoryIds = targetingFilters.categoryIds
        let contentProviderId = targetingFilters.contentProviderId

        for campaign in campaigns {
            for contentTarget in campaign.targeting ?? [] {
                guard let targetsList = contentTarget.targets else {
                    return []
                }

                if let contentId = contentId, let contentType = contentType, !contentId.isEmpty, !contentType.isEmpty {
                    //small letters in, big letters matching
                    if contentType == ContentType.vod.rawValue && targetsList.contains(where: { $0.type == ContentType.vod.rawValue && $0.ids?.contains(contentId) ?? false }) {
                        activeCampaigns.append(campaign)
                        break
                    }
                    
                    if contentType == ContentType.channel.rawValue && targetsList.contains(where: { $0.type == ContentType.channel.rawValue && $0.ids?.contains(contentId) ?? false }) {
                        activeCampaigns.append(campaign)
                        break
                    }
                    
                    if contentType == ContentType.radio.rawValue && targetsList.contains(where: { $0.type == ContentType.radio.rawValue && $0.ids?.contains(contentId) ?? false }) {
                        activeCampaigns.append(campaign)
                        break
                    }
                }
                
                if let seriesId = seriesId, !seriesId.isEmpty,
                    targetsList.contains(where: { $0.type == ContentType.series.rawValue && $0.ids?.contains(seriesId) ?? false }) {
                    activeCampaigns.append(campaign)
                    break
                }
                
                if !(categoryIds?.isEmpty ?? false) && targetsList.contains(where: { target in
                    return target.type == ContentType.category.rawValue && isCategoryIdContained(targetIds: target.ids ?? [], categoryIds: categoryIds ?? [])
                }) {
                    activeCampaigns.append(campaign)
                    break
                }


                if let contentProviderId = contentProviderId, !contentProviderId.isEmpty,
                    targetsList.contains(where: { $0.type == "CONTENT_PROVIDER" && $0.ids?.contains(contentProviderId) ?? false }) {
                    activeCampaigns.append(campaign)
                    break
                }
            }
        }
        
        func isCategoryIdContained(targetIds: [String], categoryIds: [String]) -> Bool {
            for categoryId in categoryIds {
                if targetIds.contains(categoryId) {
                    return true
                }
            }
            return false
        }


        // Filter campaigns without targeting if the content id is not contained in the campaigns targets
        if activeCampaigns.isEmpty {
            NSLog("no matches, find campaigns without targeting")
            activeCampaigns += campaigns.filter { $0.targeting?.isEmpty ?? false }
        }

        return activeCampaigns
    }
    
    // MARK: - Select Ad with Weight
    func selectObjectWithWeight<T: WeightedObjectProtocol>(objects: [T]) -> T? {
        guard !objects.isEmpty else {
            return nil
        }
        
        // Calculate total weight
        let totalWeight = objects.reduce(0) { $0 + ($1.weight ?? 0) }
        
        // Generate a random value between 0 and totalWeight
        let randomNumber = Int.random(in: 0..<totalWeight)
        
        // Iterate over the objects and find the selected one
        var sum = 0
        for object in objects {
            sum += object.weight ?? 0
            if sum > randomNumber {
                return object
            }
        }
        
        // This should never be reached, but if it does, return the last object
        return objects.last
    }
    
    func activeAdFromPlacement() -> InsideAd? {
        var allAdsFromPlacement = [InsideAd]()
        
        // List of all ads in all placements that belong to the campaign that match the location.
        InsideAdSdk.shared.activeCampaign?.placements?.forEach({ allAdsFromPlacement.append(contentsOf: $0.ads ?? []) })
        
        return selectObjectWithWeight(objects: allAdsFromPlacement)
    }
    
    func activePlacement() -> Placement? {
        // List of all ads in all placements that belong to the campaign that match the location.
        return InsideAdSdk.shared.activeCampaign?.placements?.findBy(adId: InsideAdSdk.shared.activeInsideAd?.id ?? "")
    }
}
