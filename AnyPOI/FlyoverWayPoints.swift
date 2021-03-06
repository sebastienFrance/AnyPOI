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
    func flyoverWillEndAnimation(_ urgentStop:Bool)
    func flyoverDidEnd(_ flyoverUpdatedPois:[PointOfInterest], urgentStop:Bool)
    
    func flyoverGetPoiCalloutDelegate() -> PoiCalloutDelegateImpl
    
    
    /// Add the POIs and their overlays (if any) on the Map
    ///
    /// - Parameter pois: List of PointOfInterest
    func flyoverAddPoisOnMap(pois:[PointOfInterest])
    
    
    /// Remove the POIs and their overlays (if any) from the Map
    ///
    /// - Parameter pois: List of PointOfInterest
    func flyoverRemovePoisFromMap(pois:[PointOfInterest])
}

class FlyoverWayPoints: NSObject{
    
    fileprivate var mapAnimation:MapCameraAnimations?
    fileprivate let theMapView:MKMapView
    fileprivate weak var flyoverDelegate:FlyoverWayPointsDelegate!
    
    fileprivate var stopWithoutAnimation = false
    
    // Tap gesture to stop the Flyover animation on user request
    fileprivate var singleTapGesture:UITapGestureRecognizer?
    
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

    @objc func singleTapGestureToStopFlyoverAnimation(_ gestureRecognizer:UIGestureRecognizer) {
        mapAnimation!.stopAnimation()
    }


    //MARK: Flyover
    // Add annotations on map depending on the selected WayPoint
    func doFlyover(_ poi:PointOfInterest) {
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
        UIView.animate(withDuration: 0.5, animations: {
            
            if self.theMapView.selectedAnnotations.count > 0 {
                self.theMapView.deselectAnnotation(self.theMapView.selectedAnnotations[0], animated: true)
            }
            
            self.flyoverDelegate.flyoverWillStartAnimation()
            
            }, completion: { result in
                // set the Map to satellite for Flyover / Remove all useless annotation & overlays from the map and start Flyover animation
                self.theMapView.mapType = .satelliteFlyover

                self.flyoverUpdatedPois.removeAll()
                self.flyoverRemovedAnnotations.removeAll()

                if let viewAnnotation = self.theMapView.view(for: poi) as? WayPointPinAnnotationView {
                    viewAnnotation.configureForFlyover(poi, delegate: self.flyoverDelegate.flyoverGetPoiCalloutDelegate())
                    self.flyoverUpdatedPois.append(poi)
                }

               
                self.mapAnimation!.flyoverAroundAnnotation(poi)
         })
        
    }

    func doFlyover(_ routeDatasource:RouteDataSource, routeFromCurrentLocation:MKRoute?) {
        if routeDatasource.wayPoints.count > 0 {
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
            UIView.animate(withDuration: 0.5, animations: {
                
                if self.theMapView.selectedAnnotations.count > 0 {
                    self.theMapView.deselectAnnotation(self.theMapView.selectedAnnotations[0], animated: true)
                }
                
                self.flyoverDelegate.flyoverWillStartAnimation()
                
            }, completion: { result in
                // set the Map to satellite for Flyover / Remove all useless annotation & overlays from the map and start Flyover animation
                self.theMapView.mapType = .satelliteFlyover
                self.prepareAnnotationsAndOverlaysForFlyover(routeDatasource)
                if routeDatasource.isFullRouteMode {
                    self.mapAnimation!.flyover(routeDatasource.wayPoints)
                } else {
                    if let route = routeFromCurrentLocation {
                        self.mapAnimation!.flyoverFromAnnotation(self.theMapView.userLocation, waypoint: routeDatasource.toWayPoint!, onRoutePolyline: route.polyline)
                    } else {
                        self.mapAnimation!.flyover([routeDatasource.fromWayPoint!, routeDatasource.toWayPoint!])
                    }
                }
            })
        }
    }
    
    // Keep all overlays and annotations changed / removed during the Flyover
    fileprivate var flyoverRemovedAnnotations = [PointOfInterest]()
    fileprivate var flyoverUpdatedPois = [PointOfInterest]()
    
    // Remove from the Map all overlays and Annotations that are not used during the Flyover
    // Annotations used during the Flyover are changed (to display the minimum number of information)
    fileprivate func prepareAnnotationsAndOverlaysForFlyover(_ datasource:RouteDataSource) {
        // Remove all data from the Map except the annotations and overlays that
        // will be used by the Flyover
        flyoverUpdatedPois.removeAll()
        flyoverRemovedAnnotations.removeAll()
        
        for currentAnnotation in theMapView.annotations {
            if let currentPoi = currentAnnotation as? PointOfInterest {
                if !datasource.contains(poi:currentPoi) {
                    flyoverRemovedAnnotations.append(currentPoi)
                } else {
                    // If Flyover has been started for a section, we keep only the From & To of this section
                    if !datasource.isFullRouteMode && datasource.fromPOI != currentPoi && datasource.toPOI != currentPoi {
                        flyoverRemovedAnnotations.append(currentPoi)
                    } else {
                        if let viewAnnotation = theMapView.view(for: currentAnnotation) as? WayPointPinAnnotationView {
                            viewAnnotation.configureForFlyover(currentPoi, delegate: flyoverDelegate.flyoverGetPoiCalloutDelegate())
                            flyoverUpdatedPois.append(currentPoi)
                        }
                    }
                }
            }
        }
        
        flyoverDelegate.flyoverRemovePoisFromMap(pois: flyoverRemovedAnnotations)
    }
    
    // Add on the Map all overlays and annotations that were removed from the Map during the Flyover
    fileprivate func restoreRemovedAnnotationsAndOverlays() {
        flyoverDelegate.flyoverAddPoisOnMap(pois: flyoverRemovedAnnotations)
        
        flyoverUpdatedPois.removeAll()
        flyoverRemovedAnnotations.removeAll()
    }
    
    fileprivate func cleanupFlyover(_ urgentStop: Bool) {
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
            UIView.animate(withDuration: 0.5, animations: {
                self.theMapView.mapType = UserPreferences.sharedInstance.mapMode
                self.flyoverDelegate.flyoverWillEndAnimation(false)
                }, completion:  { result in
                    self.cleanupFlyover(false)
            })
        }
    }
    
}
