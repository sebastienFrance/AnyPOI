//
//  RouteManager.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 15/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import PKHUD

protocol RouteDisplayInfos : class {
    func refresh(datasource:RouteDataSource)
    func hideRouteDisplay()
}

class RouteManager: NSObject {
    let routeDatasource:RouteDataSource

    enum RouteSectionProgress {
        case forward, backward, all
    }
    
    fileprivate enum InsertPoiPostion {
        case head, tail, currentPosition
    }

    
    struct RouteFromCurrentLocation {
        var toPOI: PointOfInterest
        var route: MKRoute
        var transportType:MKDirectionsTransportType
        var region:MKCoordinateRegion {
            get {
                let (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(route.polyline)
                return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
            }
        }
       
        init(poi:PointOfInterest, route:MKRoute, transportType:MKDirectionsTransportType) {
            self.toPOI = poi
            self.route = route
            self.route.polyline.title = MapUtils.PolyLineType.fromCurrentPosition
            self.transportType = transportType
        }
    }
    
    fileprivate(set) var fromCurrentLocation: RouteFromCurrentLocation?
    
    fileprivate var routeDirectionCounter = 0
    
    weak fileprivate var routeDisplayInfos: RouteDisplayInfos!
    fileprivate var theMapView:MKMapView {
        get {
            return MapViewController.instance!.theMapView
        }
    }
    
    fileprivate var poiCallOutDelegate:PoiCalloutDelegate {
        get {
            return MapViewController.instance!.poiCalloutDelegate
        }
    }
    
    fileprivate var mapViewController:MapViewController {
        get {
            return MapViewController.instance!
        }
    }

    // MARK: Initializations
    
    /// Initialize a RouteManager
    ///
    /// - Parameters:
    ///   - route: Route that must be managed and displayed
    ///   - routeDisplay: interface that display the route overview and that must be refreshed
    ///   when the route is changed
    init(route:Route, routeDisplay:RouteDisplayInfos) {
        routeDatasource = RouteDataSource(route:route)
        routeDisplayInfos = routeDisplay
        super.init()
        subscribeRouteNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Route notifications
    fileprivate func subscribeRouteNotifications() {
        // Route notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RouteManager.directionForWayPointUpdated(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionForWayPointUpdated),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector:  #selector(RouteManager.directionsDone(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionsDone),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RouteManager.directionStarting(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionStarting),
                                               object: nil)
    }
    
    
    /// Called only when the direction must be computed. It set a flag
    /// to force to refresh the overlays... of the route when the directions will be computed
    /// and it displays a hud with the number of direction that must be resolved
    ///
    /// - Parameter notification: notification that has triggered the direction
    @objc func directionStarting(_ notification : Notification) {
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = NSLocalizedString("LoadingDirectionRouteManager", comment: "")
        
        routeDirectionCounter = routeDatasource.theRoute.routeToReloadCounter
        
        // DirectionStarting always provide a wayPoint as parameter
        if let userInfo = (notification as NSNotification).userInfo {
            let startingWayPoint = userInfo[Route.DirectionStartingParameters.startingWayPoint] as! WayPoint
            hudBaseView.subtitleLabel.text = "\(NSLocalizedString("FromRouteManager", comment: "")) \(startingWayPoint.wayPointPoi!.poiDisplayName!) 0/\(routeDirectionCounter)"
        }
    }
    
    
    /// Called when a part of the direction is available and can be displayed on the Map
    /// Add overlays on the Map based on the current position (when not in FMR and a new WayPoint is
    /// added the Map will contains 2 overlays, one for the previous wayPoint and one for the new one.
    /// the Old overlay will be removed in directionsDone() with removeAllOverlays
    /// It refreshes also the counter in the HUD (number of direction that must still be computed)
    ///
    /// - Parameter notification: notification that has triggered the direction update
    @objc func directionForWayPointUpdated(_ notification : Notification) {
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.subtitleLabel.text = "\(NSLocalizedString("FromRouteManager", comment: "")) \(routeDatasource.fromPOI!.poiDisplayName!) \(routeDirectionCounter - routeDatasource.theRoute.routeToReloadCounter)/\(routeDirectionCounter)"
        
        // FIXEDME: Maybe we should not add the overlays in this method? or we should find a better
        // way to see the progress when a new one is added
        addRouteOverlays()
        
        if !routeDatasource.isFullRouteMode {
            displayRouteMapRegion()
        }
        
        refreshRouteInfosOverview()
    }
    
    
    /// Called when the direction has been completed
    /// All route overlays are removed and they are displayed again
    /// to make sure displayed overlays reflect the position in the route
    ///
    /// - Parameter notification: notification that has triggered the direction update
    @objc func directionsDone(_ notification : Notification) {
        HUD.hide()
        // Even if the route is empty we need to refresh it if it's requested
        // because we could still have old overlays from a previous route...
        removeAllRouteOverlays()
        addRouteOverlays()
        
        refreshRouteInfosOverview()
        
        if let directionFailures = notification.userInfo?[Route.DirectionDoneParameters.directionFailures] as? [Route.RouteSegment],
            directionFailures.count > 0 {
            
            var errorMsg:String
            if directionFailures.count == 1 {
                let currentSegment = directionFailures.first
                errorMsg = String(format:NSLocalizedString("RouteDirectionFailure From %@ To %@", comment: ""),currentSegment!.fromWayPoint.wayPointPoi!.poiDisplayName!, currentSegment!.toWayPoint.wayPointPoi!.poiDisplayName!)
            } else {
                errorMsg = NSLocalizedString("RouteDirectionFailurePart1", comment: "")
                for currentSegment in directionFailures {
                    errorMsg += String(format:NSLocalizedString("RouteDirectionFailurePart2 From %@ To %@", comment: ""), currentSegment.fromWayPoint.wayPointPoi!.poiDisplayName!, currentSegment.toWayPoint.wayPointPoi!.poiDisplayName!)
                }
                errorMsg += NSLocalizedString("RouteDirectionFailurePart3", comment: "")
            }
            Utilities.showAlertMessage(MapViewController.instance!, title: NSLocalizedString("Warning", comment: ""), message:errorMsg)
        }
        
        if !routeDatasource.isFullRouteMode {
            displayRouteMapRegion()
        }
    }

    //MARK: public interface
    
    /// Put on the screen the view to display route infos
    /// Add all POIs used by the route and non filtered annotation on the Map
    func loadAndDisplayOnMap() {
        refreshRouteInfosOverview()
        
        // Warning: remove all POIs from the Route and then add them again
        // it's mandatory to reset the pin color and the content of the callout 
        // to have the right button to add/remove the POI from the route
        mapViewController.removeFromMap(pois: routeDatasource.pois)
        mapViewController.addOnMap(pois: routeDatasource.pois)

        // start to load the route asynchronously
        routeDatasource.theRoute.reloadDirections()
    }
    
    
    /// Remove all route overlays and hide the RouteInfos view from the Map
    func cleanup() {
        removeAllRouteOverlays()

        UIView.animate(withDuration: 0.5, animations: {
            self.routeDisplayInfos.hideRouteDisplay()
        }, completion: nil)
        
    }
    
    
    /// Called when a new WayPoint has been added in the Route
    /// It will start a reload of direction for the new WayPoint
    func reloadDirections() {
        routeDatasource.theRoute.reloadDirections()
    }
    
    /// Display the next, previous route section or the full route
    ///  - Annotations & Callouts will be refreshed appropriately
    ///  - Overlays will be refreshed to reflect the current route position
    ///
    /// - Parameter direction: direction to move on the route (forward, backward or all)
    func moveTo(direction:RouteSectionProgress) {
        if let oldFrom = routeDatasource.fromPOI,
            let oldTo = routeDatasource.toPOI {
            
            if let routeFromCurrentLocation = fromCurrentLocation {
                theMapView.remove(routeFromCurrentLocation.route.polyline)
                fromCurrentLocation = nil
            }
            
            // Remove the overlays currently displayed for the route before we go to the next section
            removeRouteOverlays()

            // Update From & To based on direction
            switch direction {
            case .forward: routeDatasource.moveToNextWayPoint()
            case .backward: routeDatasource.moveToPreviousWayPoint()
            case .all: routeDatasource.setFullRouteMode()
            }
            
            if let newFrom = routeDatasource.fromPOI,
                let newTo = routeDatasource.toPOI {
                
                showHUDForTransition()
                
                
                // Update the short infos based on new route section displayed
                refreshRouteInfosOverview()
                
                // Reset color of the old From only if it has really changed
                if oldFrom != newFrom {
                    refresh(poi:oldFrom)
                }
                
                // Reset color of the old To only if it has really changed
                // For the old To we need also to enable again the button to add the POI in the route
                if oldTo != newTo {
                    refresh(poi:oldTo)
                }
                
                refreshFromToAnnotations()
                
                // add the overlays to display the current route section (or the full route)
                addRouteOverlays()
                
                // Update the Map region based on the route section currently displayed
                displayRouteMapRegion()
            }
        }
    }

    // MARK: Route Display
    // Show information on Map (distance, duration...)
    // When at the beginning of the list we display a summary of the date (full distance, full travel duration...)
    // Else we display only infos related to the From/To (with some differences when the route from the user location is displayed)
    func refreshRouteInfosOverview() {
        routeDisplayInfos.refresh(datasource: routeDatasource)
    }

    func showWayPointIndex(_ index:Int) {
        if routeDatasource.isFullRouteMode {
            removeRouteOverlays()
        }
        
        routeDatasource.setFromWayPoint(wayPointIndex:index)
        moveTo(direction:.forward)
    }
    
    
    // Show the map based on the route currently displayed
    // - When a route section is displayed it zooms on the route section
    // - When the full route is displayed it zooms to display the full route...
    func displayRouteMapRegion() {
        if routeDatasource.isFullRouteMode {
            if let region = routeDatasource.theRoute.region {
                theMapView.setRegion(region, animated: true)
            }
        } else {
            if let routeFromCurrentLocation = fromCurrentLocation {
                self.theMapView.setRegion(routeFromCurrentLocation.region, animated: true)
            } else {
                let region = routeDatasource.fromWayPoint!.regionWith([routeDatasource.fromPOI!, routeDatasource.toPOI!])
                if let theRegion = region {
                    theMapView.setRegion(theRegion, animated: true)
                }

            }
        }
    }
    
    

    // MARK: Annotations & Overlays
    
    /// Remove all overlays of the route and 
    /// the overlay displaying the route from the current position (if displayed)
    func removeAllRouteOverlays() {
        theMapView.removeOverlays(routeDatasource.theRoute.polyLines)
       
        if let routeFromCurrentLocation = fromCurrentLocation {
            theMapView.remove(routeFromCurrentLocation.route.polyline)
            fromCurrentLocation = nil
        }
        
        // look if there're still polylines that should be removed (It can happens when the route is displayed on the Map
        // and the user delete it from the RoutesViewController -> The route is deleted from the database before it has 
        // been removed from the map, so we must still remove the related overlays from the Map)
        var polyLineToRemove = [MKPolyline]()
        for currentOverlay in theMapView.overlays {
            if let polyLine = currentOverlay as? MKPolyline {
                polyLineToRemove.append(polyLine)
            }
        }
        theMapView.removeOverlays(polyLineToRemove)
    }
    
    /// Remove the route overlays of the current position
    fileprivate func removeRouteOverlays() {
        if routeDatasource.isFullRouteMode {
            theMapView.removeOverlays(routeDatasource.theRoute.polyLines)
        } else {
            if let polyLine = routeDatasource.fromWayPoint?.routeInfos?.polyline {
                theMapView.remove(polyLine)
            }
        }
        if let routeFromCurrentLocation = fromCurrentLocation {
            theMapView.remove(routeFromCurrentLocation.route.polyline)
            fromCurrentLocation = nil
        }

    }

    /// Add the overlays for the Route based on routeDatasource
    /// - When the whole route is displayed all routes overlays are added on the Map
    /// - When a route section is displayed only the related overlay is added on the Map
    /// - When the route from current location is enabled then only this overlay is added on the Map
    func addRouteOverlays() {
        if routeDatasource.isFullRouteMode {
            // Add all overlays to show the full route
            theMapView.addOverlays(routeDatasource.theRoute.polyLines, level: .aboveRoads)
        } else {
            // Add either the route from the current position or the route between the From/To WayPoints
            if let theRoutePolyline = routeDatasource.fromWayPoint!.routeInfos?.polyline {
                theMapView.add(theRoutePolyline, level: .aboveRoads)
            }
            if let routeFromCurrentLocation = fromCurrentLocation {
                theMapView.add(routeFromCurrentLocation.route.polyline)
            }
        }
    }
    

    
    //MARK: Route update
    
    /// Add a Point of interest in the Route
    /// When we are in Full Route Mode, we request the user if the POI must be added at the start or end of the route
    /// else it's inserted at the current position
    ///
    /// - Parameter poi: The Point of interest to be added in the route
    func add(poi:PointOfInterest) {
        if routeDatasource.isFullRouteMode && !routeDatasource.wayPoints.isEmpty {
            
            // Request to the user if the POI must be added as the start or as the end of the route
            let alertActionSheet = UIAlertController(title: "\(NSLocalizedString("AddWayPointRouteManager", comment: "")) \(poi.poiDisplayName!)", message: NSLocalizedString("WhereRouteManager", comment: ""), preferredStyle: .actionSheet)
            alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("AsStartPointRouteManager", comment: ""), style: .default) { alertAction in
                self.insert(poi:poi, atPosition: .head)
                })
            alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("AsEndPointRouteManager", comment: ""), style: .default) { alertAction in
                self.insert(poi:poi, atPosition: .tail)
                })
            
            
            alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            mapViewController.present(alertActionSheet, animated: true, completion: nil)
            
        } else {
            // If it's the first WayPoint we are adding in the route, it becomes the head
            if routeDatasource.wayPoints.isEmpty {
                insert(poi:poi, atPosition: .head)
            } else {
                insert(poi:poi, atPosition: .currentPosition)
            }
        }
    }
    
    
    /// Change the Transport type for the section currently displayed (it can be a section
    /// from the route or a route from the current location
    ///
    /// - Parameter transportType: new transport type
    func set(transportType:MKDirectionsTransportType) {
        if let _ = fromCurrentLocation {
            setCurrentLocationRoute(withTransportType:transportType)
        } else {
            // Remove from the map the current overlay for the route section before the compute the new one
            // FIXEDME: Maybe it should be removed only when the new one has been successfully computed
            if let routeOverlay = routeDatasource.fromWayPoint?.routeInfos?.polyline {
                theMapView.remove(routeOverlay)
            }
            // Route will be automatically updated thanks to database notification
            routeDatasource.updateWith(transportType:transportType)
        }
    }
    
    
    /// Move a WayPoint from an index to another one
    ///
    /// - Parameters:
    ///   - sourceIndex: current index of the WayPoint in the route
    ///   - destinationIndex: index where the WayPoint must be moved in the route
    func moveWayPoint(sourceIndex: Int, destinationIndex:Int) {
        if sourceIndex != destinationIndex {
            routeDatasource.moveWayPoint(fromIndex:sourceIndex, toIndex: destinationIndex)
            
            // Refresh all Poi used by the Route -> Could be improved?
            for currentWayPoint in routeDatasource.wayPoints {
                refresh(poi:currentWayPoint.wayPointPoi!)
            }
        }
    }
    

    /// Delete a wayPoint located at given index from the route (called from RouteViewEditor)
    /// When the wayPoint has been removed the MapView is refreshed (POIs, Overlays...)
    ///
    /// - Parameter index: index of the wayPoint to be removed from the route
    func deleteWayPointAt(index:Int) {
        if routeDatasource.wayPoints.count > index {
            if routeDatasource.isFullRouteMode {
                let wayPointToDelete = routeDatasource.wayPoints[index]
                
                // overlays will be remove when directionDone() will be called
                
                // Keep in mind the from & to related to the deleted WayPoint
                let fromPoiToRefresh = wayPointToDelete.wayPointPoi!
                var toPoiToRefresh:PointOfInterest?
                
                // if we don't remove the latest WayPoint from the route
                if routeDatasource.toWayPoint != wayPointToDelete {
                    toPoiToRefresh = routeDatasource.wayPoints[index + 1].wayPointPoi
                } else {
                    // we remove the latest WayPoint from the route
                    if routeDatasource.wayPoints.count > 2 {
                        // the new toWayPoint will be WayPoint before the current latest
                        toPoiToRefresh = routeDatasource.wayPoints[index - 1].wayPointPoi
                    }
                }
                
                // Delete the WayPoint and update the indexes
                routeDatasource.delete(wayPoint:wayPointToDelete)
                
                // Refresh Poi annotations
                refresh(poi:fromPoiToRefresh)
                if let toPoi = toPoiToRefresh {
                    refresh(poi:toPoi)
                }
            } else {
                // It's exactly as if the user has selected on the Map an Annotation and selected deletion on the Callout
                removeAndRefreshRoute(poi:routeDatasource.wayPoints[index].wayPointPoi!)
            }
        }
    }
    
    /// This method is used when the remove POI from route has been selected from its callout
    /// When the POI is used several time in the route we request first the confirmation.
    ///
    /// When the POI is removed it triggers automatically a refresh and a recomputation of the route (when needed)
    ///
    /// - Parameter poi: Point of Interest to remove from the route
    func remove(poi:PointOfInterest) {
        if routeDatasource.occurencesOf(poi:poi) > 1 {
            // the POI is used several times in the route
            // If the full route is displayed or
            // if a section only is displayed and the Poi to remove is not the start / stop
            // we request user confirm the Poi must be fully removed from the route
            if routeDatasource.isFullRouteMode ||
                (routeDatasource.fromPOI != poi && routeDatasource.toPOI != poi) {
                let alertActionSheet = UIAlertController(title: NSLocalizedString("Warning", comment: ""), message: "\(poi.poiDisplayName!) \(NSLocalizedString("POIUsedSeveralTimesDoWeDeleteItRouteManager", comment: ""))", preferredStyle: .alert)
                alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default) {  alertAction in
                    
                    self.removeAndRefreshRoute(poi:poi)
                })
                
                mapViewController.present(alertActionSheet, animated: true, completion: nil)
            } else {
                removeAndRefreshRoute(poi:poi)
            }
        } else {
            removeAndRefreshRoute(poi:poi)
        }
    }
    
    /// Remove the given Poi from the route and refresh the Map display
    ///
    /// - Parameter poi: Point of interest to remove from the Route
    fileprivate func removeAndRefreshRoute(poi:PointOfInterest) {
        var needRefreshAnnotationFromTo = false
        
        // No need to remove overlay because the route overlays will be refreshed in directionDone()
     
        // If the POI to be removed is the from or to, it means the from or to will
        // change after its removal and we will have to refresh the new From/To
        if poi === routeDatasource.fromPOI || poi === routeDatasource.toPOI {
            needRefreshAnnotationFromTo = true
        }
        
        // Remove the Poi from the datasource
        // The From/To can be different after this call
        routeDatasource.deleteWayPointsWith(poi: poi)
        
        // Update the removed Poi on the Map (Pin annotation & callout)
        refresh(poi:poi)
        
        if needRefreshAnnotationFromTo {
            refreshFromToAnnotations()
        }
        
        // If there's no route section, we go back to route start
        if routeDatasource.theRoute.wayPoints.count == 1 {
            moveTo(direction:.all)
        }
    }
    
    
    /// Add the POI in the route at the given position. Annotations are refreshed on the Map
    ///
    /// - Parameters:
    ///   - poi: Point of interest to be added in the route
    ///   - atPosition: Position where the POI must be inserted in the route (head, tail or current position)
    fileprivate func insert(poi:PointOfInterest, atPosition:InsertPoiPostion) {
        
        switch atPosition {
        case .head: // Only when the whole route is displayed
            if let currentStartPoi = routeDatasource.fromPOI {
                // The old starting WayPoint is changed to end if the route has only 1 wayPoint
                // else it becomes a simple wayPoint of the route
                if routeDatasource.theRoute.wayPoints.count == 1 {
                    refreshAnnotation(poi:currentStartPoi, withType: .routeEnd)
                } else {
                    refreshAnnotation(poi:currentStartPoi, withType: .waypoint)
                }
            }
            
            // The new wayPoint is inserted at the start
            routeDatasource.insertAsRouteStart(poi:poi)
            refreshAnnotation(poi:poi, withType: .routeStart)
            
        case .tail: // Only when the whole route is displayed

            // We first check if the WayPoint before the new .tail is the start of the route
            // because we will have to refresh it
            var fromType = MapUtils.PinAnnotationType.waypoint
            let fromPoi = routeDatasource.toPOI
            if let _ = fromPoi {
                fromType = routeDatasource.theRoute.wayPoints.count == 1 ? .routeStart : .waypoint
            }
            
            // The new wayPoint is added at the end
            routeDatasource.insertAsRouteEnd(poi:poi)
            
            // Refresh the fromPoi of the new .tail
            // It must be done after the new POI has been added in the route
            // else the start of the route could not be correctly refreshed
            // FIXEDME: Maybe we should pass the Full routeDatasource to avoid pb during the refresh???
            if let theFromPoi = fromPoi {
                refreshAnnotation(poi: theFromPoi, withType: fromType)
            }
            
            refreshAnnotation(poi:poi, withType: .routeEnd)
            
        case .currentPosition: // Only when only a route section is displayed
            if let currentStartPoi = routeDatasource.fromPOI {
                // The old start becomes the simple wayPoint from the route
                refreshAnnotation(poi:currentStartPoi, withType: .waypoint)
            }
            
            if let currentEndPoi = routeDatasource.toPOI {
                // the old ending waypoint is changed to become the start
                refreshAnnotation(poi:currentEndPoi, withType: .routeStart)
            }
            
            // The new wayPoint is added at the end of the new route section
            routeDatasource.append(poi:poi)
            refreshAnnotation(poi:poi, withType: .routeEnd)
        }
    }

    // MARK: Route from current location
    
    // - Remove the overlay that displays the route from the current location
    // - Reset some flags
    // - Update the Summary infos
    // - Change the Map bounding box to display the current route section
    func removeRouteFromCurrentLocation() {
        
        if let routeFromCurrentLocation = fromCurrentLocation {
            theMapView.remove(routeFromCurrentLocation.route.polyline)
            fromCurrentLocation = nil
        }
  
        refreshRouteInfosOverview()
        displayRouteMapRegion()
    }

    // - Add the Polyline overlay to display the route from the current location
    // - Update the Summary infos
    // - Change the Map bounding box to display the whole route
    fileprivate func displayRouteFromCurrentLocation(route:MKRoute, toPOI:PointOfInterest, withTransportType:MKDirectionsTransportType = .automobile) {
        if let routeFromCurrentLocation = fromCurrentLocation {
            theMapView.remove(routeFromCurrentLocation.route.polyline)
        }
        
        fromCurrentLocation = RouteFromCurrentLocation(poi: toPOI, route: route, transportType: withTransportType)
        theMapView.add(fromCurrentLocation!.route.polyline)
        
        refreshRouteInfosOverview()
        displayRouteMapRegion()
    }
    
    /// Request the route from the current location to target POI. When the route is computed it's displayed on the map
    ///
    /// - Parameters:
    ///   - targetPOI: Destination of the route
    ///   - transportType: transport to be used for the route computation (walk, automobile...)
    func addRouteFromCurrentLocation(targetPOI: PointOfInterest, transportType:MKDirectionsTransportType) {
        // If a route from current location is already displayed, we first remove it
        // before to compute the new one
        if let routeFromCurrentLocation = fromCurrentLocation {
            let poiToRefresh = routeFromCurrentLocation.toPOI
            removeRouteFromCurrentLocation()
            
            // refresh the callout that was the previous target of the "route from current location"
            if let annotationView = mapViewController.theMapView.view(for: poiToRefresh) as? WayPointPinAnnotationView {
                var wayPointType = MapUtils.PinAnnotationType.routeEnd
                if poiToRefresh === routeDatasource.fromPOI {
                    wayPointType = .routeStart
                }
                MapUtils.refreshPin(annotationView, poi: poiToRefresh, delegate: poiCallOutDelegate, type: wayPointType)
            }
        }
        
        let routeRequest = MKDirectionsRequest()
        routeRequest.transportType = transportType
        routeRequest.source = MKMapItem.forCurrentLocation()
        routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: targetPOI.coordinate, addressDictionary: nil))
        
        // Display a HUD while loading the route
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text =  NSLocalizedString("LoadingDirectionRouteManager", comment: "")
        hudBaseView.subtitleLabel.text = NSLocalizedString("FromCurrentLocationRouteManager", comment: "")
        
        // ask the direction
        let routeDirections = MKDirections(request: routeRequest)
        routeDirections.calculate { routeResponse, routeError in
            HUD.hide()
            if let error = routeError {
                Utilities.showAlertMessage(self.mapViewController, title:NSLocalizedString("Warning", comment: ""), error: error)
                self.fromCurrentLocation = nil

            } else {
                // Get the first route direction from the response
                if let firstRoute = routeResponse?.routes[0] {
                    self.displayRouteFromCurrentLocation(route:firstRoute, toPOI:targetPOI)
                } else {
                    self.fromCurrentLocation = nil

                }
            }
        }
    }
    
    
    /// Called when the user change the transport type for the route from current location
    ///
    /// - Parameter withTransportType: the new transport type (car, walk...)
    fileprivate func setCurrentLocationRoute(withTransportType:MKDirectionsTransportType) {
        if let toPoi = routeDatasource.toPOI {
            let routeRequest = MKDirectionsRequest()
            routeRequest.transportType = withTransportType
            routeRequest.source = MKMapItem.forCurrentLocation()
            routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: toPoi.coordinate, addressDictionary: nil))
            
            // Display a HUD while loading the route
            PKHUD.sharedHUD.dimsBackground = true
            HUD.show(.progress)
            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
            hudBaseView.titleLabel.text =  NSLocalizedString("LoadingDirectionRouteManager", comment: "")
            hudBaseView.subtitleLabel.text = NSLocalizedString("FromCurrentLocationRouteManager", comment: "")
            
            // ask the direction
            let routeDirections = MKDirections(request: routeRequest)
            routeDirections.calculate { routeResponse, routeError in
                HUD.hide()
                if let error = routeError {
                    Utilities.showAlertMessage(self.mapViewController, title:NSLocalizedString("Warning", comment: ""), error: error)
                    self.fromCurrentLocation = nil

                } else {
                    // Get the first route direction from the response
                    if let firstRoute = routeResponse?.routes[0] {
                        self.displayRouteFromCurrentLocation(route:firstRoute, toPOI: toPoi, withTransportType: withTransportType)
                    } else {
                        self.fromCurrentLocation = nil
                    }
                }
            }
        }
    }

    
    //MARK: Refresh POI
    fileprivate func refreshAnnotation(poi:PointOfInterest, withType:MapUtils.PinAnnotationType) {
        if let annotationView = theMapView.view(for: poi) as? WayPointPinAnnotationView {
            MapUtils.refreshPin(annotationView, poi: poi, delegate: poiCallOutDelegate, type: withType)
        }
    }

    fileprivate func refreshFromToAnnotations() {
        if let from = routeDatasource.fromPOI {
            refresh(poi:from)
            if let to = routeDatasource.toPOI , to != from {
                refresh(poi:to)
            }
        }
    }
    
    // Refresh a Poi depending on its role in the Map
    func refresh(poi:PointOfInterest) {
        if let annotationView = theMapView.view(for: poi) as? WayPointPinAnnotationView {
            let poiType = getPinType(poi: poi)
            MapUtils.refreshPin(annotationView, poi: poi, delegate: poiCallOutDelegate, type: poiType)
            
            // Specific case when the route contains only the From then we must not set the
            // Add Way Point accessory
            if poiType == .routeStart && routeDatasource.wayPoints.count == 1 {
                annotationView.disableAddWayPointAccessory()
            }
        }
    }

    // Get the role of a POI in the Route (start/end/wayPoint/normal)?
    func getPinType(poi:PointOfInterest) -> MapUtils.PinAnnotationType {
        var poiType = MapUtils.PinAnnotationType.normal
        if poi === routeDatasource.fromPOI {
            poiType = .routeStart
            // === The Poi is displayed as the From
        } else if poi === routeDatasource.toPOI {
            // === The Poi is displayed as the To
            poiType = .routeEnd
        } else {
            if routeDatasource.contains(poi:poi) {
                // === The Poi is part of the route but currently its WayPoint is not displayed
                poiType = .waypoint
            }
        }
        
        return poiType
    }

    fileprivate func showHUDForTransition() {
        PKHUD.sharedHUD.dimsBackground = false
        
        HUD.flash(.label(routeDatasource.routeName), delay:1.0) { _ in
            // Don't select the annotation because the callout may move the Map region, which is not nice
            //    self.theMapView.selectAnnotation(self.routeDatasource.fromPOI!, animated: true)
        }
    }
}
