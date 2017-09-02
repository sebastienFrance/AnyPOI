//
//  WikipediaRequest.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 29/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation

protocol WikipediaRequestDelegate: class {
    func wikipediaLoadingDidFinished(_ wikipedias:[Wikipedia])
    func wikipediaLoadingDidFailed()
}


class WikipediaRequest {
    
    fileprivate(set) var isWikipediaLoading = false
    
    fileprivate weak var delegate:WikipediaRequestDelegate?
    
    init(delegate:WikipediaRequestDelegate) {
        self.delegate = delegate
    }
    
    func searchAround(_ center:CLLocationCoordinate2D) {
        
        isWikipediaLoading = true
        
        // Search all Wikipedias articles for the POI coordinates
        let request = WikipediaUtils.getGeoSearchRequest(center)

        request.responseJSON { response in
            if let error = response.result.error {
                NSLog("\(#function) - \(error.localizedDescription)")
                self.delegate?.wikipediaLoadingDidFailed()
            }
            
            var wikipedias = [Wikipedia]()
            
            if let JSON = response.result.value {
                let response = JSON as! NSDictionary
                
                if response["query"] != nil {
                    let query = response["query"] as! NSDictionary
                    let geosearch = query["geosearch"] as! Array<Dictionary<String, AnyObject>>
                    
                    if geosearch.count > 0 {
                        var summaryCounter = geosearch.count
                        
                        for currentSearch in geosearch {
                            
                            let pageId = currentSearch[Wikipedia.ArticleCste.pageId] as! NSNumber
                            
                            WikipediaUtils.getPageSummary(pageId.intValue).responseJSON { response in
                                summaryCounter -= 1
                                if let JSON = response.result.value {
                                    let wikipedia = Wikipedia(initialValues:currentSearch)
                                    wikipedias.append(wikipedia)
                                    wikipedia.extract = WikipediaUtils.getExtractFromJSONResponse(JSON)
                                }
                                
                                if summaryCounter == 0 {
                                    self.isWikipediaLoading = false
                                    
                                    // Sort by distance
                                    let locationPoi = CLLocation(latitude: center.latitude, longitude: center.longitude)
                                    wikipedias.sort() { first, second in
                                        let locationFirst = CLLocation(latitude: first.coordinates.latitude, longitude: first.coordinates.longitude)
                                        let locationSecond = CLLocation(latitude: second.coordinates.latitude, longitude: second.coordinates.longitude)
                                        
                                        if locationPoi.distance(from: locationFirst) > locationPoi.distance(from: locationSecond) {
                                            return false
                                        } else {
                                            return true
                                        }
                                    }
                                    self.delegate?.wikipediaLoadingDidFinished(wikipedias)
                                }
                            }
                        }
                    } else {
                        // No page found -> Stop the loading and warn with a notification
                        self.isWikipediaLoading = false
                        NSLog("\(#function) wikipedia not found!!!")
                        self.delegate?.wikipediaLoadingDidFinished(wikipedias)
                    }
                } else {
                    NSLog("\(#function) - error query is missing in the response")
                    self.delegate?.wikipediaLoadingDidFailed()
                }
            }
        }
    }

}
