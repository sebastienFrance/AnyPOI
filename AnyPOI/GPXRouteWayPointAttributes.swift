//
//  RouteWayPointAttributes.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 28/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

struct GPXRouteWayPointAtttributes {
    var poiName = ""
    var routeWptAttributes:[String : String]? = nil
    var wayPointAttributes:[String : String]? = nil
    
    var transportType: MKDirectionsTransportType {
        get {
            if let wayPointAttr = wayPointAttributes,
                let transportTypeString = wayPointAttr[XSD.wayPointTransportTypeAttr],
                let transportTypeInt = UInt(transportTypeString) {
                return MKDirectionsTransportType(rawValue: transportTypeInt)
            } else {
                return MKDirectionsTransportType.automobile
            }
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        get {
            if let wptAttr = routeWptAttributes,
                let latitudeString = wptAttr[XSD.wptLatitudeAttr],
                let longitudeString = wptAttr[XSD.wptLongitudeAttr],
                let latitude = Double(latitudeString),
                let longitude = Double(longitudeString){
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                return nil
            }
        }
    }
    
    var poiInternalURL: URL? {
        if let wayPointAttr = wayPointAttributes,
            let poiInternalUrl = wayPointAttr[XSD.wayPointPoiInternalUrlAttr] {
            return URL(string: poiInternalUrl)
        } else {
            return nil
        }
    }
    
    var distance: Double {
        get {
            if let wayPointAttr = wayPointAttributes,
                let distanceString = wayPointAttr[XSD.wayPointDistanceAttr],
                let theDistance = Double(distanceString) {
                return theDistance
            } else {
                return Double.nan
            }
        }
    }
    
    var duration: Double {
        get {
            if let wayPointAttr = wayPointAttributes,
                let durationString = wayPointAttr[XSD.wayPointDurationAttr],
                let theDuration = Double(durationString) {
                return theDuration
            } else {
                return Double.nan
            }
        }
    }

}
