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

class FlyoverWayPoints: NSObject, MapCameraAnimationsDelegate {
    
    private var mapAnimation:MapCameraAnimations?
    private let theMapView:MKMapView
    private let routeDatasource:RouteDataSource
    private weak var flyoverDelegate:FlyoverWayPointsDelegate!
    
    private var stopWithoutAnimation = false
    
    private var singleTapGesture:UITapGestureRecognizer?
    
    init(mapView:MKMapView, datasource:RouteDataSource, delegate:FlyoverWayPointsDelegate) {
        theMapView = mapView
        routeDatasource = datasource
        flyoverDelegate = delegate
        super.init()
    }
    
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
    
    private var flyoverRemovedAnnotations = [MKAnnotation]()
    private var flyoverRemovedOverlays = [MKOverlay]()
    private var flyoverUpdatedPois = [PointOfInterest]()
    
    private func prepareAnnotationsAndOverlaysForFlyover() {
        // Remove all data from the Map except the annotations and overlays that
        // will be used by the Flyover
        flyoverUpdatedPois.removeAll()
        flyoverRemovedOverlays.removeAll()
        flyoverRemovedAnnotations.removeAll()
        
        for currentAnnotation in theMapView.annotations {
            if let currentPoi = currentAnnotation as? PointOfInterest {
                if !routeDatasource.hasPoi(currentPoi) {
                    flyoverRemovedAnnotations.append(currentAnnotation)
                    if let overlay = currentPoi.getMonitordRegionOverlay() {
                        flyoverRemovedOverlays.append(overlay)
                    }
                } else {
                    // If Flyover has been started for a section, we keep only the From & To of this section
                    if !routeDatasource.isBeforeRouteSections && routeDatasource.fromPOI != currentPoi && routeDatasource.toPOI != currentPoi {
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
    
    private func restoreRemovedAnnotationsAndOverlays() {
        theMapView.addAnnotations(flyoverRemovedAnnotations)
        theMapView.addOverlays(flyoverRemovedOverlays)
        
        flyoverUpdatedPois.removeAll()
        flyoverRemovedOverlays.removeAll()
        flyoverRemovedAnnotations.removeAll()
    }
    
    
    func doFlyover(routeFromCurrentLocation:MKRoute?) {
        mapAnimation = MapCameraAnimations(mapView: theMapView, mapCameraDelegate: self)
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(FlyoverWayPoints.singleTapGestureToStopFlyoverAnimation(_:)))
        singleTapGesture!.numberOfTapsRequired = 1
        singleTapGesture!.numberOfTouchesRequired = 1
        theMapView.addGestureRecognizer(singleTapGesture!)

        
        theMapView.showsCompass = false
        theMapView.showsPointsOfInterest = false
        theMapView.showsScale = false
        theMapView.showsTraffic = false
        
        
        UIView.animateWithDuration(0.5, animations: {
            
            if self.theMapView.selectedAnnotations.count > 0 {
                self.theMapView.deselectAnnotation(self.theMapView.selectedAnnotations[0], animated: true)
            }
            
            self.flyoverDelegate.flyoverWillStartAnimation()
            
            }, completion: { result in
                self.theMapView.mapType = .SatelliteFlyover
                self.prepareAnnotationsAndOverlaysForFlyover()
                if self.routeDatasource.isBeforeRouteSections {
                    self.mapAnimation!.flyover(self.routeDatasource.wayPoints)
                } else {
                    if let route = routeFromCurrentLocation {
                        self.mapAnimation!.flyoverFromAnnotation(self.theMapView.userLocation, waypoint: self.routeDatasource.toWayPoint!, onRoute: route)
                    } else {
                        self.mapAnimation!.flyover([self.routeDatasource.fromWayPoint!, self.routeDatasource.toWayPoint!])
                    }
                }
        })
        
    }
    
    
    //MARK: MapCameraAnimationsDelegate
    internal func mapAnimationCompleted() {
        // Restore the mapView to its initial state
        if stopWithoutAnimation {
            stopWithoutAnimation = false
            flyoverDelegate.flyoverWillEndAnimation(true)
            cleanupFlyover(true)
        } else {
            UIView.animateWithDuration(0.5, animations: {
                self.flyoverDelegate.flyoverWillEndAnimation(false)
                }, completion:  { result in
                    self.cleanupFlyover(false)
            })

        }
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
