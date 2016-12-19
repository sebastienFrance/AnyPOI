//
//  GPXRoute.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit
class GPXRoute {

    var routeAttributes:[String : String]? = nil
    var routeWayPoints:[GPXParser.RouteWayPointAtttributes]? = nil
    var routeName = ""


    fileprivate static let totalDistanceAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDistance
    fileprivate static let totalDurationAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDuration

    func importIt() {
        guard let theRouteAttributes = routeAttributes else {
            print("\(#function) \(routeName) has no attribute, it cannot be imported...")
            return
        }


        let route = POIDataManager.sharedInstance.addRoute(routeName, routePath: [PointOfInterest]())
        if let theRouteWayPoints = routeWayPoints {
            for currentWayPoint in theRouteWayPoints {
                let (poi, transportType) = GPXRoute.getPOI(wayPoint: currentWayPoint)
                if let foundPoi = poi {
                    POIDataManager.sharedInstance.appendWayPoint(route: route, poi: foundPoi, transportType: transportType)
                }
            }
        }


        if let totalDistanceString = theRouteAttributes[GPXRoute.totalDistanceAttr],
            let totalDistance = Double(totalDistanceString){
            route.latestTotalDistance = totalDistance
        }

        if let totalDurationString = theRouteAttributes[GPXRoute.totalDurationAttr],
            let totalDuration = Double(totalDurationString){
            route.latestTotalDuration = totalDuration
        }

        POIDataManager.sharedInstance.commitDatabase()
    }

    fileprivate static let wayPointPoiInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.poiInternalUrl
    fileprivate static let wayPointInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.internalUrl
    fileprivate static let wayPointTransportTypeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.transportType

    fileprivate static let wptLatitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.latitude
    fileprivate static let wptLongitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.longitude



    fileprivate static func getPOI(wayPoint:GPXParser.RouteWayPointAtttributes) -> (poi:PointOfInterest?, transportType:MKDirectionsTransportType) {
        if let wptAttr = wayPoint.routeWptAttributes,
            let latitudeString = wptAttr[GPXRoute.wptLatitudeAttr],
            let longitudeString = wptAttr[GPXRoute.wptLongitudeAttr],
            let latitude = Double(latitudeString),
            let longitude = Double(longitudeString) {

            let wptCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
            if let wayPointAttr = wayPoint.wayPointAttributes,
                let poiInternalUrl = wayPointAttr[GPXRoute.wayPointPoiInternalUrlAttr],
                let poiUrl =  URL(string: poiInternalUrl),
                let transportTypeString = wayPointAttr[GPXRoute.wayPointTransportTypeAttr],
                let transportTypeInt = UInt(transportTypeString) {
                let transportType = MKDirectionsTransportType(rawValue: transportTypeInt)
                return (POIDataManager.sharedInstance.findPOI(url: poiUrl, poiName: "", coordinates:  wptCoordinate), transportType)
            }
        }
        return (nil, MKDirectionsTransportType.automobile)
    }
}

