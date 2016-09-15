//
//  NavigationURL.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 30/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

class NavigationURL {
    
    private static let baseURL = "AnyPOI"
    
    private struct Parameters {
        static let baseURL = "AnyPOI"
        static let action = "action"
        static let poiId = "poiId"
    }
    
    private struct Actions {
        static let showPoiOnMap = "showPoiOnMap"
    }
    
    private var isValidURL = false
    
    private var parameters = [String:String]()
    
    // Convert URL parameters into a simple dictionary
    init(openURL:NSURL) {
        if let query = openURL.query {
            let parameters = query.componentsSeparatedByString("&")
            for currentParameter in parameters {
                let paramNameValue = currentParameter.componentsSeparatedByString("=")
                if paramNameValue.count != 2 {
                    break
                } else {
                    self.parameters[paramNameValue[0]] = paramNameValue[1]
                }
            }
            isValidURL = true
        }
    }
    
    func getPoi() -> String? {
        if !isValidURL {
            return nil
        }
        
        return parameters[Parameters.poiId]
    }
    
    

    
    static func showPoiOnMapURL(poi:PointOfInterest) -> NSURL? {
        
        let params = urlParameters([Parameters.action : Actions.showPoiOnMap,
                                    Parameters.poiId  : poi.objectID.URIRepresentation().absoluteString])
        
        print("URL: \(params)")
        
        return NSURL(string: "\(baseURL)://?\(params)")
    }
    
    private static func urlParameters(paramValues:[String:String]) -> String {
        var allParameters = ""
        for (param, value) in paramValues {
            if !allParameters.isEmpty {
                allParameters = allParameters + "&"
            }
            allParameters = allParameters + "\(param)=\(value)"
        }
        
        return allParameters
    }
}