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
    
    var totalDuration:Double? {
        get {
            if let theRouteAttributes = routeAttributes,
                let totalDurationString = theRouteAttributes[GPXRoute.totalDurationAttr],
                let totalDuration = Double(totalDurationString){
                return totalDuration
            } else {
                return nil
            }
        }
    }
    
    var totalDistance:Double? {
        get {
            if let theRouteAttributes = routeAttributes,
                let totalDistanceString = theRouteAttributes[GPXRoute.totalDistanceAttr],
                let totalDistance = Double(totalDistanceString){
                return totalDistance
            } else {
                return nil
            }
        }
    }
    
    var routeFromToDescription:String {
        get {
            if let wayPoints = routeWayPoints {
                if let fromWayPoint = wayPoints.first,
                    let toWayPoint = wayPoints.last {
                    return fromWayPoint.poiName + " ➔ " + toWayPoint.poiName
                }
            }
            return "Unknown source and destination"
        }
    }
    
    var routeDistanceAndDuration:String {
        get {
            if let duration = totalDuration,
                let distance = totalDistance,
                let wayPoints = routeWayPoints {
                
                let distanceFormatter = LengthFormatter()
                distanceFormatter.unitStyle = .short
                let expectedTravelTime = Utilities.shortStringFromTimeInterval(duration) as String
                return "\(distanceFormatter.string(fromMeters: distance)) in \(expectedTravelTime) with \(wayPoints.count - 1) steps"
            } else {
                return "No infos"
            }
        }
    }
    
    var isRouteAlreadyExist:Bool {
        get {
            if let url = routeURL,
                !routeName.isEmpty {
                if let _ = POIDataManager.sharedInstance.findRoute(url: url, routeName: routeName) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }

    fileprivate var routeURL:URL? {
        get {
            if let routeAttr = routeAttributes,
                let urlString = routeAttr[GPXRoute.routeInternalUrlAttr] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }
    }



    fileprivate static let totalDistanceAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDistance
    fileprivate static let totalDurationAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDuration
    fileprivate static let routeInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.internalUrlAttr

    func importIt(options:GPXImportOptions) {
        guard let _ = routeAttributes else {
            print("\(#function) \(routeName) has no attribute, it cannot be imported...")
            return
        }

        if options.routeOptions.importAsNew || !isRouteAlreadyExist {
            _ = importAsNew()
        } else {
            _ = importAsUpdate()
        }
    }
    
    fileprivate func importAsNew() -> Route {
        let route = POIDataManager.sharedInstance.addRoute(routeName, routePath: [PointOfInterest]())
        if let theRouteWayPoints = routeWayPoints {
            for currentWayPoint in theRouteWayPoints {
                let (poi, transportType) = GPXRoute.getPOI(wayPoint: currentWayPoint)
                if let foundPoi = poi {
                    POIDataManager.sharedInstance.appendWayPoint(route: route, poi: foundPoi, transportType: transportType)
                }
            }
        }
        
        if let distance = totalDistance {
            route.latestTotalDistance = distance
        }
        
        if let duration = totalDuration {
            route.latestTotalDuration = duration
        }
        
        POIDataManager.sharedInstance.commitDatabase()

        return route
    }
    
    fileprivate func importAsUpdate()  {
        if let url = routeURL,
            !routeName.isEmpty {
            if let theRoute = POIDataManager.sharedInstance.findRoute(url: url, routeName: routeName) {
                theRoute.routeName = routeName
                if let theRouteWayPoints = routeWayPoints {
                    let wayPoints = NSMutableOrderedSet()
                    for currentWayPoint in theRouteWayPoints {
                        let (poi, transportType) = GPXRoute.getPOI(wayPoint: currentWayPoint)
                        if let foundPoi = poi {
                            let newWayPoint = POIDataManager.sharedInstance.addWayPoint(foundPoi, transportType: transportType)
                            wayPoints.add(newWayPoint)
                            
                            POIDataManager.sharedInstance.appendWayPoint(route: theRoute, poi: foundPoi, transportType: transportType)
                        }
                    }
                    theRoute.routeWayPoints = wayPoints
                }
                
                if let distance = totalDistance {
                    theRoute.latestTotalDistance = distance
                }
                
                if let duration = totalDuration {
                    theRoute.latestTotalDuration = duration
                }
                
                POIDataManager.sharedInstance.commitDatabase()
            }
        }
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
                return (POIDataManager.sharedInstance.findPOI(url: poiUrl, poiName: wayPoint.poiName, coordinates:  wptCoordinate), transportType)
            }
        }
        return (nil, MKDirectionsTransportType.automobile)
    }
}

