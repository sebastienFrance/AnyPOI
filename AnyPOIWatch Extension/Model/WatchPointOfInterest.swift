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

class WatchPointOfInterest : Equatable {
    static func == (lhs: WatchPointOfInterest, rhs: WatchPointOfInterest) -> Bool {
        if lhs.title == rhs.title && lhs.distance == rhs.distance {
            return true
        } else {
            return false
        }
    }
    
    
    private let theProps:[String:String]
    
    init(properties:[String:String]) {
        theProps = properties
    }
    
    var title:String? {
        if let remaining = theProps[CommonProps.debugRemainingComplicationTransferInfo], let urgentCounter = theProps[CommonProps.debugNotUrgentComplicationTransferInfo] {
            return  "(\(remaining)/\(urgentCounter)) \(theProps[CommonProps.POI.title]!)"
        } else {
            return  theProps[CommonProps.POI.title]  ?? "unknown"
        }
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
