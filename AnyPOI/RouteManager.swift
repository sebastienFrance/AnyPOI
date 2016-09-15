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
    func displayRouteEmptyInfos()
    func displayRouteSummaryInfos(datasource:RouteDataSource)
    func displayRouteWayPointsInfos(datasource:RouteDataSource)
    func hideRouteDisplay()
   
    func doFlyover(routeDatasource:RouteDataSource)
    
    func refreshRouteAllOverlays()
    func displayNewGroupsOnMap(groups:[GroupOfInterest], withMonitoredOverlays:Bool)
    
    
    func getViewController() -> UIViewController
    func getPoiCalloutDelegate() -> PoiCalloutDelegate
}

class RouteManager: NSObject {
    
    private(set) var routeFromCurrentLocation : MKRoute?
    private(set) var isRouteFromCurrentLocationDisplayed = false
    private var isShowOnlyRouteAnnotations = false
    let routeDatasource:RouteDataSource!
    private var routeDirectionCounter = 0
    
    weak private var routeDisplayInfos: RouteDisplayInfos!
    weak private var theMapView:MKMapView!

    // MARK: Initializations
    init(datasource:RouteDataSource, routeDisplay:RouteDisplayInfos, mapView:MKMapView) {
        routeDatasource = datasource
        routeDisplayInfos = routeDisplay
        theMapView = mapView
        super.init()
        subscribeRouteNotifications()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("Deinit for RouteManager")
    }
    
    func loadAndDisplayOnMap() {
        displayRouteInfos()
        
        // Add route Annotations
        theMapView.removeAnnotations(theMapView.annotations)
        if let poisToBeAdded = routeDatasource?.pois {
            theMapView.addAnnotations(poisToBeAdded)
        }
        
        routeDisplayInfos.displayNewGroupsOnMap(POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: false)

        
        routeDatasource.theRoute.reloadDirections() // start to load the route
        
        // Initialization of the Map must be done only when the view is ready.
        if let region = routeDatasource?.theRoute.region {
            // Don't change the MapView if we have only one wayPoint
            if routeDatasource.wayPoints.count > 1 {
                theMapView.setRegion(region, animated: true)
            }
        }
    }
    
    func cleanup() {
        removeRouteOverlays()
        theMapView.removeAnnotations(theMapView.annotations)

        UIView.animateWithDuration(0.5, animations: {
            self.routeDisplayInfos.hideRouteDisplay()
        }, completion: nil)
        
//        for currentWayPoint in routeDatasource.theRoute.wayPoints {
//            currentWayPoint.calculatedRoute = nil
//        }
    }
    
    func reloadDirections() {
        routeDatasource.theRoute.reloadDirections()
    }
    
    //MARK: Route notifications
    private func subscribeRouteNotifications() {
        // Route notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RouteManager.directionForWayPointUpdated(_:)),
                                                         name: Route.Notifications.directionForWayPointUpdated,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:  #selector(RouteManager.directionsDone(_:)),
                                                         name: Route.Notifications.directionsDone,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RouteManager.directionStarting(_:)),
                                                         name: Route.Notifications.directionStarting,
                                                         object: nil)
    }
    
    func directionStarting(notification : NSNotification) {
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.Progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = "Loading directions"
        
        routeDirectionCounter = routeDatasource.theRoute.routeToReloadCounter
        
        // DirectionStarting always provide a wayPoint as parameter
        if let userInfo = notification.userInfo {
            let startingWayPoint = userInfo[Route.DirectionStartingParameters.startingWayPoint] as! WayPoint
            hudBaseView.subtitleLabel.text = "From \(startingWayPoint.wayPointPoi!.poiDisplayName!) 0/\(routeDirectionCounter)"
        }
    }
    
    func directionForWayPointUpdated(notification : NSNotification) {
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.subtitleLabel.text = "From \(routeDatasource.fromPOI!.poiDisplayName!) \(routeDirectionCounter - routeDatasource.theRoute.routeToReloadCounter)/\(routeDirectionCounter)"
        
        routeDisplayInfos.refreshRouteAllOverlays()
        displayRouteInfos()
    }
    
    func directionsDone(notification : NSNotification) {
        if routeDatasource.wayPoints.count > 1 {
            HUD.hide()
            routeDisplayInfos.refreshRouteAllOverlays()
            displayRouteInfos()
            displayRouteMapRegion()
        }
    }
    
    // Display the next, previous route section or the full route
    //  - Annotations & Callouts will be refreshed appropriately
    //  - Overlays will be refreshed to reflect the current route position
    func displayRouteSection(direction:MapViewController.RouteSectionProgress) {
        if let oldFrom = routeDatasource.fromPOI,
            oldTo = routeDatasource.toPOI {
            
            // Update From & To based on direction
            switch direction {
            case .forward: routeDatasource.moveToNextWayPoint()
            case .backward: routeDatasource.moveToPreviousWayPoint()
            case .all: routeDatasource.showAllRoute()
            }
            
            if let newFrom = routeDatasource.fromPOI,
                newTo = routeDatasource.toPOI {
                
                showHUDForTransition()
                
                // Remove Overlay for from current location
                isRouteFromCurrentLocationDisplayed = false
                
                // Update the short infos based on new route section displayed
                displayRouteInfos()
                
                // Reset color of the old From only if it has really changed
                if oldFrom != newFrom {
                    refreshPoiAnnotation(oldFrom)
                }
                
                // Reset color of the old To only if it has really changed
                // For the old To we need also to enable again the button to add the POI in the route
                if oldTo != newTo {
                    refreshPoiAnnotation(oldTo)
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
        if routeDatasource.wayPoints.isEmpty {
            routeDisplayInfos.displayRouteEmptyInfos()
        } else if routeDatasource.isBeforeRouteSections {
            routeDisplayInfos.displayRouteSummaryInfos(routeDatasource)
        } else {
            routeDisplayInfos.displayRouteWayPointsInfos(routeDatasource)
        }
        
    }

    func showWayPointIndex(index:Int) {
        routeDatasource.setCurrentWayPoint(index)
        displayRouteSection(.forward)
    }
    
    
    // Show the map based on the route currently displayed
    // - When a route section is displayed it zooms on the route section
    // - When the full route is displayed it zooms to display the full route...
    func displayRouteMapRegion() {
        if routeDatasource.isBeforeRouteSections {
            if let region = routeDatasource.theRoute.region {
                //let regionThatFits = theMapView.regionThatFits(region)
                theMapView.setRegion(region, animated: UserPreferences.sharedInstance.mapAnimations)
            }
        } else {
            if !isRouteFromCurrentLocationDisplayed {
                let region = routeDatasource.fromWayPoint!.regionWith([routeDatasource.fromPOI!, routeDatasource.toPOI!])
                if let theRegion = region {
                    theMapView.setRegion(theRegion, animated: UserPreferences.sharedInstance.mapAnimations)
                }
            } else {
                var (topLeft, bottomRight) = MapUtils.boundingBoxForAnnotationsNew([routeDatasource.fromPOI!, routeDatasource.toPOI!])
                (topLeft, bottomRight) = MapUtils.extendBoundingBox(topLeft, bottomRightCoord: bottomRight, multiPointOverlay: routeFromCurrentLocation!.polyline)
                let region = MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
                self.theMapView.setRegion(region, animated: UserPreferences.sharedInstance.mapAnimations)
            }
        }
    }
    

    // MARK: Annotations & Overlays
    // Remove from the map all overlays used to display the route
    // FIXEDME: 😡😡⚡️⚡️ Should be improved
    private func removeRouteOverlays() {
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
        if routeDatasource.isBeforeRouteSections {
            // Add all overlays to show the full route
            theMapView.addOverlays(routeDatasource.theRoute.polyLines, level: .AboveRoads)
        } else {
            // Add either the route from the current position or the route between the From/To WayPoints
            if let theRoute = routeDatasource.fromWayPoint!.calculatedRoute {
                theMapView.addOverlay(theRoute.polyline, level: .AboveRoads)
            }
            if isRouteFromCurrentLocationDisplayed {
                theMapView.addOverlay(routeFromCurrentLocation!.polyline)
            }
        }
    }
    
    
    func showOnlyRouteAnnotations() {
        isShowOnlyRouteAnnotations = !isShowOnlyRouteAnnotations
        
        if isShowOnlyRouteAnnotations {
            // Remove all annotations which are not used in the route
            var annotationsToRemove = [MKAnnotation]()
            for currentAnnotation in theMapView.annotations {
                if currentAnnotation is PointOfInterest && !routeDatasource.hasPoi(currentAnnotation as! PointOfInterest) {
                    annotationsToRemove.append(currentAnnotation)
                }
            }
            theMapView.removeAnnotations(annotationsToRemove)
        } else {
            // Add all annotations
            if isShowOnlyRouteAnnotations == false {
                routeDisplayInfos.displayNewGroupsOnMap(POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: false)
            }
        }
        
    }
    
    //MARK: Route update
    // User has requested to add a POI in the route
    // It can be triggered by the user from the Callout, when creating a new POI on the Map, when using Route Editor
    //
    // This method create a new WayPoint for this POI in the route
    // When the new WayPoint is inserted, it will automatically trigger a route loading
    func addPoiToTheRoute(poi:PointOfInterest) {
        if routeDatasource.isBeforeRouteSections && !routeDatasource.wayPoints.isEmpty {
            
            // Request to the user if the POI must be added as the start or as the end of the route
            let alertActionSheet = UIAlertController(title: "Add \(poi.poiDisplayName!)", message: "Where ?", preferredStyle: .ActionSheet)
            alertActionSheet.addAction(UIAlertAction(title: "As starting point", style: .Default) { alertAction in
                self.insertPoiInRoute(poi, atPosition: .head)
                })
            alertActionSheet.addAction(UIAlertAction(title: "As end point", style: .Default) { alertAction in
                self.insertPoiInRoute(poi, atPosition: .tail)
                })
            
            
            alertActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            routeDisplayInfos.getViewController().presentViewController(alertActionSheet, animated: true, completion: nil)
            
        } else {
            // If it's the first WayPoint we are adding in the route, it becomes the head
            if routeDatasource.wayPoints.isEmpty {
                insertPoiInRoute(poi, atPosition: .head)
            } else {
                insertPoiInRoute(poi, atPosition: .currentPosition)
            }
        }
    }
    
    func setTransportType(transportType:MKDirectionsTransportType) {
        if !isRouteFromCurrentLocationDisplayed {
            // Route will be automatically update thanks to database notification
            routeDatasource.updateTransportTypeFromWayPoint(transportType)
        } else {
            buildRouteFromCurrentLocation(transportType)
        }
        
    }
    
    func moveWayPoint(sourceIndex: Int, destinationIndex:Int) {
        routeDatasource.moveWayPoint(sourceIndex, toIndex: destinationIndex)
        
        // Refresh all Poi used by the Route -> Could be improved?
        for currentWayPoint in routeDatasource.wayPoints {
            refreshPoiAnnotation(currentWayPoint.wayPointPoi!)
        }
        
    }
    

    func deleteWayPointAt(index:Int) {
        if routeDatasource.wayPoints.count > index {
            if routeDatasource.isBeforeRouteSections {
                let wayPointToDelete = routeDatasource.wayPoints[index]
                
                // Remove the overlay of the deleted WayPoint
                if let overlayToRemove = wayPointToDelete.calculatedRoute?.polyline {
                    theMapView.removeOverlay(overlayToRemove)
                } else {
                    // When there is no overlay it probably means it's the latest WayPoint we want to delete
                    // In this case we need to get the overlay where this WayPoint is the target and to delete it
                    if routeDatasource.wayPoints.count >= 2,
                        let overlayToRemove = routeDatasource.wayPoints[index - 1].calculatedRoute?.polyline {
                        theMapView.removeOverlay(overlayToRemove)
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
                routeDatasource.deleteWayPoint(wayPointToDelete)
                
                // Refresh Poi annotations
                refreshPoiAnnotation(fromPoiToRefresh)
                if let toPoi = toPoiToRefresh {
                    refreshPoiAnnotation(toPoi)
                }
            } else {
                // It's exactly as if the user has selected on the Map an Annotation and selected deletion on the Callout
                removePoiAndRefresh(routeDatasource.wayPoints[index].wayPointPoi!)
            }
        }
    }
    
    // Delete from the route the POI with a selected annotation on the Map
    // Dialog box is opened to request confirmation when the Poi is used by several route sections
    func removeSelectedPoi() {
        if theMapView.selectedAnnotations.count > 0,
            let selectedPoi = theMapView.selectedAnnotations[0] as? PointOfInterest {
            
            if routeDatasource.poiOccurences(selectedPoi) > 1 {
                // the POI is used several times in the route
                // If the full route is displayed or
                // if a section only is displayed and the Poi to remove is not the start / stop
                // we request user confirm the Poi must be fully removed from the route
                if routeDatasource.isBeforeRouteSections ||
                    (routeDatasource.fromPOI != selectedPoi && routeDatasource.toPOI != selectedPoi) {
                    let alertActionSheet = UIAlertController(title: "Warning", message: "\(selectedPoi.poiDisplayName!) is used several times, do you want to remove it?", preferredStyle: .Alert)
                    alertActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    alertActionSheet.addAction(UIAlertAction(title: "Ok", style: .Default) {  alertAction in
                        
                        self.removePoiAndRefresh(selectedPoi)
                        })
                    
                    routeDisplayInfos.getViewController().presentViewController(alertActionSheet, animated: true, completion: nil)
                } else {
                    removePoiAndRefresh(selectedPoi)
                }
            } else {
                removePoiAndRefresh(selectedPoi)
            }
        }
    }
    
    // Remove the given Poi from the route and refresh the Map display
    //  - WayPoint overlay is removed
    //  - Poi is removed from route data source
    //  - To & From annotations are refreshed
    //  - If required, we display the full route
    private func removePoiAndRefresh(poi:PointOfInterest) {
        var needToRefreshCurrentRouteSection = false
        // If the POI is used to display the current WayPoint we remove its overlay
        if poi === routeDatasource.fromPOI || poi === routeDatasource.toPOI,
            let overlayToRemove = routeDatasource.fromWayPoint?.calculatedRoute?.polyline {
            theMapView.removeOverlay(overlayToRemove)
            needToRefreshCurrentRouteSection = true
        }
        
        // Remove the Poi from the datasource
        routeDatasource.deleteWayPointsWith(poi)
        
        // Update the removed Poi on the Map (Pin annotation & callout)
        //refreshPoiRemovedFromRoute(poi)
        refreshPoiAnnotation(poi)
        
        if needToRefreshCurrentRouteSection {
            refreshAnnotationsForCurrentWayPoint()
        }
        
        // If there's no route section, we go back to route start
        if routeDatasource.theRoute.wayPoints.count == 1 {
            displayRouteSection(.all)
        }
    }
    
    private func insertPoiInRoute(poi:PointOfInterest, atPosition:MapViewController.InsertPoiPostion) {
        
        switch atPosition {
        case .head: // Only when the whole route is displayed
            if let currentStartPoi = routeDatasource?.fromPOI {
                // The old starting WayPoint is changed to end if the route has only 1 wayPoint
                // else it becomes a simple wayPoint of the route
                if routeDatasource.theRoute.wayPoints.count == 1 {
                    refreshPoiAnnotation(currentStartPoi, withType: .routeEnd)
                } else {
                    refreshPoiAnnotation(currentStartPoi, withType: .waypoint)
                }
            }
            
            // The new wayPoint is inserted at the start
            routeDatasource.insertPoiAsRouteStart(poi)
            refreshPoiAnnotation(poi, withType: .routeStart)
            
        case .tail: // Only when the whole route is displayed
            if let currentEndPoi = routeDatasource?.toPOI {
                // the old ending waypoint is changed as the start if the route contains only 1 wayPoint
                // else it becomes a simple WayPoint of the route
                if routeDatasource.theRoute.wayPoints.count == 1 {
                    refreshPoiAnnotation(currentEndPoi, withType: .routeStart)
                } else {
                    refreshPoiAnnotation(currentEndPoi, withType: .waypoint)
                }
                
            }
            
            // The new wayPoint is added at the end
            routeDatasource.insertPoiAtAsRouteEnd(poi)
            refreshPoiAnnotation(poi, withType: .routeEnd)
            
        case .currentPosition: // Only when only a route section is displayed
            if let currentStartPoi = routeDatasource?.fromPOI {
                // The old start becomes the simple wayPoint from the route
                refreshPoiAnnotation(currentStartPoi, withType: .waypoint)
            }
            
            if let currentEndPoi = routeDatasource?.toPOI {
                // the old ending waypoint is changed to become the start
                refreshPoiAnnotation(currentEndPoi, withType: .routeStart)
            }
            
            // The new wayPoint is added at the end of the new route section
            routeDatasource.insertPoiInRoute(poi)
            refreshPoiAnnotation(poi, withType: .routeEnd)
        }
    }

    // MARK: Route from current location
    
    // - Remove the overlay that displays the route from the current location
    // - Reset some flags
    // - Update the Summary infos
    // - Change the Map bounding box to display the current route section
    private func removeRouteFromCurrentLocation() {
        isRouteFromCurrentLocationDisplayed = false
        
        if let overlayFromCurrentLocation = routeFromCurrentLocation?.polyline {
            theMapView.removeOverlay(overlayFromCurrentLocation)
        }
        routeFromCurrentLocation = nil
        
        displayRouteInfos()
        displayRouteMapRegion()
    }

    // - Add the Polyline overlay to display the route from the current location
    // - Update the Summary infos
    // - Change the Map bounding box to display the whole route
    private func displayRouteFromCurrentLocation(route:MKRoute) {
        if let oldRoute = routeFromCurrentLocation {
            theMapView.removeOverlay(oldRoute.polyline)
        }
        routeFromCurrentLocation = route
        routeFromCurrentLocation?.polyline.title = MapUtils.PolyLineType.fromCurrentPosition
        isRouteFromCurrentLocationDisplayed = true
        
        theMapView.addOverlay(routeFromCurrentLocation!.polyline)
        
        displayRouteInfos()
        displayRouteMapRegion()
    }
    
    // Request the route from the current location to target of the current route section
    private func buildRouteFromCurrentLocation(transportType:MKDirectionsTransportType) {
        if let toPoi = routeDatasource?.toPOI {
            let routeRequest = MKDirectionsRequest()
            routeRequest.transportType = transportType
            routeRequest.source = MKMapItem.mapItemForCurrentLocation()
            routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: toPoi.coordinate, addressDictionary: nil))
            
            // Display a HUD while loading the route
            PKHUD.sharedHUD.dimsBackground = true
            HUD.show(.Progress)
            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
            hudBaseView.titleLabel.text = "Loading directions"
            hudBaseView.subtitleLabel.text = "from current location"
            
            // ask the direction
            let routeDirections = MKDirections(request: routeRequest)
            routeDirections.calculateDirectionsWithCompletionHandler { routeResponse, routeError in
                HUD.hide()
                if let error = routeError {
                    Utilities.showAlertMessage(self.routeDisplayInfos.getViewController(), title:"Route error", error: error)
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
    private func refreshPoiAnnotation(poi:PointOfInterest, withType:MapUtils.PinAnnotationType) {
        if let annotationView = theMapView.viewForAnnotation(poi) as? WayPointPinAnnotationView {
            MapUtils.refreshPin(annotationView, poi: poi, delegate: routeDisplayInfos.getPoiCalloutDelegate(), type: withType)
        }
    }

    private func refreshAnnotationsForCurrentWayPoint() {
        if let from = routeDatasource.fromPOI {
            refreshPoiAnnotation(from)
            if let to = routeDatasource.toPOI where to != from {
                refreshPoiAnnotation(to)
            }
        }
    }
    
    // Refresh a Poi depending on its role in the Map
    func refreshPoiAnnotation(poi:PointOfInterest) {
        if let annotationView = theMapView.viewForAnnotation(poi) as? WayPointPinAnnotationView {
            let poiType = getPoiType(poi) ?? MapUtils.PinAnnotationType.normal
            MapUtils.refreshPin(annotationView, poi: poi, delegate: routeDisplayInfos.getPoiCalloutDelegate(), type: poiType)
            
            // Specific case when the route contains only the From then we must not set the
            // Add Way Point accessory
            if poiType == .routeStart && routeDatasource!.wayPoints.count == 1 {
                annotationView.disableAddWayPointAccessory()
            }
        }
    }


    //MARK: Utils
    // Display actions buttons
    // Buttons always displayed:
    // - Flyover and Navigation are always displayed
    //
    // Buttons displayed only when a route section is shown:
    // - Show/Hide route from current location
    // - Delete To/From WayPoint
    func showActions() {
        let alertActionSheet = UIAlertController(title: "\(routeDatasource.fromPOI!.poiDisplayName!) ➔ \(routeDatasource.toPOI!.poiDisplayName!)", message: "", preferredStyle: .ActionSheet)
        alertActionSheet.addAction(UIAlertAction(title: "Flyover", style: .Default) { alertAction in
            self.routeDisplayInfos.doFlyover(self.routeDatasource)
            })
        
        alertActionSheet.addAction(UIAlertAction(title: "Navigation", style: .Default) { alertAction in
            self.performNavigation()
            })
        
        
        if !routeDatasource.isBeforeRouteSections {
            
            if !isRouteFromCurrentLocationDisplayed {
                let title = "Route from current location ➔ \(routeDatasource.toPOI!.poiDisplayName!)"
                alertActionSheet.addAction(UIAlertAction(title: title, style: .Default) { alertAction in
                    self.buildRouteFromCurrentLocation(self.routeDatasource.fromWayPoint!.transportType!)
                    })
            } else {
                alertActionSheet.addAction(UIAlertAction(title: "Hide route from current location", style: .Default) { alertAction in
                    self.removeRouteFromCurrentLocation()
                    })
            }
            
            alertActionSheet.addAction(UIAlertAction(title: "Delete \(routeDatasource.fromPOI!.poiDisplayName!)", style: .Destructive) { alertAction in
                self.removePoiAndRefresh(self.routeDatasource.fromPOI!)
                })
            
            alertActionSheet.addAction(UIAlertAction(title: "Delete \(routeDatasource.toPOI!.poiDisplayName!)", style: .Destructive) { alertAction in
                self.removePoiAndRefresh(self.routeDatasource.toPOI!)
                })
        }
        
        alertActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        routeDisplayInfos.getViewController().presentViewController(alertActionSheet, animated: true, completion: nil)
        
    }
    
    func performNavigation() {
        if routeDatasource.isBeforeRouteSections {
            var items = [MKMapItem]()
            
            let mapAppOptions:[String : AnyObject] = [
                MKLaunchOptionsMapTypeKey : MKMapType.Standard.rawValue,
                MKLaunchOptionsShowsTrafficKey: true]
            
            items = routeDatasource.theRoute.mapItems
            MKMapItem.openMapsWithItems(items, launchOptions: mapAppOptions)
        } else {
            routeDisplayInfos.getViewController().performSegueWithIdentifier(PoiCalloutDelegateImpl.storyboard.startRoute, sender: nil)
        }
    }

    // Get the role of a POI in the Route (start/end/wayPoint/normal)?
    func getPoiType(poi:PointOfInterest) -> MapUtils.PinAnnotationType {
        var poiType = MapUtils.PinAnnotationType.normal
        if poi === routeDatasource.fromPOI {
            poiType = .routeStart
            // === The Poi is displayed as the From
        } else if poi === routeDatasource.toPOI {
            // === The Poi is displayed as the To
            poiType = .routeEnd
        } else {
            if routeDatasource.hasPoi(poi) {
                // === The Poi is part of the route but currently its WayPoint is not displayed
                poiType = .waypoint
            }
        }
        
        return poiType
    }

    private func showHUDForTransition() {
        PKHUD.sharedHUD.dimsBackground = false
        
        HUD.flash(.Label(routeDatasource.routeName), delay:1.0) { _ in
            self.theMapView.selectAnnotation(self.routeDatasource.fromPOI!, animated: true)
        }
    }

    
}
