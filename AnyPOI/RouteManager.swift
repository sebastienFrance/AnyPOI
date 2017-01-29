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
    func refreshRouteOverlays()
    func displayOnMap(groups:[GroupOfInterest], withMonitoredOverlays:Bool)
}

class RouteManager: NSObject {
    let routeDatasource:RouteDataSource

    enum RouteSectionProgress {
        case forward, backward, all
    }
    
    fileprivate(set) var routeFromCurrentLocation : MKRoute?
    fileprivate(set) var isRouteFromCurrentLocationDisplayed = false
    fileprivate var routeDirectionCounter = 0
    fileprivate var hasRouteChangedDueToReloading = false
    
    weak fileprivate var routeDisplayInfos: RouteDisplayInfos!
    //weak fileprivate var theMapView:MKMapView!
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
    
    fileprivate var mapViewController:UIViewController {
        get {
            return MapViewController.instance!
        }
    }

    // MARK: Initializations
    init(datasource:RouteDataSource, routeDisplay:RouteDisplayInfos) {
        routeDatasource = datasource
        routeDisplayInfos = routeDisplay
        super.init()
        subscribeRouteNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("Deinit for RouteManager")
    }
    
    func loadAndDisplayOnMap() {
        displayRouteInfos()
        
        // Add route Annotations
        theMapView.removeAnnotations(theMapView.annotations)
        theMapView.addAnnotations(routeDatasource.pois)
        
        routeDisplayInfos.displayOnMap(groups:POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: false)

        hasRouteChangedDueToReloading = true // Force the display of the Route even if no changes
        routeDatasource.theRoute.reloadDirections() // start to load the route
        
        // Initialization of the Map must be done only when the view is ready.
        if let region = routeDatasource.theRoute.region {
            // Don't change the MapView if we have only one wayPoint
            if routeDatasource.wayPoints.count > 1 {
                theMapView.setRegion(region, animated: true)
            }
        }
    }
    
    func cleanup() {
        removeRouteOverlays()
        //theMapView.removeAnnotations(theMapView.annotations)

        UIView.animate(withDuration: 0.5, animations: {
            self.routeDisplayInfos.hideRouteDisplay()
        }, completion: nil)
        
    }
    
    func reloadDirections() {
        hasRouteChangedDueToReloading = false
        routeDatasource.theRoute.reloadDirections()
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
    
    func directionStarting(_ notification : Notification) {
        hasRouteChangedDueToReloading = true
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
    
    func directionForWayPointUpdated(_ notification : Notification) {
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.subtitleLabel.text = "\(NSLocalizedString("FromRouteManager", comment: "")) \(routeDatasource.fromPOI!.poiDisplayName!) \(routeDirectionCounter - routeDatasource.theRoute.routeToReloadCounter)/\(routeDirectionCounter)"
        
        routeDisplayInfos.refreshRouteOverlays()
        displayRouteInfos()
    }
    
    func directionsDone(_ notification : Notification) {
        HUD.hide()
        // Even if the route is empty we need to refresh it if it's requested
        // because we could still have old overlays from a previous route...
        if hasRouteChangedDueToReloading {
            routeDisplayInfos.refreshRouteOverlays()
            displayRouteInfos()
            displayRouteMapRegion()
        }
    }
    
    // Display the next, previous route section or the full route
    //  - Annotations & Callouts will be refreshed appropriately
    //  - Overlays will be refreshed to reflect the current route position
    func moveTo(direction:RouteSectionProgress) {
        if let oldFrom = routeDatasource.fromPOI,
            let oldTo = routeDatasource.toPOI {
            
            // Update From & To based on direction
            switch direction {
            case .forward: routeDatasource.moveToNextWayPoint()
            case .backward: routeDatasource.moveToPreviousWayPoint()
            case .all: routeDatasource.setFullRouteMode()
            }
            
            if let newFrom = routeDatasource.fromPOI,
                let newTo = routeDatasource.toPOI {
                
                showHUDForTransition()
                
                // Remove Overlay for from current location
                isRouteFromCurrentLocationDisplayed = false
                
                // Update the short infos based on new route section displayed
                displayRouteInfos()
                
                // Reset color of the old From only if it has really changed
                if oldFrom != newFrom {
                    refresh(poi:oldFrom)
                }
                
                // Reset color of the old To only if it has really changed
                // For the old To we need also to enable again the button to add the POI in the route
                if oldTo != newTo {
                    refresh(poi:oldTo)
                }
                
                refreshAnnotationsForCurrentWayPoint()
                
                // Remove all route overlays currently displayed and add the new ones
                removeRouteOverlays()
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
    func displayRouteInfos() {
        routeDisplayInfos.refresh(datasource: routeDatasource)
    }

    func showWayPointIndex(_ index:Int) {
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
            if !isRouteFromCurrentLocationDisplayed {
                let region = routeDatasource.fromWayPoint!.regionWith([routeDatasource.fromPOI!, routeDatasource.toPOI!])
                if let theRegion = region {
                    theMapView.setRegion(theRegion, animated: true)
                }
            } else {
                var (topLeft, bottomRight) = MapUtils.boundingBoxForAnnotationsNew([routeDatasource.fromPOI!, routeDatasource.toPOI!])
                (topLeft, bottomRight) = MapUtils.extendBoundingBox(topLeft, bottomRightCoord: bottomRight, multiPointOverlay: routeFromCurrentLocation!.polyline)
                let region = MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
                self.theMapView.setRegion(region, animated: true)
            }
        }
    }
    
    func executeAction() {
        let mailActivity = RouteMailActivityItemSource(datasource:routeDatasource)
        let GPXactivity = GPXActivityItemSource(route: [routeDatasource.theRoute])
        var activityItems:[UIActivityItemSource] = [mailActivity, GPXactivity]
        
        if let image = MapViewController.instance!.mapImage() {
            let imageActivity = ImageAcvitityItemSource(image: image)
             activityItems.append(imageActivity)
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                    UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                    UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                    UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo, UIActivityType.message]
        
        MapViewController.instance!.present(activityController, animated: true, completion: nil)
    }
    

    // MARK: Annotations & Overlays
    // Remove from the map all overlays used to display the route
    // FIXEDME: 😡😡⚡️⚡️ Should be improved
    fileprivate func removeRouteOverlays() {
        var overlaysToRemove = [MKOverlay]()
        for currentOverlay in theMapView.overlays {
            if currentOverlay is MKPolyline {
                overlaysToRemove.append(currentOverlay)
            }
        }
        
        theMapView.removeOverlays(overlaysToRemove)
    }

    // Add the overlays for the Route based on routeDatasource
    // - When the whole route is displayed all routes overlays are added on the Map
    // - When a route section is displayed only the related overlay is added on the Map
    // - When the route from current location is enabled then only this overlay is added on the Map
    func addRouteOverlays() {
        if routeDatasource.isFullRouteMode {
            // Add all overlays to show the full route
            theMapView.addOverlays(routeDatasource.theRoute.polyLines, level: .aboveRoads)
        } else {
            // Add either the route from the current position or the route between the From/To WayPoints
            if let theRoutePolyline = routeDatasource.fromWayPoint!.routeInfos?.polyline {
                theMapView.add(theRoutePolyline, level: .aboveRoads)
            }
            if isRouteFromCurrentLocationDisplayed {
                theMapView.add(routeFromCurrentLocation!.polyline)
            }
        }
    }
    

    
    //MARK: Route update
    // User has requested to add a POI in the route
    // It can be triggered by the user from the Callout, when creating a new POI on the Map, when using Route Editor
    //
    // This method create a new WayPoint for this POI in the route
    // When the new WayPoint is inserted, it will automatically trigger a route loading
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
    
    func setTransportType(_ transportType:MKDirectionsTransportType) {
        if !isRouteFromCurrentLocationDisplayed {
            // Route will be automatically update thanks to database notification
            routeDatasource.updateWith(transportType:transportType)
        } else {
            addRouteFromCurrentLocation(withTransportType:transportType)
        }
        
    }
    
    func moveWayPoint(sourceIndex: Int, destinationIndex:Int) {
        routeDatasource.moveWayPoint(fromIndex:sourceIndex, toIndex: destinationIndex)
        
        // Refresh all Poi used by the Route -> Could be improved?
        for currentWayPoint in routeDatasource.wayPoints {
            refresh(poi:currentWayPoint.wayPointPoi!)
        }
    }
    

    func deleteWayPointAt(_ index:Int) {
        if routeDatasource.wayPoints.count > index {
            if routeDatasource.isFullRouteMode {
                let wayPointToDelete = routeDatasource.wayPoints[index]
                
                // Remove the overlay of the deleted WayPoint
                if let overlayToRemove = wayPointToDelete.routeInfos?.polyline {
                    theMapView.remove(overlayToRemove)
                } else {
                    // When there is no overlay it probably means it's the latest WayPoint we want to delete
                    // In this case we need to get the overlay where this WayPoint is the target and to delete it
                    if routeDatasource.wayPoints.count >= 2,
                        let overlayToRemove = routeDatasource.wayPoints[index - 1].routeInfos?.polyline {
                        theMapView.remove(overlayToRemove)
                    }
                }
                
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
    
    // Delete from the route the POI with a selected annotation on the Map
    // Dialog box is opened to request confirmation when the Poi is used by several route sections
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
    
    // Remove the given Poi from the route and refresh the Map display
    //  - WayPoint overlay is removed
    //  - Poi is removed from route data source
    //  - To & From annotations are refreshed
    //  - If required, we display the full route
    fileprivate func removeAndRefreshRoute(poi:PointOfInterest) {
        var needToRefreshCurrentRouteSection = false
        // If the POI is used to display the current WayPoint we remove its overlay
        
        //FIXEDME: Error, when we are in FR Mode we must not delete the overlay from the fromWayPoint because
        // in this mode the fromWayPoint is the start of the route and not the segment we want to remove (which can 
        // be anywhere in the route (start, middle, end...)
        if poi === routeDatasource.fromPOI || poi === routeDatasource.toPOI,
            let overlayToRemove = routeDatasource.fromWayPoint?.routeInfos?.polyline {
            theMapView.remove(overlayToRemove)
            needToRefreshCurrentRouteSection = true
        }
        
        // Remove the Poi from the datasource
        routeDatasource.deleteWayPointsWith(poi: poi)
        
        // Update the removed Poi on the Map (Pin annotation & callout)
        //refreshPoiRemovedFromRoute(poi)
        refresh(poi:poi)
        
        if needToRefreshCurrentRouteSection {
            refreshAnnotationsForCurrentWayPoint()
        }
        
        // If there's no route section, we go back to route start
        if routeDatasource.theRoute.wayPoints.count == 1 {
            moveTo(direction:.all)
        }
    }
    
    fileprivate func insert(poi:PointOfInterest, atPosition:MapViewController.InsertPoiPostion) {
        
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
        isRouteFromCurrentLocationDisplayed = false
        
        if let overlayFromCurrentLocation = routeFromCurrentLocation?.polyline {
            theMapView.remove(overlayFromCurrentLocation)
        }
        routeFromCurrentLocation = nil
        
        displayRouteInfos()
        displayRouteMapRegion()
    }

    // - Add the Polyline overlay to display the route from the current location
    // - Update the Summary infos
    // - Change the Map bounding box to display the whole route
    fileprivate func displayRouteFromCurrentLocation(_ route:MKRoute) {
        if let oldRoute = routeFromCurrentLocation {
            theMapView.remove(oldRoute.polyline)
        }
        routeFromCurrentLocation = route
        routeFromCurrentLocation?.polyline.title = MapUtils.PolyLineType.fromCurrentPosition
        isRouteFromCurrentLocationDisplayed = true
        
        theMapView.add(routeFromCurrentLocation!.polyline)
        
        displayRouteInfos()
        displayRouteMapRegion()
    }
    
    // Request the route from the current location to target of the current route section
    func buildRouteFromCurrentLocationTo(targetPOI: PointOfInterest, transportType:MKDirectionsTransportType) {
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
                self.isRouteFromCurrentLocationDisplayed = false
            } else {
                // Get the first route direction from the response
                if let firstRoute = routeResponse?.routes[0] {
                    self.displayRouteFromCurrentLocation(firstRoute)
                } else {
                    self.isRouteFromCurrentLocationDisplayed = false
                }
            }
        }
    }
    
    fileprivate func addRouteFromCurrentLocation(withTransportType:MKDirectionsTransportType) {
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
                    self.isRouteFromCurrentLocationDisplayed = false
                } else {
                    // Get the first route direction from the response
                    if let firstRoute = routeResponse?.routes[0] {
                        self.displayRouteFromCurrentLocation(firstRoute)
                    } else {
                        self.isRouteFromCurrentLocationDisplayed = false
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

    fileprivate func refreshAnnotationsForCurrentWayPoint() {
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
            self.theMapView.selectAnnotation(self.routeDatasource.fromPOI!, animated: true)
        }
    }
}
