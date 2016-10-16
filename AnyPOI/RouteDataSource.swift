//
//  RouteDataSource.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 28/05/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class RouteDataSource {
    
    let theRoute:Route
    
    fileprivate var fromWayPointIndex:Int!
    
    var isBeforeRouteSections:Bool {
        get {
            return fromWayPointIndex == 0 ? true : false
        }
    }

    // Returns the start of the route section or the start of the whole route
    // when not displaying a section
    var fromWayPoint:WayPoint? {
        get {
            if isBeforeRouteSections {
                return theRoute.startWayPoint
            } else {
                return theRoute.wayPointAtIndex(fromWayPointIndex - 1)
            }
        }
    }
    
    // Returns the end of the route section or the end of the whole route
    // when not displaying a section
   var toWayPoint:WayPoint? {
        get {
            if isBeforeRouteSections {
                return theRoute.endWayPoint
            } else {
                return theRoute.wayPointAtIndex(fromWayPointIndex)
            }
        }
    }
    
    // Returns the POI that starts the route section or the  POI that starts the whole route
    // when not displaying a section
   var fromPOI:PointOfInterest? {
        get {
            return fromWayPoint?.wayPointPoi
        }
    }
    
    
    // Returns the POI that ends the route section or the  POI that ends the whole route
    // when not displaying a section
    var toPOI:PointOfInterest? {
        get {
            return toWayPoint?.wayPointPoi
        }
    }
    
    // All wayPoints of the route
    var wayPoints:[WayPoint] {
        get {
            return theRoute.wayPoints
        }
    }
    
    // All POIs of the route. If a POI is used in several WayPoints it will appear several times
    var pois:[PointOfInterest] {
        get {
            return theRoute.pois
        }
    }

    // Full distance and travel time of the whole route
    fileprivate func fullDistanceAndTravelTime() -> (distance:CLLocationDistance, travelTime:TimeInterval) {
        return theRoute.fullDistanceAndTravelTime()
    }
    
    init(route:Route) {
        theRoute = route
        fromWayPointIndex = 0
    }
    
    deinit {
        print("RouteDatasource: \(theRoute.routeName) deallocated")
    }
    
    func setCurrentWayPoint(_ index:Int) {
        fromWayPointIndex = index
    }
    
    // Gives the name of the full route or of the WayPoint currently displayed
    var routeName:String! {
        get {
            if isBeforeRouteSections {
                return allRouteName
            } else {
                if let fromDisplayName = fromPOI?.poiDisplayName,
                    let toDisplayName = toPOI?.poiDisplayName {
                    return "\(fromDisplayName) ➔ \(toDisplayName)"
                } else {
                    return NSLocalizedString("UnknownFromToRouteDatasource", comment: "")
                }
            }
        }
    }
    
    var allRouteName:String! {
        get {
            return "\(NSLocalizedString("FullDirectionRouteDatasource", comment: "")) \(theRoute.routeName!)"
        }
    }
    
    // Gives the distance & time of the full route or of the WayPoint currently displayed
    var routeDistanceAndTime:String! {
        get {
            if isBeforeRouteSections {
                return allRouteDistanceAndTime
            } else {
                if let route = fromWayPoint?.routeInfos {
                    let distanceFormatter = LengthFormatter()
                    distanceFormatter.unitStyle = .short
                    let expectedTravelTime = Utilities.shortStringFromTimeInterval(route.expectedTravelTime) as String
                    return "\(distanceFormatter.string(fromMeters: route.distance)) in \(expectedTravelTime)"
                } else {
                    return "No route info"
                }
            }
        }
    }
    
    
    var allRouteDistanceAndTime:String! {
        get {
            let  (fullDistance, fullExpectedTravelTime) = fullDistanceAndTravelTime()
            let distanceFormatter = LengthFormatter()
            distanceFormatter.unitStyle = .short
            let expectedTravelTime = Utilities.shortStringFromTimeInterval(fullExpectedTravelTime) as String
            return "\(distanceFormatter.string(fromMeters: fullDistance)) in \(expectedTravelTime)"
        }
    }
    
    // Returns the number of occurences a WayPoint is used by this route
    func poiOccurences(_ poi:PointOfInterest) -> Int {
        var counter = 0
        for currentPoi in theRoute.pois {
            if currentPoi === poi {
                counter += 1
            }
        }
        return counter
    }
    
    // Return true when the given Poi is used by the Route, otherwise it returns false
    func hasPoi(_ poi:PointOfInterest) -> Bool {
        for currentPoi in theRoute.pois {
            if currentPoi === poi {
                return true
            }
        }
        return false
    }
    
    // Delete all WayPoints using the given POI
    fileprivate func deleteAllWayPointsUsing(_ poi:PointOfInterest) {
        var wayPointsToDelete = [WayPoint]()
        for currentWayPoint in wayPoints {
            if currentWayPoint.wayPointPoi === poi {
                wayPointsToDelete.append(currentWayPoint)
            }
        }
        
        // delete all WayPoints where this Poi is used
        for currentWayPoint in wayPointsToDelete {
            POIDataManager.sharedInstance.deleteWayPoint(currentWayPoint)
        }
        POIDataManager.sharedInstance.commitDatabase()
    }
    
    func deleteWayPoint(_ wayPointToDelete:WayPoint) {
        if fromWayPointIndex != 0 {
            // === The WayPoint to remove is currently displayed
            if wayPointToDelete == fromPOI {
                // If it's the head of the route we just need to update the index when
                // there's no more WayPoint to display a section, then we go back to the 
                // beginning
                if fromWayPointIndex == 1 {
                    if theRoute.routeWayPoints!.count <= 2 {
                        fromWayPointIndex = 0
                    }
                } else {
                    fromWayPointIndex = fromWayPointIndex - 1
                    if fromWayPointIndex == (theRoute.routeWayPoints!.count - 1) { // FIXME: 😡⚡️ unreachable case?
                        // we delete the latest toWayPoint
                        if theRoute.routeWayPoints!.count <= 2 {
                            fromWayPointIndex = 0
                        } else {
                            fromWayPointIndex = fromWayPointIndex - 1 // FIXME: 😡⚡️ unreachable case?
                        }
                    }
                }
                
            } else {
                // The wayPoint to remove is not displayed
                // If it's after the currently displayed wayPoint there's nothing to change.
                // If we delete a WayPoint that is before the currently displayed WayPoint we need to
                // decrement the index 
                if let indexOfWayPointToDelete = indexOfWayPoint(wayPointToDelete) , indexOfWayPointToDelete <= fromWayPointIndex - 1 {
                    fromWayPointIndex = fromWayPointIndex - 1
                }
            }
        } else {
            // === Full route is displayed, nothing special has to be done
        }
        
        POIDataManager.sharedInstance.deleteWayPoint(wayPointToDelete)
        POIDataManager.sharedInstance.commitDatabase()

    }
    
    fileprivate func indexOfWayPoint(_ wayPointToFind:WayPoint) -> Int? {
        var index = 0
        for currentWayPoint in wayPoints {
            if currentWayPoint === wayPointToFind {
                return index
            } else {
                index += 1
            }
        }
        
        return nil
    }
    
    // Remove the given Poi from the route. The route section will be automatically updated
    // If the Poi is currently displayed as To or From of the route section:
    //   - Only the WayPoint displaying this Poi is deleted
    // If the Poi is not used by the WayPoint currently displayed:
    //   - All WayPoints using this Poi are removed from the route
    // If the whole route is displayed
    //   - All WayPoints using this Poi are removed from the route
    func deleteWayPointsWith(_ poi:PointOfInterest) {
        if fromWayPointIndex != 0 {
            var wayPointToDelete:WayPoint?
            if poi === fromPOI {
                // === The Poi to remove is used as From by the WayPoint currently displayed
                
                wayPointToDelete = fromWayPoint! // get it before to change indexes
                
                if fromWayPointIndex == 1 {
                    // if the route has less than or equal 2 Waypoint we don't have route to display
                    // so we go back at the beginning
                    if theRoute.routeWayPoints!.count <= 2 {
                        fromWayPointIndex = 0
                    }
                } else {
                    fromWayPointIndex = fromWayPointIndex - 1
                    if fromWayPointIndex == (theRoute.routeWayPoints!.count - 1) {
                        // we delete the latest toWayPoint
                        if theRoute.routeWayPoints!.count <= 2 {
                            fromWayPointIndex = 0
                        } else {
                            fromWayPointIndex = fromWayPointIndex - 1
                        }
                    }
                }
            } else if poi === toPOI {
                // === The Poi to remove is used as To by the WayPoint currently displayed
                
                 wayPointToDelete = toWayPoint! // get it before to change indexes
                if fromWayPointIndex == (theRoute.routeWayPoints!.count - 1) {
                    // we delete the latest toWayPoint
                    if theRoute.routeWayPoints!.count <= 2 {
                        fromWayPointIndex = 0
                    } else {
                        fromWayPointIndex = fromWayPointIndex - 1
                    }
                }
            } else {
                // === The Poi to remove is not used by the WayPoint currently displayed
                
                // Keep in mind the currently displayed WayPoint to update the route index
                // after the deletion of the Poi
                let wayPoint = fromWayPoint!
                
                // The POI is not part of the currently displayed section
                // We remove all occurence of this POI from the route
                deleteAllWayPointsUsing(poi)
                
                // We need to recompute the WayPointIndex due to deleted Poi
                if let index = theRoute.indexOfWayPoint(wayPoint) {
                    fromWayPointIndex = index + 1
                } else {
                    fromWayPointIndex = 0 // Should not happen?
                }
                return
            }
            
            if let theWayPoint = wayPointToDelete {
                POIDataManager.sharedInstance.deleteWayPoint(theWayPoint)
                POIDataManager.sharedInstance.commitDatabase()
            }
        } else {
            // === Remove all WayPoints using this Poi
            deleteAllWayPointsUsing(poi)
        }
    }
    
    
    // Insert a wayPoint at the head of the route
    func insertPoiAsRouteStart(_ poi:PointOfInterest) {
        if wayPoints.count > 0 {
            POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: 0, transportType: wayPoints[0].transportType!)
        } else {
            POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: 0)
        }
        POIDataManager.sharedInstance.commitDatabase()
    }
    
    // insert a wayPoint at the end of the route
    func insertPoiAtAsRouteEnd(_ poi:PointOfInterest) {
        POIDataManager.sharedInstance.addWayPointToRoute(theRoute, pois: [poi])
        POIDataManager.sharedInstance.commitDatabase()
    }

    // Insert a Poi as a WayPoint after the current position
    func insertPoiInRoute(_ poi:PointOfInterest) {
        if let from = fromWayPoint {
            if isBeforeRouteSections {
                if theRoute.wayPoints.count <= 1 {
                    POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: 1, transportType: from.transportType!)
                } else {
                    POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: 0, transportType: from.transportType!)
                }
            } else {
                POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: fromWayPointIndex + 1, transportType: from.transportType!)
                fromWayPointIndex = fromWayPointIndex + 1
            }
        } else {
            // it's the first WayPoint added to the route
            POIDataManager.sharedInstance.insertWayPointTo(theRoute, poi: poi, index: 0)
        }
        POIDataManager.sharedInstance.commitDatabase()
   }

    // Reset the route position at the head
    func showAllRoute() {
        fromWayPointIndex = 0
    }
    
    // move the route position to the next section (or to the head if we are at the end)
    func moveToNextWayPoint() {
        if fromWayPointIndex == (theRoute.routeWayPoints!.count - 1) {
            fromWayPointIndex = 0
        } else {
            fromWayPointIndex = fromWayPointIndex + 1
        }
    }
    
    
    // move the route position to the previous section (or to the latest section if we are at the start)
    func moveToPreviousWayPoint() {
        if isBeforeRouteSections {
            fromWayPointIndex = (theRoute.routeWayPoints!.count - 1)
        } else {
            fromWayPointIndex = fromWayPointIndex - 1
        }
    }
    
    // Exchange the position of 2 wayPoints (it doesn't update the route position)
    func moveWayPoint(_ fromIndex: Int, toIndex:Int) {
        theRoute.moveWayPoint(fromIndex, toIndex: toIndex)
    }
    
    // Delete a wayPoints at the given index (it doesn't update the route position)
    func deleteWayPointAtIndex(_ index:Int) {
        POIDataManager.sharedInstance.deleteWayPoint(theRoute.wayPoints[index])
        POIDataManager.sharedInstance.commitDatabase()
    }
    
    // Change the transport type of a route section at the given index
    func setTransportTypeForWayPointAtIndex(_ index:Int, transportType:MKDirectionsTransportType) {
        if let wayPoint = theRoute.wayPointAtIndex(index) {
            wayPoint.transportType = transportType
            POIDataManager.sharedInstance.updateWayPoint(wayPoint)
            POIDataManager.sharedInstance.commitDatabase()
        }
    }
    
    // Change the transport type of the current position
    func updateTransportTypeFromWayPoint(_ transportType: MKDirectionsTransportType) {
        if let from = fromWayPoint {
            from.transportType = transportType
            from.calculatedRoute = nil
            POIDataManager.sharedInstance.updateWayPoint(from)
            POIDataManager.sharedInstance.commitDatabase()
        } else {
            print("Warning: \(#function) called with non existing from wayPoint")
        }
    }

}
