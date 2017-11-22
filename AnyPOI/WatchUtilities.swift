//
//  File.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 04/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation

class WatchUtilities {
    
    /// Build a property list that contains POIs around current location
    /// Property list contains an error code when the Location is not Authorized or when the current location is unavailable
    static func getPoisAround(maxRadius:Double, maxPOIResults:Int) -> (propList:[String:Any], pois:[PointOfInterest]) {
        var result = [String:Any]()
        var pois = [PointOfInterest]()
        
        if LocationManager.sharedInstance.isLocationAuthorized() {
            
            if let centerLocation = LocationManager.sharedInstance.locationManager?.location {
                NSLog("\(#function) found location \(centerLocation.coordinate.latitude) / \(centerLocation.coordinate.longitude)")
                
                pois = PoiBoundingBox.getPoiAroundCurrentLocation(centerLocation, radius: maxRadius, maxResult: maxPOIResults)
                let poiArray = poisToArray(pois: pois, centerLocation: centerLocation)
                
                result[CommonProps.messageStatus] = CommonProps.MessageStatusCode.ok.rawValue
                result[CommonProps.listOfPOIs] = poiArray
                NSLog("\(#function) send \(poiArray.count) POI")
            } else {
                NSLog("\(#function) Cannot get CLLocation")
                result[CommonProps.messageStatus] = CommonProps.MessageStatusCode.erroriPhoneLocationNotAvailable.rawValue
            }
        } else {
            NSLog("\(#function) Location is not authorized")
            result[CommonProps.messageStatus] = CommonProps.MessageStatusCode.erroriPhoneLocationNotAuthorized.rawValue
        }
        
        return (result, pois)
    }
    
    static func getPoisAroundAsArray(maxRadius:Double, maxPOIResults:Int) -> [[String:String]] {
        
        if LocationManager.sharedInstance.isLocationAuthorized() {
            
            if let center = LocationManager.sharedInstance.locationManager?.location {
                let poisAround = PoiBoundingBox.getPoiAroundCurrentLocation(center, radius: maxRadius, maxResult: maxPOIResults)
                return poisToArray(pois: poisAround, centerLocation: center)
            } else {
                NSLog("\(#function) Cannot get CLLocation")
            }
        } else {
            NSLog("\(#function) Location is not authorized")
        }
        
        return [[String:String]]()
    }
    
    private static func poisToArray(pois:[PointOfInterest], centerLocation:CLLocation) -> [[String:String]] {
        // convert POIs to properties and add them in an Array
        let poiArray : [[String:String]] = pois.map() {
            var poiProps = $0.props
            
            poiProps[CommonProps.POI.distance] = "\($0.distanceFrom(location: centerLocation))"
            return poiProps
        }
        return poiArray
    }
}
