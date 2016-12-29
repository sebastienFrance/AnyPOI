//
//  Route.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 01/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import CoreSpotlight
import MobileCoreServices // for kUTTypeData

@objc(Route)
class Route: NSManagedObject {

    // Insert code here to add functionality to your managed object subclass
    struct Notifications {
        static let directionsDone = "directionsDone"
        static let directionStarting = "directionStarting"
        static let directionForWayPointUpdated = "directionForWayPointUpdated"
    }
    
    struct DirectionStartingParameters {
        static let startingWayPoint = "startingWayPoint"

    }
    
    
    // Get the bounding box to display the route on Map
    var region: MKCoordinateRegion? {
        get {

            var overlays = [MKMultiPoint]()
            var annotations = [PointOfInterest]()
            for wayPoint in routeWayPoints! {
                let theWayPoint = wayPoint as! WayPoint
                if let theRoutePolyline = theWayPoint.routeInfos?.polyline {
                    overlays.append(theRoutePolyline)
                }
                
                if let thePoi = theWayPoint.wayPointPoi {
                    annotations.append(thePoi)
                }
            }

            if overlays.count == 0 {
                if annotations.count > 0 {
                   return MapUtils.boundingBoxForAnnotations(annotations)
                } else {
                    return nil
                }
            } else {
                var (topLeft, bottomRight) = MapUtils.boundingBoxForOverlays(overlays)
                (topLeft, bottomRight) = MapUtils.extendBoundingBox(topLeft, bottomRightCoord: bottomRight, annotations: annotations)
                return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
            }
        }
    }

    // Get all Polylines to display the route
    var polyLines:[MKPolyline] {
        get {
            var polyLines = [MKPolyline]()
            for wayPoint in routeWayPoints! {
                let theWayPoint = wayPoint as! WayPoint
                if let theRoutePolyline = theWayPoint.routeInfos?.polyline {
                    polyLines.append(theRoutePolyline)
                }
            }
            return polyLines
        }
    }

    // Get all Point Of Interet from the route
    var pois:[PointOfInterest] {
        get {
            var allPointOfInterest = [PointOfInterest]()
            for wayPoint in routeWayPoints! {
                let theWayPoint = wayPoint as! WayPoint
                allPointOfInterest.append(theWayPoint.wayPointPoi!)
            }
            return allPointOfInterest
        }
    }
    
    var mapItems:[MKMapItem] {
        get {
            var items = [MKMapItem]()
            for wayPoint in wayPoints   {
                let thePoi = wayPoint.wayPointPoi!
                let newMapItem = MKMapItem(placemark: MKPlacemark(coordinate: thePoi.coordinate, addressDictionary: nil))
                items.append(newMapItem)
            }
            return items
        }
    }
    
    var wayPoints:[WayPoint] {
        return routeWayPoints?.array as! [WayPoint]
    }

    // Starting point of the route
    var startWayPoint: WayPoint? {
        get {
            return routeWayPoints!.firstObject as? WayPoint
        }
    }

    // End point of the route
    var endWayPoint: WayPoint? {
        get {
            return routeWayPoints!.lastObject as? WayPoint
        }
    }
    
    fileprivate var isDirectionLoading = false


    func initializeRoute(_ routeName:String, wayPoints:NSOrderedSet) {
        self.routeName = routeName
        self.routeWayPoints = wayPoints
        self.latestTotalDistance = Double.nan
        self.latestTotalDuration = Double.nan
    }
    
    // Get a WayPoint from the route
    func wayPointAtIndex(_ index:Int) -> WayPoint? {
        if index > routeWayPoints!.count {
            return nil
        } else {
            return routeWayPoints!.object(at: index) as? WayPoint
        }
    }
    
    func indexOfWayPoint(_ wayPoint:WayPoint) -> Int? {
        let index = routeWayPoints!.index(of: wayPoint)
        if index != NSNotFound {
            return index
        } else {
            return nil
        }
    }

    // Get the full distance & travel time of the route
    func fullDistanceAndTravelTime() -> (distance:CLLocationDistance, travelTime:TimeInterval) {
        var fullDistance = CLLocationDistance(0)
        var fullExpectedTravelTime = TimeInterval(0)
        
        for wayPoint in routeWayPoints! {
            let currentWayPoint = wayPoint as! WayPoint
            if let route = currentWayPoint.routeInfos {
                fullDistance += route.distance
                fullExpectedTravelTime += route.expectedTravelTime
            }
        }
        
        return (fullDistance, fullExpectedTravelTime)
    }
    
    var latestFullRouteDistanceAndTime:String! {
        get {
            if !latestTotalDistance.isNaN && !latestTotalDistance.isInfinite &&
                !latestTotalDuration.isNaN && !latestTotalDuration.isInfinite {
                let distanceFormatter = LengthFormatter()
                distanceFormatter.unitStyle = .short
                let expectedTravelTime = Utilities.shortStringFromTimeInterval(latestTotalDuration) as String
                return "\(distanceFormatter.string(fromMeters: latestTotalDistance)) in \(expectedTravelTime)"
            } else {
                return ""
            }
        }
    }
    
    var routeDescription:String! {
        get {
            if wayPoints.count > 1 {
                return "\(wayPoints[0].wayPointPoi!.poiDisplayName!) ➔ \(wayPoints.last!.wayPointPoi!.poiDisplayName!)"
            } else if wayPoints.count == 1 {
                return "\(wayPoints[0].wayPointPoi!.poiDisplayName!) ➔ \(NSLocalizedString("RouteNoDestination", comment: ""))"
            } else {
                return NSLocalizedString("RouteNotDefined", comment: "")
            }
        }
    }

    // This method is called at every commit (update, delete or create) to update SpotLight
    override func didSave() {
        if isDeleted {
            // Poi is deleted, we must unregister it from Spotlight
            removeFromSpotLight()
        } else {
            // Poi is updated or created, we need to update its properties in Spotlight
            updateInSpotLight()
        }
    }
    
    fileprivate var attributeSetForSearch : CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
        // Add metadata that supplies details about the item.
        attributeSet.title = routeName!
        
        attributeSet.contentDescription = routeDescription + " " + latestFullRouteDistanceAndTime
        
        // Add keywords that will contains:
        // - All words from the display name
        let subStringFromDisplayName = routeName!.characters.split(separator: " ")
        var keywords = [String]()
        for currentString in subStringFromDisplayName {
            if currentString.count > 1 {
                keywords.append(String(currentString))
                print("\(#function) keyword added: \(String(currentString))")
            }
        }

        //FIXEDME: 😡 Translate I18N
        keywords.append(NSLocalizedString("SpotlightKeywordTravel", comment: ""))
        keywords.append(NSLocalizedString("SpotlightKeywordHolidays", comment: ""))
        keywords.append(NSLocalizedString("SpotlightKeywordRoute", comment: ""))
        attributeSet.keywords = keywords
        
        
        // It Seems SupportsNavigation & supportsPhoneCall are mutually exclusives!
        if let icon = UIImage(named:"Waypoint Map-40.png")  {
            attributeSet.thumbnailData = UIImagePNGRepresentation(icon)
        }
        
        return attributeSet
    }
    
    // Add or Update the Poi in Spotlight
    fileprivate func updateInSpotLight() {

        
        // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
        let item = CSSearchableItem(uniqueIdentifier: objectID.uriRepresentation().absoluteString, domainIdentifier: "Route", attributeSet: attributeSetForSearch)
        
        // Add the item to the on-device index.
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let theError = error {
                print("\(#function) error with \(theError.localizedDescription)")
            }
        }
    }
    
    func removeFromSpotLight() {
        let URI = objectID.uriRepresentation().absoluteString
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [URI]) { error in
            if let theError = error {
                print("\(#function) Error Route \(self.routeName!) cannot be removed from Spotlightn, error: \(theError.localizedDescription)")
            }
        }
    }

    
    //MARK: Direction methods
    // When a WayPoint is removed from a route we must reset the calculated route 
    // from the previous wayPoint (if the removed wayPoint is not the start)
    func willRemoveWayPoint(_ wayPoint:WayPoint) {
        let index = routeWayPoints!.index(of: wayPoint)
        if index != NSNotFound && index > 0 {
            let source = routeWayPoints!.object(at: index - 1) as! WayPoint
            source.routeInfos = nil
        }
    }
    
    // Re-compute the direction to the given wayPoint (if it's not the start of the route)
    func resetDirectionTo(_ wayPoint:WayPoint) {
        let index = routeWayPoints!.index(of: wayPoint)
        if index != NSNotFound && index >= 0 {
            let source = routeWayPoints!.object(at: index) as! WayPoint
            source.routeInfos = nil
        }
    }
    
    func hasToReloadDirections() -> Bool {
        
        // look for the first wayPoint without calculatedRoute and request an update
        var foundWayPoint = false
        var index = 0
        while !foundWayPoint && index < (wayPoints.count - 1) {
            if wayPoints[index].routeInfos == nil {
                foundWayPoint = true
            } else {
                index += 1
            }
        }
        return foundWayPoint
    }
    
    // Load direction starting with the first WayPoint for which there's no calculated route.
    // The direction is requested only if we have the placemark for all Pois in the Route

    // Notifications:
    //  - directionStarting: sent when the route contains at least one wayPoint where the route must be computed. When no route update then this notification is not sent
    //  - directionsDone: it's always sent, only one time, at the end of the route computation. This notification is sent even when there's no route update
    //  - directionForWayPointUpdated : it's sent for each WayPoint for which a route has been computed. The notification contains the WayPoint which is the source of the route

    var routeToReloadCounter = 0
    
    func reloadDirections() {
        
        if isDirectionLoading {
            print("route \(routeName) is already loading direction, we don't resquest it twice")
            return
        }
        
        // look for the first wayPoint without calculatedRoute and request an update
        var foundWayPoint = false
        //var index = 0
        var startIndex = 0
        
        // We cannot have route to compute if don't have at least 2 WayPoints
        if wayPoints.count > 1 {
            for index in 0..<wayPoints.count - 1  {
                if wayPoints[index].routeInfos == nil {
                    if !foundWayPoint {
                        foundWayPoint = true
                        startIndex = index
                    }
                    routeToReloadCounter += 1
                }
            }
        }
        
        
        if foundWayPoint {
            print("Request direction from index: \(startIndex)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionStarting),
                                                                      object: self,
                                                                      userInfo:[DirectionStartingParameters.startingWayPoint : wayPoints[startIndex]])
            requestRouteDirectionFrom(currentIndex:startIndex, untilEnd: true, forceToReload: false)
        } else {
            // Notify the route has been updated even when nothing has changed
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionsDone), object: self)
        }
    }

    fileprivate func requestRouteFrom(currentIndex:Int, untilEnd:Bool, forceToReload:Bool) {
        isDirectionLoading = true
        requestRouteDirectionFrom(currentIndex:currentIndex, untilEnd: untilEnd, forceToReload: forceToReload)
    }
    
    // Load the route direction for or from at the given index when untilEnd is set to False or True.
    // When forceToReload is set to true, the direction will be requested again even if there's already 
    // a calculated direction.
    fileprivate func requestRouteDirectionFrom(currentIndex:Int, untilEnd:Bool, forceToReload:Bool) {
        // We need at least 2 wayPoint to do something
        if wayPoints.count < 2 {
            isDirectionLoading = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionsDone), object: self)
        }
        
        if currentIndex >= (wayPoints.count - 1) {
            print("Error, cannot request a route starting with the latest wayPoint")
            isDirectionLoading = false
            return
        }
        if wayPoints[currentIndex].routeInfos == nil || (wayPoints[currentIndex].routeInfos != nil && forceToReload) {
            if let directions = RouteUtilities.getDirectionRequestFor(wayPoints[currentIndex], destination: wayPoints[currentIndex + 1]) {
                print("requestRouteDirectionFrom to Server with currentIndex : \(currentIndex)")
                directions.calculate { routeResponse, routeError in
                    print("calculateDirectionsWithCompletionHandler with currentIndex : \(currentIndex)")
                    
                    self.routeToReloadCounter -= 1
                    
                    let theWayPoint = self.wayPoints[currentIndex]
                    if let error = routeError {
                        theWayPoint.routeInfos = nil
                        print("Error calculating direction \(error.localizedDescription)")
                    } else {
                        // Get the first route direction from the response
                        if let routeDirection = routeResponse,
                            let firstRoute = self.getShortestRouteFrom(routeDirection) {
                            
                            switch firstRoute.transportType {
                            case MKDirectionsTransportType.automobile:
                                firstRoute.polyline.title = MapUtils.PolyLineType.automobile
                            case MKDirectionsTransportType.walking:
                                firstRoute.polyline.title = MapUtils.PolyLineType.wakling
                            case MKDirectionsTransportType.transit:
                                firstRoute.polyline.title = MapUtils.PolyLineType.transit
                            default:
                                firstRoute.polyline.title = "Unknown"
                            }
                            theWayPoint.routeInfos = RouteInfos(route:firstRoute)

                            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionForWayPointUpdated), object: theWayPoint)
                        }
                    }
                    
                    if untilEnd && (currentIndex + 1 < self.wayPoints.count - 1) {
                        self.requestRouteFrom(currentIndex:currentIndex + 1, untilEnd:true, forceToReload: forceToReload)
                    } else {
                        self.isDirectionLoading = false
                        self.updateLatestDistanceAndDuration()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionsDone), object: self)
                    }
                }
            } else {
                print("Direction cannot be allocated from \(wayPoints[currentIndex].wayPointPoi?.poiDisplayName) to \(wayPoints[currentIndex + 1].wayPointPoi?.poiDisplayName)")
                isDirectionLoading = false
            }
        } else {
            // look for the next
            if untilEnd && (currentIndex + 1 < self.wayPoints.count - 1) {
                self.requestRouteFrom(currentIndex:currentIndex + 1, untilEnd:true, forceToReload: forceToReload)
            } else {
                self.isDirectionLoading = false
                self.updateLatestDistanceAndDuration()
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.directionsDone), object: self)
            }
        }
    }
    
    fileprivate func updateLatestDistanceAndDuration() {
       let (distance, travelTime) = fullDistanceAndTravelTime()
        latestTotalDuration = travelTime
        latestTotalDistance = distance
        POIDataManager.sharedInstance.commitDatabase()
    }
    
    func getShortestRouteFrom(_ routeDirections:MKDirectionsResponse) -> MKRoute? {
        if routeDirections.routes.count > 0 {
            var shortestRouteIndex = 0
            var shortestDistance = routeDirections.routes[0].distance
            for index in 1..<routeDirections.routes.count {
                let currentRoute = routeDirections.routes[index]
                if currentRoute.distance < shortestDistance {
                    shortestDistance = currentRoute.distance
                    shortestRouteIndex = index
                }
            }
            return routeDirections.routes[shortestRouteIndex]
        } else {
            return nil
        }
    }
    
    
    // Move a WayPoint to another position in the route and update impacted wayPoints
    func moveWayPoint(fromIndex: Int, toIndex:Int) {
        // Make sure indexes are valids
        if fromIndex == toIndex {
            print("Invalid indexes from \(fromIndex) is less than to \(toIndex)")
            return
        }
        
        if fromIndex >= routeWayPoints!.count || fromIndex < 0 {
            print("swapRoute invalid value for fromIndex: \(fromIndex)")
            return
        }
        
        if toIndex >= routeWayPoints!.count || toIndex < 0 {
            print("swapRoute invalid value for toIndex: \(toIndex)")
            return
        }
        
        // Store old transportTypes
        let oldToMinusTransportType = toIndex > 0 ? wayPointAtIndex(toIndex - 1)?.transportType! : UserPreferences.sharedInstance.routeDefaultTransportType
        let oldFromMinusTransportType = fromIndex > 0 ? wayPointAtIndex(fromIndex - 1)?.transportType! : UserPreferences.sharedInstance.routeDefaultTransportType
        let oldToTransportType = wayPointAtIndex(toIndex)?.transportType!
        let oldFromTransportType = wayPointAtIndex(fromIndex)?.transportType!
        
        let newRoutes = NSMutableOrderedSet.init(orderedSet: routeWayPoints!)
        newRoutes.moveObjects(at: IndexSet(integer: fromIndex), to: toIndex)
        routeWayPoints = newRoutes
        
        // Update transportType based on movement
        if fromIndex > toIndex {
            if toIndex > 0 {
                wayPointAtIndex(toIndex - 1)?.transportType = oldFromMinusTransportType
                wayPointAtIndex(toIndex - 1)?.routeInfos = nil
            }
            wayPointAtIndex(toIndex)?.transportType = oldToMinusTransportType
            wayPointAtIndex(toIndex)?.routeInfos = nil
            wayPointAtIndex(fromIndex)?.transportType = oldFromTransportType
            wayPointAtIndex(fromIndex)?.routeInfos = nil
        } else {
            if fromIndex > 0 {
                wayPointAtIndex(fromIndex - 1)?.transportType = oldFromTransportType
                wayPointAtIndex(fromIndex - 1)?.transportType = nil
             }
            wayPointAtIndex(toIndex)?.transportType = oldToTransportType
            wayPointAtIndex(toIndex)?.routeInfos = nil
            wayPointAtIndex(toIndex - 1)?.transportType = oldFromMinusTransportType
            wayPointAtIndex(toIndex - 1)?.routeInfos = nil
       }
        
        
        // If the latest wayPoint has been moved then we reset the calculatedRoute for the new latest
        // waypoint
        if fromIndex == (newRoutes.count - 1) || toIndex == (newRoutes.count - 1) {
            let latestWayPoint = newRoutes.lastObject as! WayPoint
            latestWayPoint.routeInfos = nil
       }
        
        POIDataManager.sharedInstance.updateRoute(route:self)
        POIDataManager.sharedInstance.commitDatabase()
    }
}

extension Route {
    func toGPXElement() -> XMLElement {
        var rteElement = XMLElement(elementName: GPXParser.XSD.GPX.Elements.RTE.name)
        rteElement.addSub(element: XMLElement(elementName: GPXParser.XSD.GPX.Elements.RTE.Elements.name.name, withValue:routeName!))
        
        var rtept = XMLElement(elementName: GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.name)
        for currentWayPoint in wayPoints {
            rtept.addSub(element: currentWayPoint.toGPXElement())
        }
        
        rteElement.addSub(element: rtept)
        
        var GPXExtension = XMLElement(elementName: GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.name)
        GPXExtension.addSub(element: addRouteExtensionToGPX())
        
        rteElement.addSub(element: GPXExtension)
        return rteElement
    }
    
    
    fileprivate func addRouteExtensionToGPX() -> XMLElement {
        let attributes = [GPXParser.routeInternalUrlAttr : objectID.uriRepresentation().absoluteString,
                          GPXParser.routeTotalDistanceAttr : "\(latestTotalDistance)",
                          GPXParser.routeTotalDurationAttr : "\(latestTotalDuration)"]
        let element = XMLElement(elementName: GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.name, attributes: attributes)
        return element
    }
}

