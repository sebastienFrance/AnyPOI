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
    
    private struct MapConstantes {
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
        var route:MKRoute?
        
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
            route = wayPoint.calculatedRoute
        }
        
        init(camera:MKMapCamera, wayPoint:WayPoint, animationDuration:Double) {
            self.camera = camera
            annotation = wayPoint.wayPointPoi!
            coordinate = annotation!.coordinate
            route = wayPoint.calculatedRoute
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
    private var userRequestedToStopFlyoverAnimation = false
    
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
    func flyover(wayPoints:[WayPoint]) {
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
            
            var nextRoute:MKRoute?
            if currentWayPoint != wayPoints.last {
                nextRoute = currentWayPoint.calculatedRoute
            }
            add360RotationAround(currentWayPoint.wayPointPoi!, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: startingDuration, route: nextRoute)

            previousWayPoint = currentWayPoint
        }
        
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()
    }
    
    func flyoverFromAnnotation(annotation:MKAnnotation, waypoint:WayPoint, onRoute:MKRoute? = nil) {
        reset()
        let duration = addStartingJunctionFrom(annotation)
        add360RotationAround(annotation, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: duration, route:onRoute)
        let startDuration = addJunctionFrom(annotation, toWayPoint:waypoint)
        add360RotationAround(waypoint.wayPointPoi!, fromDistance:  DefaultFor360Degree.fromDistance, pitch: DefaultFor360Degree.pitch, startDuration: startDuration)
        userRequestedToStopFlyoverAnimation = false
        executeCameraPathFromIndex()
   }
    
    func fromCurrentMapLocationTo(coordinates:CLLocationCoordinate2D) {
        fromCurrentMapLocationTo(coordinates, withAnimation: true)
    }
    
    func fromCurrentMapLocationTo(coordinates:CLLocationCoordinate2D, withAnimation:Bool) {
        switch theMapView.mapType {
        case .HybridFlyover, .SatelliteFlyover:
            let finalCamera = MKMapCamera.init(lookingAtCenterCoordinate: coordinates, fromDistance: MapConstantes.defaultCameraDistanceFrom, pitch: MapConstantes.defaultCameraPitchForFlyover, heading: MapConstantes.defaultCameraHeading)
            
            if withAnimation {
                flyoverFromCurrentLocationTo(finalCamera)
            } else {
                theMapView.setCamera(finalCamera, animated: false)
            }
        default:
            setRegionToLocation(coordinates, withAnimation: withAnimation)
        }
    }
    
    private func setRegionToLocation(coordinates:CLLocationCoordinate2D, withAnimation:Bool) {
        let region = MKCoordinateRegion(center: coordinates, span: MapConstantes.defaultCoordinateSpan)
        
        var regionAnimation = false
        if withAnimation && MapUtils.distanceFromTo(theMapView.centerCoordinate, toCoordinate:coordinates) <= MapConstantes.maxDistanceWithAnimations {
            regionAnimation = true
        }
        
        theMapView.setRegion(region, animated: regionAnimation)
    }

    
    private func flyoverFromCurrentLocationTo(camera:MKMapCamera) {
        reset()
        
        let fromCoordinate = theMapView.centerCoordinate
        let toCoordinate = camera.centerCoordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distanceFromLocation(toLocation)
        
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
            
            let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), fromCoordinate:fromCoordinate, animationDuration:2.5)
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
    private func reset() {
        theCameraPath = [CameraPath]()
    }
    
    // Get duration and FromDistance to be used based on the distance between two WayPoints
    private static func getFromDistanceAndDuration(distanceFromTo:CLLocationDistance) -> (startDuration:Double, fromDistance:CLLocationDistance) {
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
    private func add360RotationAround(annotation:MKAnnotation, fromDistance: CLLocationDistance, pitch: CGFloat, startDuration:Double, route:MKRoute? = nil) {
        let theCoordinate = annotation.coordinate
        
        var newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 0), annotation:annotation, animationDuration:startDuration)
        newCameraPath.isSelectedAnnotation = true
        newCameraPath.animationDelay = 2
        if let theRoute = route {
            newCameraPath.updateOverlays = true
            newCameraPath.route = theRoute
        } else {
            newCameraPath.updateOverlays = false //true
        }
        theCameraPath.append(newCameraPath)
        
        newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenterCoordinate: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 135), annotation:annotation, animationDuration: 2.5)
        theCameraPath.append(newCameraPath)
        newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenterCoordinate: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 270), annotation:annotation, animationDuration: 2.5)
        theCameraPath.append(newCameraPath)
        newCameraPath = CameraPath(camera: MKMapCamera(lookingAtCenterCoordinate: theCoordinate, fromDistance: fromDistance, pitch: pitch, heading: 360), annotation:annotation, animationDuration: 2.5)
        newCameraPath.animationDelay = 2
        theCameraPath.append(newCameraPath)
    }

    
    // Add the MKMapCamera needed to perform the junction between the 2 given annotations
    // The MKMapCamera added will depend on the distance between these 2 wayPoints
    private func addJunctionFrom(annotation: MKAnnotation, toWayPoint:WayPoint) -> Double {
        let fromCoordinate = annotation.coordinate
        let toCoordinate = toWayPoint.wayPointPoi!.coordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distanceFromLocation(toLocation)
        
        let (startDuration, fromDistance) = MapCameraAnimations.getFromDistanceAndDuration(distanceFromTo)
        
        if distanceFromTo <= 10000 {
            let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), wayPoint:toWayPoint, animationDuration:5)
            theCameraPath.append(newCameraPath)
        } else {
            var newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: fromCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), annotation:annotation, animationDuration:5)
            theCameraPath.append(newCameraPath)
            newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), wayPoint:toWayPoint, animationDuration:5)
            theCameraPath.append(newCameraPath)
            
        }
        return startDuration
    }

    
    // Add the MKMapCamera needed to perform the junction from the current MapView coordinates and the given annotation
    // The MKMapCamera added will depend on the distance between the MapView and the WayPoint
    private func addStartingJunctionFrom(annotation:MKAnnotation) -> Double {
        let fromCoordinate = theMapView.centerCoordinate
        let toCoordinate = annotation.coordinate
        
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distanceFromLocation(toLocation)
        
        var (startDuration, fromDistance) = MapCameraAnimations.getFromDistanceAndDuration(distanceFromTo)
        
        // If the altitude of the MapView is already lower than the altitude computed then we start with
        // the altitude from the MapView to avoid useless Up and Down!
        if theMapView.camera.altitude < fromDistance {
            fromDistance = theMapView.camera.altitude
        }
        
        let newCameraPath = CameraPath(camera:MKMapCamera(lookingAtCenterCoordinate: toCoordinate, fromDistance: fromDistance, pitch: 0, heading: 0), annotation:annotation, animationDuration:startDuration)
        theCameraPath.append(newCameraPath)
        
        return startDuration
    }

    
    

    // It Performs the animation of MkMapCamera starting with the given index
    // The animation stops only when all animations have beend done or when the user
    // has interrupted it
    private func executeCameraPathFromIndex(index:Int = 0) {
        
        isFlyoverAnimationRunning = true
        
        UIView.animateWithDuration(theCameraPath[index].animationDuration, delay:theCameraPath[index].animationDelay, options:[.AllowUserInteraction] , animations: {
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
                        self.theMapView.removeOverlays(self.theMapView.overlays) // Warning: SEB monitoring should not be removed???
                        if let route = self.theCameraPath[index].route {
                            self.theMapView.addOverlay(route.polyline, level: .AboveRoads)
                        }
                    }
                    
                    // Continue the animation
                    let newIndex = index + 1

                    // Wait 1s before to continue the next animation
                    dispatch_after(dispatch_time( DISPATCH_TIME_NOW, ((Int64)(1.0) * (Int64)(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                        self.executeCameraPathFromIndex(newIndex)
                    }
                }
         })
    }
}
