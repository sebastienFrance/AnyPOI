//
//  WikipediaUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 25/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import Alamofire
import MapKit

class WikipediaUtils {
    // Get all Wikipedia sites for all languages (give URL for each language) https://commons.wikimedia.org/w/api.php?action=sitematrix&smtype=language
    // Get full page content in HTML: http://en.wikipedia.org/?curid=18630637
    // Get URL for image of a given page with a max size: /w/api.php?action=query&prop=pageimages&format=json&piprop=thumbnail&pithumbsize=20&pageids=32937647
    // Get Following URL if there're severals https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=thumbnail&pageids=32937647&generator=images&gimlimit=10&gimdir=ascending&picontinue=-2

    static func getExtractFromJSONResponse(_ JSONResponse:Any) -> String {
        let response = JSONResponse as! NSDictionary
        let query = response["query"] as! NSDictionary
        let pages = query["pages"] as! NSDictionary
        let values = pages.allValues[0] as! NSDictionary
        
        let extract = values["extract"] as! String
        
        return extract
    }

    static func getWikipediaAPI() -> String {
        return "https://" + WikipediaLanguages.endPoint() + ".wikipedia.org/w/api.php"
    }
    
    static func getMobileURLForPageId(_ pageId:Int) -> String {
        return "https://" + WikipediaLanguages.endPoint() + ".m.wikipedia.org/?curid=\(pageId)"
    }
    
    static func getDesktopURLForPageId(_ pageId:Int) -> String {
        return "https://" + WikipediaLanguages.endPoint() + ".wikipedia.org/?curid=\(pageId)"
    }

    static func getGeoSearchRequest(_ coordinate:CLLocationCoordinate2D,
        radius:Int = UserPreferences.sharedInstance.wikipediaNearByDistance,
        maxResults:Int = UserPreferences.sharedInstance.wikipediaMaxResults) -> DataRequest {
        
        return Alamofire.request(getWikipediaAPI(), parameters: [
            "action": "query",
            "list" : "geosearch",
            "gscoord" : "\(coordinate.latitude)|\(coordinate.longitude)",
            "gsradius" : "\(radius)", "gslimit" : "\(maxResults)",
            "format" : "json"])
    }
    // Get page summary: /w/api.php?action=query&prop=extracts&format=json&exintro=&explaintext=&pageids=32937647
    static func getPageSummary(_ pageId:Int) -> DataRequest {
        return Alamofire.request(getWikipediaAPI(), parameters: [
            "action": "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "pageids" : "\(pageId)",
            "format" : "json"])

    }
    
    
    
}
