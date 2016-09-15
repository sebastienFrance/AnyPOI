//
//  PoiBoundingBox.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 30/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class PoiBoundingBox {
    // MARK: Utilities
    static func getPoiAroundCurrentLocation(location:CLLocation, radius:Double, maxResult:Int) -> [PointOfInterest] {
        let geoLocation = GeoLocation.fromDegrees(location.coordinate.latitude, longitude: location.coordinate.longitude)
        do {
            
            let boundingBox = try geoLocation?.boundingCoordinates(radius)
            
            let southWest = CLLocationCoordinate2DMake(boundingBox![0].getLatitudeInDegree()!, boundingBox![0].getLongitudeInDegree()!)
            let northEast = CLLocationCoordinate2DMake(boundingBox![1].getLatitudeInDegree()!, boundingBox![1].getLongitudeInDegree()!)
            
            var pois = PoiBoundingBox.getPOIInBoundingBox(southWest, northEast: northEast)
            
            // Extract from the result the 3 POIs that are neareast from the current position
            pois = pois.sort() { firstPoi, secondPoi in
                let firstPoiLocation = CLLocation(latitude: firstPoi.poiLatitude, longitude: firstPoi.poiLongitude)
                let secondPoiLocation = CLLocation(latitude: secondPoi.poiLatitude, longitude: secondPoi.poiLongitude)
                
                if location.distanceFromLocation(firstPoiLocation) <= location.distanceFromLocation(secondPoiLocation) {
                    return true
                } else {
                    return false
                }
            }
            
            if pois.count > maxResult {
                return Array(pois[0...maxResult - 1])
            } else {
                return pois
            }
            
        } catch let error as NSError {
            print("\(#function) error with \(error.localizedDescription)")
            return [PointOfInterest]()
        }
        
    }
    
    private static func getPOIInBoundingBox(southWest:CLLocationCoordinate2D, northEast:CLLocationCoordinate2D) -> [PointOfInterest] {
        let fetchRequest = NSFetchRequest(entityName: "PointOfInterest")
        
        fetchRequest.predicate = NSPredicate(format: "poiLatitude >= %f AND poiLongitude >= %f AND poiLatitude <= %f AND poiLongitude <= %f", southWest.latitude, southWest.longitude, northEast.latitude, northEast.longitude)
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try DatabaseAccess.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
        } catch let error as NSError {
            print("\(#function) could not be fetched \(error), \(error.userInfo)")
            return []
        }
    }
}