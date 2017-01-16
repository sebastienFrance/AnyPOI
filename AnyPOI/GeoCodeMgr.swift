//
//  GeoCodeMgr.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 27/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation

// Warning: This class is not used due to restriction on number of Geocoding request
class GeoCodeMgr {
    
    // Initialize the Singleton
    class var sharedInstance: GeoCodeMgr {
        struct Singleton {
            static let instance = GeoCodeMgr()
        }
        return Singleton.instance
    }
    
    fileprivate let geoCoder = CLGeocoder()
    fileprivate var poisWithoutPlacemark = Set<PointOfInterest>()
    
    func getPlacemark(poi:PointOfInterest) {
        guard !geoCoder.isGeocoding else { return }
        
        let location = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            if let errorReverseGeocode = error {
                print("Reverse geocoder failed with error" + errorReverseGeocode.localizedDescription)
                switch errorReverseGeocode {
                case CLError.network:
                    print("Warning error because too many requests! (network error)")

                default:
                    break
                }
                
                
                return
            }
            
            if let placemarksResults = placemarks {
                if placemarksResults.count > 0 {
                    print("Resolved")
                    poi.initializeWith(placemark:placemarksResults[0])
                    POIDataManager.sharedInstance.updatePOI(poi)
                    POIDataManager.sharedInstance.commitDatabase()
                    
                } else {
                    print("Empty data received")
                }
                
            } else {
                print("No received data")
            }
        })
    }
}
