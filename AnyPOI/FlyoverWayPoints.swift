//
//  FlyoverWayPoints.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 25/06/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

@objc
protocol FlyoverWayPointsDelegate: class  {
    
    func flyoverWillStartAnimation()
    func flyoverWillEndAnimation(urgentStop:Bool)
    func flyoverDidEnd(flyoverUpdatedPois:[PointOfInterest], urgentStop:Bool)
    
    func flyoverGetPoiCalloutDelegate() -> PoiCalloutDelegateImpl
}

class FlyoverWayPoints: NSObject{
    
    private var mapAnimation:MapCameraAnimations?
    private let theMapView:MKMapView
    private weak var flyoverDelegate:FlyoverWayPointsDelegate!
    
    private var stopWithoutAnimation = false
    
    // Tap gesture to stop the Flyover animation on user request
    private var singleTapGesture:UITapGestureRecognizer?
    
    init(mapView:MKMapView,  delegate:FlyoverWayPointsDelegate) {
        theMapView = mapView
        flyoverDelegate = delegate
        super.init()
    }
    
    // Can be called when the user restart the App from background and a Flyover was running
    func urgentStop() {
        stopWithoutAnimation = true
        mapAnimation?.stopAnimation()
    }
    
    
    deinit {
        if let gesture = singleTapGesture {
            theMapView.removeGestureRecognizer(gesture)
        }
    }

    func singleTapGestureToStopFlyoverAnimation(gestureRecognizer:UIGestureRecognizer) {
        mapAnimation!.stopAnimation()
    }


    //MARK: Flyover
    // Add annotations on map depending on the selected WayPoint
    func doFlyover(poi:PointOfInterest) {
        mapAnimation = MapCameraAnimations(mapView: theMapView, mapCameraDelegate: self)
        
        // Initialize the TapGesture to stop Flyover on user request
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(FlyoverWayPoints.singleTapGestureToStopFlyoverAnimation(_:)))
        singleTapGesture!.numberOfTapsRequired = 1
        singleTapGesture!.numberOfTouchesRequired = 1
        theMapView.addGestureRecognizer(singleTapGesture!)
        
        // remove from the map all accessories
        theMapView.showsCompass = false
        theMapView.showsPointsOfInterest = false
        theMapView.showsScale = false
        theMapView.showsTraffic = false
        
        // Start an animation to hide graphical element before to perform the animation with Flyover
        UIView.animateWithDuration(0.5, animations: {
            
            if self.theMapView.selectedAnnotations.count > 0 {
                self.theMapView.deselectAnnotation(self.theMapView.selectedAnnotations[0], animated: true)
            }
            
            self.flyoverDelegate.flyoverWillStartAnimation()
            
            }, completion: { result in
                // set the Map to satellite for Flyover / Remove all useless annotation & overlays from the map and start Flyover animation
                self.theMapView.mapType = .SatelliteFlyover

                self.flyoverUpdatedPois.removeAll()
                self.flyoverRemovedOverlays.removeAll()
                self.flyoverRemovedAnnotations.removeAll()

                if let viewAnnotation = self.theMapView.viewForAnnotation(poi) as? WayPointPinAnnotationView {
                    viewAnnotation.configureForFlyover(poi, delegate: self.flyoverDelegate.flyoverGetPoiCalloutDelegate())
                    self.flyoverUpdatedPois.append(poi)
                }

               
                self.mapAnimation!.flyoverAroundAnnotation(poi)
         })
        
    }

    func doFlyover(routeDatasource:RouteDataSource, routeFromCurrentLocation:MKRoute?) {
        mapAnimation = MapCameraAnimations(mapView: theMapView, mapCameraDelegate: self)
        
        // Initialize the TapGesture to stop Flyover on user request
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(FlyoverWayPoints.singleTapGestureToStopFlyoverAnimation(_:)))
        singleTapGesture!.numberOfTapsRequired = 1
        singleTapGesture!.numberOfTouchesRequired = 1
        theMapView.addGestureRecognizer(singleTapGesture!)

        // remove from the map all accessories
        theMapView.showsCompass = false
        theMapView.showsPointsOfInterest = false
        theMapView.showsScale = false
        theMapView.showsTraffic = false
        
        // Start an animation to hide graphical element before to perform the animation with Flyover
        UIView.animateWithDuration(0.5, animations: {
            
            if self.theMapView.selectedAnnotations.count > 0 {
                self.theMapView.deselectAnnotation(self.theMapView.selectedAnnotations[0], animated: true)
            }
            
            self.flyoverDelegate.flyoverWillStartAnimation()
            
            }, completion: { result in
                // set the Map to satellite for Flyover / Remove all useless annotation & overlays from the map and start Flyover animation
                self.theMapView.mapType = .SatelliteFlyover
                self.prepareAnnotationsAndOverlaysForFlyover(routeDatasource)
                if routeDatasource.isBeforeRouteSections {
                    self.mapAnimation!.flyover(routeDatasource.wayPoints)
                } else {
                    if let route = routeFromCurrentLocation {
                        self.mapAnimation!.flyoverFromAnnotation(self.theMapView.userLocation, waypoint: routeDatasource.toWayPoint!, onRoute: route)
                    } else {
                        self.mapAnimation!.flyover([routeDatasource.fromWayPoint!, routeDatasource.toWayPoint!])
                    }
                }
        })
        
    }
    
    // Keep all overlays and annotations changed / removed during the Flyover
    private var flyoverRemovedAnnotations = [MKAnnotation]()
    private var flyoverRemovedOverlays = [MKOverlay]()
    private var flyoverUpdatedPois = [PointOfInterest]()
    
    // Remove from the Map all overlays and Annotations that are not used during the Flyover
    // Annotations used during the Flyover are changed (to display the minimum number of information)
    private func prepareAnnotationsAndOverlaysForFlyover(datasource:RouteDataSource) {
        // Remove all data from the Map except the annotations and overlays that
        // will be used by the Flyover
        flyoverUpdatedPois.removeAll()
        flyoverRemovedOverlays.removeAll()
        flyoverRemovedAnnotations.removeAll()
        
        for currentAnnotation in theMapView.annotations {
            if let currentPoi = currentAnnotation as? PointOfInterest {
                if !datasource.hasPoi(currentPoi) {
                    flyoverRemovedAnnotations.append(currentAnnotation)
                    if let overlay = currentPoi.getMonitordRegionOverlay() {
                        flyoverRemovedOverlays.append(overlay)
                    }
                } else {
                    // If Flyover has been started for a section, we keep only the From & To of this section
                    if !datasource.isBeforeRouteSections && datasource.fromPOI != currentPoi && datasource.toPOI != currentPoi {
                        flyoverRemovedAnnotations.append(currentAnnotation)
                        if let overlay = currentPoi.getMonitordRegionOverlay() {
                            flyoverRemovedOverlays.append(overlay)
                        }
                    } else {
                        if let viewAnnotation = theMapView.viewForAnnotation(currentAnnotation) as? WayPointPinAnnotationView {
                            viewAnnotation.configureForFlyover(currentPoi, delegate: flyoverDelegate.flyoverGetPoiCalloutDelegate())
                            flyoverUpdatedPois.append(currentPoi)
                        }
                    }
                }
            }
        }
        
        theMapView.removeAnnotations(flyoverRemovedAnnotations)
        theMapView.removeOverlays(flyoverRemovedOverlays)
    }
    
    // Add on the Map all overlays and annotations that were removed from the Map during the Flyover
    private func restoreRemovedAnnotationsAndOverlays() {
        theMapView.addAnnotations(flyoverRemovedAnnotations)
        theMapView.addOverlays(flyoverRemovedOverlays)
        
        flyoverUpdatedPois.removeAll()
        flyoverRemovedOverlays.removeAll()
        flyoverRemovedAnnotations.removeAll()
    }
    
    private func cleanupFlyover(urgentStop: Bool) {
        theMapView.mapType = UserPreferences.sharedInstance.mapMode
        theMapView.showsCompass = true
        theMapView.showsScale = true
        theMapView.showsTraffic = UserPreferences.sharedInstance.mapShowTraffic
        
        flyoverDelegate.flyoverDidEnd(flyoverUpdatedPois, urgentStop: urgentStop)
        
        flyoverUpdatedPois.removeAll()
        
        restoreRemovedAnnotationsAndOverlays()
    }
}

extension FlyoverWayPoints : MapCameraAnimationsDelegate  {
    
    //MARK: MapCameraAnimationsDelegate
    internal func mapAnimationCompleted() {
        // Restore the mapView to its initial state
        if stopWithoutAnimation {
            stopWithoutAnimation = false
            flyoverDelegate.flyoverWillEndAnimation(true)
            cleanupFlyover(true)
        } else {
            UIView.animateWithDuration(0.5, animations: {
                self.theMapView.mapType = UserPreferences.sharedInstance.mapMode
                self.flyoverDelegate.flyoverWillEndAnimation(false)
                }, completion:  { result in
                    self.cleanupFlyover(false)
            })
        }
    }
    
}
