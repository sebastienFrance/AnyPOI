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
    
    fileprivate static let wayPointTransportTypeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.transportType
    fileprivate static let wptLatitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.latitude
    fileprivate static let wptLongitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.longitude
    
    fileprivate static let wayPointPoiInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.poiInternalUrl
    
    var transportType: MKDirectionsTransportType {
        get {
            if let wayPointAttr = wayPointAttributes,
                let transportTypeString = wayPointAttr[GPXRouteWayPointAtttributes.wayPointTransportTypeAttr],
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
                let latitudeString = wptAttr[GPXRouteWayPointAtttributes.wptLatitudeAttr],
                let longitudeString = wptAttr[GPXRouteWayPointAtttributes.wptLongitudeAttr],
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
            let poiInternalUrl = wayPointAttr[GPXRouteWayPointAtttributes.wayPointPoiInternalUrlAttr] {
            return URL(string: poiInternalUrl)
        } else {
            return nil
        }
    }
}
