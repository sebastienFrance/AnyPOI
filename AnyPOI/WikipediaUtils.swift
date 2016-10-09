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

    static func getExtractFromJSONResponse(JSONResponse:AnyObject) -> String {
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
    
    static func getMobileURLForPageId(pageId:Int) -> String {
        return "https://" + WikipediaLanguages.endPoint() + ".m.wikipedia.org/?curid=\(pageId)"
    }
    
    static func getDesktopURLForPageId(pageId:Int) -> String {
        return "https://" + WikipediaLanguages.endPoint() + ".wikipedia.org/?curid=\(pageId)"
    }

    //        Alamofire.request(.GET, "https://" + languageCode + ".wikipedia.org/w/api.php", parameters: ["action": "query", "list" : "geosearch", "gscoord" : "\(poi.coordinate.latitude)|\(poi.coordinate.longitude)", "gsradius" : "10000", "gslimit" : "10", "format" : "json"])
    static func getGeoSearchRequest(coordinate:CLLocationCoordinate2D,
        radius:Int = UserPreferences.sharedInstance.wikipediaNearByDistance,
        maxResults:Int = UserPreferences.sharedInstance.wikipediaMaxResults) -> Request {
        
        return Alamofire.request(.GET, getWikipediaAPI(), parameters: [
            "action": "query",
            "list" : "geosearch",
            "gscoord" : "\(coordinate.latitude)|\(coordinate.longitude)",
            "gsradius" : "\(radius)", "gslimit" : "\(maxResults)",
            "format" : "json"])
    }
    // Get page summary: /w/api.php?action=query&prop=extracts&format=json&exintro=&explaintext=&pageids=32937647
    static func getPageSummary(pageId:Int) -> Request {
        return Alamofire.request(.GET, getWikipediaAPI(), parameters: [
            "action": "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "pageids" : "\(pageId)",
            "format" : "json"])

    }
    
    // /w/api.php?action=query&prop=extracts&format=json&exintro=&explaintext=&generator=geosearch&ggscoord=37.786971%7C-122.399677&ggsradius=10000&ggslimit=10
    // followings by adding excontinue: /w/api.php?action=query&prop=extracts&format=json&exintro=&explaintext=&excontinue=1&generator=geosearch&ggscoord=37.786971%7C-122.399677&ggsradius=10000&ggslimit=10
    
    
    static func getGeoSearchPageSummaryRequest(coordinate:CLLocationCoordinate2D, radius:Int, maxResults:Int) -> Request {
        return Alamofire.request(.GET, getWikipediaAPI(), parameters: [
            "action": "query",
            "prop" : "extracts",
            "format" : "json",
            "exintro" : "",
            "explaintext" : "",
            "generator" : "geosearch",
            "ggscoord" : "\(coordinate.latitude)|\(coordinate.longitude)",
            "ggsradius": "\(radius)",
            "ggslimit" : "\(maxResults)"
            ])
    }
 
    static func getGeoSearchPageSummaryRequest(coordinate:CLLocationCoordinate2D, radius:Int, maxResults:Int, continueValue:String) -> Request {
        return Alamofire.request(.GET, getWikipediaAPI(), parameters: [
            "action": "query",
            "prop" : "extracts",
            "format" : "json",
            "exintro" : "",
            "explaintext" : "",
            "excontinue" : continueValue,
            "generator" : "geosearch",
            "ggscoord" : "\(coordinate.latitude)|\(coordinate.longitude)",
            "ggsradius": "\(radius)",
            "ggslimit" : "\(maxResults)"
            ])
    }

    static func getGeoSearchPageSummary(coordinate:CLLocationCoordinate2D, radius:Int, maxResults:Int) {
        getGeoSearchPageSummary(coordinate, radius: radius, maxResults: maxResults, continueValue: "")
    }
    
    
    static func getGeoSearchPageSummary(coordinate:CLLocationCoordinate2D, radius:Int, maxResults:Int, continueValue: String) {
        let mainRequest = getGeoSearchPageSummaryRequest(coordinate, radius: radius, maxResults: maxResults, continueValue:  continueValue)
        mainRequest.responseJSON { response in
      //      debugPrint(response)
            if let JSON = response.result.value {
                let response = JSON as! NSDictionary
                let query = response["query"] as! NSDictionary
                let pages = query["pages"] as! NSDictionary
                for currentPage in pages.allValues {
                    if let currentBlock = currentPage as? NSDictionary {
                        //print("currentBlock : \(currentBlock)")
                        if let extractValue = currentBlock["extract"] {
                            print("Found block with Extract with \(extractValue)")
                        }
                    }
                }
                let continueBlock = response["continue"] as? NSDictionary
                if let foundContinueBlock = continueBlock {
                    let continueValueNumber = foundContinueBlock["excontinue"] as! NSNumber
                    print("Continue value is: \(continueValueNumber)")
                    getGeoSearchPageSummary(coordinate, radius: radius, maxResults: maxResults, continueValue: "\(continueValueNumber)")
                } else {
                    return
                }
                //let values = pages.allValues[0] as! NSDictionary
                
            } else {
                return
            }
        }
    }
    
    
}
