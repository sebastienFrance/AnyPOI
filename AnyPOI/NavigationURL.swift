//
//  NavigationURL.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 30/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

class NavigationURL {
    
    fileprivate static let baseURL = "AnyPOI"
    
    fileprivate struct Parameters {
        static let baseURL = "AnyPOI"
        static let action = "action"
        static let poiId = "poiId"
    }
    
    fileprivate struct Actions {
        static let showPoiOnMap = "showPoiOnMap"
    }
    
    fileprivate var isValidURL = false
    
    fileprivate var parameters = [String:String]()
    
    // Convert URL parameters into a simple dictionary
    init(openURL:URL) {
        if let query = openURL.query {
            let parameters = query.components(separatedBy: "&")
            for currentParameter in parameters {
                let paramNameValue = currentParameter.components(separatedBy: "=")
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
    
    

    
    static func showPoiOnMapURL(_ poi:PointOfInterest) -> URL? {
        
        let poiURI = poi.objectID.uriRepresentation().absoluteString
        let params = urlParameters([Parameters.action : Actions.showPoiOnMap,
                                    Parameters.poiId  : poiURI])
        
        return URL(string: "\(baseURL)://?\(params)")
    }
    

    fileprivate static func urlParameters(_ paramValues:[String:String]) -> String {
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
