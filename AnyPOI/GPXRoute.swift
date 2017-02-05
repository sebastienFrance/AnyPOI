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
    var routeWayPoints:[GPXRouteWayPointAtttributes]? = nil
    var routeName = ""
    
    var totalDuration:Double? {
        get {
            if let theRouteAttributes = routeAttributes,
                let totalDurationString = theRouteAttributes[XSD.routeTotalDurationAttr],
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
                let totalDistanceString = theRouteAttributes[XSD.routeTotalDistanceAttr],
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
                let urlString = routeAttr[XSD.routeInternalUrlAttr] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }
    }


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
        setWayPointsFor(route:route, importedPOIs: importedPOIs)
        POIDataManager.sharedInstance.commitDatabase()
        return route
    }
    
    /// Update an existing Route with the content of the GPXRoute
    ///  - existing wayPoints are replaced with the wayPoints from GPXRoute (it's not a merge)
    ///  - RouteName is updated
    ///  - LatestTotalDuration and LatestTotalDistance are updated
    fileprivate func importAsUpdate(importedPOIs:[PointOfInterest]) -> Route?  {
        if let theRoute = relatedRoute {
            theRoute.routeName = routeName
            
            // Delete the old wayPoints of the route before to set the new ones
            for currentWayPoint in theRoute.wayPoints {
                POIDataManager.sharedInstance.deleteWayPoint(currentWayPoint)
            }
            
            // Commit to make sure the old data are not yet available when the new WayPoints will
            // be imported
            POIDataManager.sharedInstance.commitDatabase()
            
            setWayPointsFor(route:theRoute, importedPOIs: importedPOIs)
            POIDataManager.sharedInstance.commitDatabase()
            return theRoute
        } else {
            print("\(#function) WARNING: route is nil, it should never appear!")
            return nil
        }
    }

    
    /// Configure the route with the list of WayPoints found in the GPX file.
    /// If the route was already configured, all its old wayPoints will be removed and then replaced by the new ones
    /// We look first in the imported POIs to create the wayPoints because maybe the user has imported POIs using "asNew"
    /// and then we want to make sure we will attach the wayPoints to the newly created POIs and not POIs that were already in 
    /// the database before the import of the GPX file
    ///
    /// - Parameters:
    ///   - route: the route that must be reconfigured
    ///   - importedPOIs: POIs from GPX file that have been imported
    fileprivate func setWayPointsFor(route:Route, importedPOIs:[PointOfInterest]) {
        if let theRouteWayPoints = routeWayPoints {
            for currentWayPoint in theRouteWayPoints {
                let (poi, transportType) = GPXRoute.searchPoi(wayPoint: currentWayPoint, importedPois:importedPOIs)
                if let foundPoi = poi {
                    POIDataManager.sharedInstance.appendWayPoint(route: route, poi: foundPoi, transportType: transportType)
                }
            }
        }
    }

    /// Search the POI and directionType of a RouteWayPointAttributes. First we look in the imported POIs and only if it cannot be found we look directly
    /// in the database
    ///
    /// - Parameter wayPoint: Contains the information to find the POI and to get its transport type
    /// - Parameter importedPois: Contains the POIs that have been imported
    /// - Returns: the POI if it exists in the database otherwise nil is returned. It returns also the transport type of the RouteWayPointAttribute
    fileprivate static func searchPoi(wayPoint:GPXRouteWayPointAtttributes, importedPois:[PointOfInterest]) -> (poi:PointOfInterest?, transportType:MKDirectionsTransportType) {
        if let coordinate = wayPoint.coordinate {
            // Look for the POI in the imported POIs
            for currentPoi in importedPois {
                if currentPoi.coordinate.latitude == coordinate.latitude &&
                    currentPoi.coordinate.longitude == coordinate.longitude &&
                    wayPoint.poiName == currentPoi.poiDisplayName! {
                    return (currentPoi, wayPoint.transportType)
                }
            }
            
            // Look for the POI using internalURL or poiName AND coordinates
            if let poiUrl = wayPoint.poiInternalURL {
                return (POIDataManager.sharedInstance.findPOI(url: poiUrl,
                                                              poiName: wayPoint.poiName,
                                                              coordinates: coordinate),
                        wayPoint.transportType)
            }
        }
        return (nil, MKDirectionsTransportType.automobile)
    }
}

