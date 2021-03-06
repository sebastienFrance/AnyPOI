//
//  MapCameraAnimations.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 18/03/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit


protocol MapCameraAnimationsDelegate: class {
    func mapAnimationCompleted()
}


class MapCameraAnimations  {
    
    fileprivate struct MapConstantes {
        static let defaultCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        static let maxDistanceWithAnimations = 3000.0
        static let defaultCameraDistanceFrom = 250.0
        static let defaultCameraPitchForFlyover = CGFloat(45.0)
        static let defaultCameraHeading = 0.0
    }

    
    struct CameraPath {
        var camera:MKMapCamera!
        var annotation:MKAnnotation?
        var coordinate:CLLocationCoordinate2D!
        var routePolyline:MKPolyline? // Could be replace by only the Polyline it contains
        
        // When set to true, it selects the annotation related to the waypoint.
        var isSelectedAnnotation = false
        var animationDuration = 1.0
        var animationDelay = 0.0
        
        // when set to true, it removes all overlays and add the overlay with the route starting at this wayPoint
        var updateOverlays = false
        
        init(camera:MKMapCamera, wayPoint:WayPoint) {
            self.camera = camera
            annotation = wayPoint.wayPointPoi!
            coordinate = annotation!.coordinate
            routePolyline = wayPoint.routeInfos?.polyline
        }
        
        init(camera:MKMapCamera, wayPoint:WayPoint, animationDuration:Double) {
            self.camera = camera
            annotation = wayPoint.wayPointPoi!
            coordinate = annotation!.coordinate
            routePolyline = wayPoint.routeInfos?.polyline
            self.animationDuration = animationDuration
        }
        
        init(camera:MKMapCamera, annotation:MKAnnotation, animationDuration:Double) {
            self.camera = camera
            self.annotation = annotation
            self.coordinate = annotation.coordinate
            self.animationDuration = animationDuration
        }
        
        init(camera:MKMapCamera, fromCoordinate:CLLocationCoordinate2D, animationDuration:Double) {
            self.camera = camera
            self.coordinate = fromCoordinate
            self.animationDuration = animationDuration
        }
        
    }
  
    var theCameraPath = [CameraPath]()
    var isFlyoverAnimationRunning = false
    fileprivate var userRequestedToStopFlyoverAnimation = false
    
    struct DefaultFor360Degree {
        static let fromDistance = 500.0
        static let pitch = CGFloat(55.0)
    }
    
    weak var theMapView:MKMapView!
    weak var delegate:MapCameraAnimationsDelegate!
    
    init(mapView:MKMapView, mapCameraDelegate:MapCameraAnimationsDelegate) {
        theMapView = mapView
        delegate = mapCameraDelegate
    }

    
    // Trigger a Flyover over all wayPoints.
    // When all wayPoints have been visited or if the user has interrupted the animation then
    // the mapAnimationCompleted() from MapCameraAnimationDelegate is called
    func flyover(_ wayPoints:[WayPoint]) {
        reset()
        var previousWayPoint:WayPoint?
        for currentWayPoint in wayPoints {
            var startingDuration = 1.0
            if let thePreviousWayPoint = previousWayPoint {
                let duration = addJunctionFrom(thePreviousWayPoint.wayPointPoi!, toWayPoint: currentWayPoint)
                startingDuration = duration
            } else {
                // It's the first WayPoint, we are starting with Flyover
                let duration = addStartingJunctionFrom(currentWayPoint.wayPointPoi!)
                startingDuration = duration
            }
            
            var nextRoutePolyline:MKPolyline?
            if currentWayPoint != wayPoints.last {
                nextRoutePolyline = currentWayPoint.routeInfos?.polyline
            }
            add360RotationAround(currentWayPoint.wayPointPoi!, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: startingDuration, routePolyline: nextRoutePolyline)

            previousWayPoint = currentWayPoint
        }
        
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()
    }
    
    func flyoverFromAnnotation(_ annotation:MKAnnotation, waypoint:WayPoint, onRoutePolyline:MKPolyline? = nil) {
        reset()
        let duration = addStartingJunctionFrom(annotation)
        add360RotationAround(annotation, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: duration, routePolyline:onRoutePolyline)
        let startDuration = addJunctionFrom(annotation, toWayPoint:waypoint)
        add360RotationAround(waypoint.wayPointPoi!, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: startDuration)
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()
   }
    
    func flyoverAroundAnnotation(_ annotation:MKAnnotation) {
        reset()
        let duration = addStartingJunctionFrom(annotation)
        add360RotationAround(annotation, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: duration)
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()
    }
    
    func fromCurrentMapLocationTo(_ coordinates:CLLocationCoordinate2D) {
        fromCurrentMapLocationTo(coordinates, withAnimation: true)
    }
    
    func fromCurrentMapLocationTo(_ coordinates:CLLocationCoordinate2D, withAnimation:Bool) {
        switch theMapView.mapType {
        case .hybridFlyover, .satelliteFlyover:
            let finalCamera = MKMapCamera.init(lookingAtCenter: coordinates, fromDistance: MapConstantes.defaultCameraDistanceFrom, pitch: MapConstantes.defaultCameraPitchForFlyover, heading: MapConstantes.defaultCameraHeading)
            
            if withAnimation {
                flyoverFromCurrentLocationTo(finalCamera)
            } else {
                theMapView.setCamera(finalCamera, animated: false)
            }
        default:
            setRegionToLocation(coordinates, withAnimation: withAnimation)
        }
    }
    
    fileprivate func setRegionToLocation(_ coordinates:CLLocationCoordinate2D, withAnimation:Bool) {
        let region = MKCoordinateRegion(center: coordinates, span: MapConstantes.defaultCoordinateSpan)
        
        var regionAnimation = false
        if withAnimation && MapUtils.distanceFromTo(theMapView.centerCoordinate, toCoordinate:coordinates) <= MapConstantes.maxDistanceWithAnimations {
            regionAnimation = true
        }
        
        theMapView.setRegion(region, animated: regionAnimation)
    }

    
    fileprivate func flyoverFromCurrentLocationTo(_ camera:MKMapCamera) {
        reset()
        
        let fromCoordinate = theMapView.centerCoordinate
        let toCoordinate = camera.centerCoordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distance(from: toLocation)
        
        if distanceFromTo > 3000 {
            theMapView.centerCoordinate = camera.centerCoordinate
            let targetCamera = CameraPath(camera: camera, fromCoordinate: camera.centerCoordinate, animationDuration: 3.5)
            theCameraPath.append(targetCamera)

        } else {
            var (_, fromDistance) = MapCameraAnimations.getFromDistanceAndDuration(distanceFromTo)
            
            // If the altitude of the MapView is already lower than the altitude computed then we start with
            // the altitude from the MapView to avoid useless Up and Down!
            if theMapView.camera.altitude < fromDistance {
                fromDistance = theMapView.camera.altitude
            }
            
            let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), fromCoordinate:fromCoordinate, animationDuration:2.5)
            theCameraPath.append(newCameraPath)
            
            let targetCamera = CameraPath(camera: camera, fromCoordinate: camera.centerCoordinate, animationDuration: 2.5)
            theCameraPath.append(targetCamera)
        }
        
 
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()

    }

    // It stop an ongoing animation (if any)
    func stopAnimation() {
        if isFlyoverAnimationRunning {
            userRequestedToStopFlyoverAnimation = true
            theMapView.layer.removeAllAnimations()
        }
    }
    
    // Reset the content of a MapCameraAnimation
    fileprivate func reset() {
        theCameraPath = [CameraPath]()
    }
    
    // Get duration and FromDistance to be used based on the distance between two WayPoints
    fileprivate static func getFromDistanceAndDuration(_ distanceFromTo:CLLocationDistance) -> (startDuration:Double, fromDistance:CLLocationDistance) {
        var startDuration = 1.0
        var fromDistance = 3000.0
        
        switch distanceFromTo {
        case 0..<10000:
            fromDistance = 3000
            startDuration = 1.0
        case 10000..<50000:
            fromDistance = 70000
            startDuration = 2.0
        case 50000..<300000:
            fromDistance = 150000
            startDuration = 4.0
        case 300000..<600000:
            fromDistance = 250000
            startDuration = 4.0
        default:
            fromDistance = 500000
            startDuration = 4.0
        }
        
        return (startDuration, fromDistance)
    }
    
    // Add the MKMapCamera needed to perform a 360 degree rotation around a WayPoint
    // Animation start after a delay of 2 seconds
    // Each step of the animation will take 2 seconds
    // At the start of the animation we update the overlays to display the route starting at this WayPoint and the callout of its annotation is displayed
    // For all other animations the callout is not displayed
    fileprivate func add360RotationAround(_ annotation:MKAnnotation, fromDistance: CLLocationDistance, pitch: CGFloat, startDuration:Double, routePolyline:MKPolyline? = nil) {
        
        if UserPreferences.sharedInstance.flyover360Enabled {
            let theCoordinate = annotation.coordinate
            
            var newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 0), annotation:annotation, animationDuration:startDuration)
            newCameraPath.isSelectedAnnotation = true
            newCameraPath.animationDelay = 2
            if let theRoutePolyline = routePolyline {
                newCameraPath.updateOverlays = true
                newCameraPath.routePolyline = theRoutePolyline
            } else {
                newCameraPath.updateOverlays = false //true
            }
            theCameraPath.append(newCameraPath)
            
            newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 135), annotation:annotation, animationDuration: 2.5)
            theCameraPath.append(newCameraPath)
            newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 270), annotation:annotation, animationDuration: 2.5)
            theCameraPath.append(newCameraPath)
            newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 360), annotation:annotation, animationDuration: 2.5)
            newCameraPath.animationDelay = 2
            theCameraPath.append(newCameraPath)
        } else {
            let theCoordinate = annotation.coordinate
            
            // During this animation we zoom on the POI and we display its callout
            var newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 0), annotation:annotation, animationDuration: 1.0)
            newCameraPath.isSelectedAnnotation = true
            newCameraPath.animationDelay = 2
            if let theRoutePolyline = routePolyline {
                newCameraPath.updateOverlays = true
                newCameraPath.routePolyline = theRoutePolyline
            } else {
                newCameraPath.updateOverlays = false //true
            }
            theCameraPath.append(newCameraPath)
            
            // Add a second animation, it will remove the POI callout during this animation
            newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 0), annotation:annotation, animationDuration: 2.0)
            theCameraPath.append(newCameraPath)

        }
    }

    
    // Add the MKMapCamera needed to perform the junction between the 2 given annotations
    // The MKMapCamera added will depend on the distance between these 2 wayPoints
    fileprivate func addJunctionFrom(_ annotation: MKAnnotation, toWayPoint:WayPoint) -> Double {
        let fromCoordinate = annotation.coordinate
        let toCoordinate = toWayPoint.wayPointPoi!.coordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distance(from: toLocation)
        
        let (startDuration, fromDistance) = MapCameraAnimations.getFromDistanceAndDuration(distanceFromTo)
        
        if distanceFromTo <= 10000 {
            let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), wayPoint:toWayPoint, animationDuration:5)
            theCameraPath.append(newCameraPath)
        } else {
            var newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: fromCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), annotation:annotation, animationDuration:5)
            theCameraPath.append(newCameraPath)
            newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), wayPoint:toWayPoint, animationDuration:5)
            theCameraPath.append(newCameraPath)
            
        }
        return startDuration
    }

    
    // Add the MKMapCamera needed to perform the junction from the current MapView coordinates and the given annotation
    // The MKMapCamera added will depend on the distance between the MapView and the WayPoint
    fileprivate func addStartingJunctionFrom(_ annotation:MKAnnotation) -> Double {
        let fromCoordinate = theMapView.centerCoordinate
        let toCoordinate = annotation.coordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distance(from: toLocation)
        
        var (startDuration, fromDistance) = MapCameraAnimations.getFromDistanceAndDuration(distanceFromTo)
        
        // If the altitude of the MapView is already lower than the altitude computed then we start with
        // the altitude from the MapView to avoid useless Up and Down!
        if theMapView.camera.altitude < fromDistance {
            fromDistance = theMapView.camera.altitude
        }
        
        let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenter: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), annotation:annotation, animationDuration:startDuration)
        theCameraPath.append(newCameraPath)
        
        return startDuration
    }

    
    

    // It Performs the animation of MkMapCamera starting with the given index
    // The animation stops only when all animations have been done or when the user
    // has interrupted it
    fileprivate func executeCameraPathFromIndex(_ index:Int = 0) {
        
        isFlyoverAnimationRunning = true
        
        UIView.animate(withDuration: theCameraPath[index].animationDuration, delay:theCameraPath[index].animationDelay, options:[.allowUserInteraction] , animations: {
            self.theMapView.camera = self.theCameraPath[index].camera
            if self.theCameraPath[index].isSelectedAnnotation {
                if let poi = self.theCameraPath[index].annotation {
                    self.theMapView.selectAnnotation(poi, animated: true)
                }
            } else {
                if let poi = self.theCameraPath[index].annotation {
                    self.theMapView.deselectAnnotation(poi, animated: true)
                }
            }
            
            
            }, completion: { result in
                // If we have reached the latest animation or of if the user has stopped it
                // we reset the MapCameraAnimations data and we call the delegate to end the animation
                if self.theCameraPath.count == 0 || (index == (self.theCameraPath.count - 1) || index > self.theCameraPath.count) || self.userRequestedToStopFlyoverAnimation {
                    self.userRequestedToStopFlyoverAnimation = false
                    self.isFlyoverAnimationRunning = false
                    self.reset()
                    self.delegate.mapAnimationCompleted()
                } else {
                    
                    // update overlays if requested by the current CameraPath
                    if self.theCameraPath[index].updateOverlays {
                        //self.theMapView.removeOverlays(self.theMapView.overlays) // Warning: SEB monitoring should not be removed???
                        if let polyLine = self.theCameraPath[index].routePolyline {
                            self.theMapView.add(polyLine, level: .aboveRoads)
                        }
                    }
                    
                    // Continue the animation
                    let newIndex = index + 1

                    // Wait 1s before to continue the next animation
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(((Int64)(1.0) * (Int64)(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        self.executeCameraPathFromIndex(newIndex)
                    }
                }
         })
    }
}
