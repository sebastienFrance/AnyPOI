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
            return NSLocalizedString("GPXRouteUnknownFromTo", comment: "")
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
                return NSLocalizedString("GPXRouteNoInfos", comment: "")
            }
        }
    }


    /// Return true with a Route with the same URL or name already exist in database
    var isRouteAlreadyExist:Bool {
        get {
            if let _ = relatedRoute {
                return true
            } else {
                return false
            }
        }
    }

    var relatedRoute: Route? {
        get {
            if let url = routeURL,
                !routeName.isEmpty {
                return POIDataManager.sharedInstance.findRoute(url: url, routeName: routeName)
            }
            return nil
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

    func importIt(options:GPXImportOptions, importedPOIs:[PointOfInterest]) {
        guard let _ = routeAttributes else {
            print("\(#function) \(routeName) has no attribute, it cannot be imported...")
            return
        }

        if options.routeOptions.importAsNew || !isRouteAlreadyExist {
            _ = importAsNew(importedPOIs:importedPOIs)
        } else {
            _ = importAsUpdate(importedPOIs:importedPOIs)
        }
    }


    /// Create a new route in the database and add all its waypoints.
    /// WayPoints are created on best effort mode (the POIs must already exist in the database)
    ///
    /// - Returns: the new created route
    fileprivate func importAsNew(importedPOIs:[PointOfInterest]) -> Route {
        let route = POIDataManager.sharedInstance.addRoute(routeName, routePath: [PointOfInterest]())
        appendRouteWayPoints(route:route, importedPOIs: importedPOIs)
        POIDataManager.sharedInstance.commitDatabase()
        return route
    }
    
    /// Update an existing Route with the content of the GPXRoute
    ///  - existing wayPoints are replaced with the wayPoints from GPXRoute (it's not a merge)
    ///  - RouteName is updated
    ///  - LatestTotalDuration and LatestTotalDistance are updated
    fileprivate func importAsUpdate(importedPOIs:[PointOfInterest])  {
        if let theRoute = relatedRoute {
            theRoute.routeName = routeName
            appendRouteWayPoints(route:theRoute, importedPOIs: importedPOIs)
            POIDataManager.sharedInstance.commitDatabase()
        } else {
            print("\(#function) WARNING: route is nil, it should never appear!")
        }
    }

    fileprivate func appendRouteWayPoints(route:Route, importedPOIs:[PointOfInterest]) {
        if let theRouteWayPoints = routeWayPoints {
            for currentWayPoint in theRouteWayPoints {
                let (poi, transportType) = GPXRoute.searchPoi(wayPoint: currentWayPoint, inPois:importedPOIs)
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
    }



    fileprivate static let wayPointPoiInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.poiInternalUrl
    fileprivate static let wayPointInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.internalUrl
    fileprivate static let wayPointTransportTypeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.transportType

    fileprivate static let wptLatitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.latitude
    fileprivate static let wptLongitudeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Attributes.longitude



    /// Search the POI and directionType of a RouteWayPointAttributes. First we look in the imported POIs and only if it cannot be found we look directly
    /// in the database
    ///
    /// - Parameter wayPoint: Contains the information to find the related POI and to get its direction type
    /// - Returns: the POI if it exists in the database otherwise nil is returned
    fileprivate static func searchPoi(wayPoint:GPXParser.RouteWayPointAtttributes, inPois:[PointOfInterest]) -> (poi:PointOfInterest?, transportType:MKDirectionsTransportType) {
        if let wptAttr = wayPoint.routeWptAttributes,
            let latitudeString = wptAttr[GPXRoute.wptLatitudeAttr],
            let longitudeString = wptAttr[GPXRoute.wptLongitudeAttr],
            let latitude = Double(latitudeString),
            let longitude = Double(longitudeString) {
            
            let wptCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
            // Look for the POI using internalURL or poiName AND coordinates
            for currentPoi in inPois {
                if currentPoi.coordinate.latitude == wptCoordinate.latitude &&
                    currentPoi.coordinate.longitude == wptCoordinate.longitude &&
                    wayPoint.poiName == currentPoi.poiDisplayName! {
                    return (currentPoi, getTransportType(wayPoint: wayPoint))
                }
            }
            
            if let wayPointAttr = wayPoint.wayPointAttributes,
                let poiInternalUrl = wayPointAttr[GPXRoute.wayPointPoiInternalUrlAttr],
                let poiUrl =  URL(string: poiInternalUrl) {
                return (POIDataManager.sharedInstance.findPOI(url: poiUrl, poiName: wayPoint.poiName, coordinates:  wptCoordinate), getTransportType(wayPoint: wayPoint))
            }
        }
        return (nil, MKDirectionsTransportType.automobile)
    }
    
    /// Get the transport type of a RouteWayPointAttribute
    ///
    /// - Parameter wayPoint: RouteWayPointAttribute from which to extract the transportType
    /// - Returns: the value of the TransportType. When it cannot be found it return Automobile as default value
    fileprivate static func getTransportType(wayPoint:GPXParser.RouteWayPointAtttributes) -> MKDirectionsTransportType {
        if let wayPointAttr = wayPoint.wayPointAttributes,
            let transportTypeString = wayPointAttr[GPXRoute.wayPointTransportTypeAttr],
            let transportTypeInt = UInt(transportTypeString) {
            return MKDirectionsTransportType(rawValue: transportTypeInt)
        } else {
            return MKDirectionsTransportType.automobile
        }
    }
}

