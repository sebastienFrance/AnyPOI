//
//  WatchPointOfInterest.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit

class WatchPointOfInterest {
    
    private let theProps:[String:String]
    
    init(properties:[String:String]) {
        theProps = properties
    }
    
    var title:String? {
        var title = "unknown"
        if let poiTitle = theProps[CommonProps.POI.title] {
            title = "\(poiTitle)\n(\(distance!))"
        }
        
        return title
    }
    
    var distance:String? {
        if let distanceString = theProps[CommonProps.POI.distance], let distance = CLLocationDistance(distanceString) {
            return "\(MKDistanceFormatter().string(fromDistance: distance))"
        } else {
            return "?"
        }
    }
    
    var category: CategoryUtils.Category? {
        return CommonProps.categoryFrom(props: theProps)
    }
    
    var color: UIColor? {
        if let color = CommonProps.poiColorFrom(props: theProps) {
            return color
        } else {
            return UIColor.white
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        if let latitudeString = theProps[CommonProps.POI.latitude],
            let longitudeString = theProps[CommonProps.POI.longitude],
            let latitude = CLLocationDegrees(latitudeString),
            let longitude = CLLocationDegrees(longitudeString) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            return nil
        }
    }
    
    
}