//
//  MapUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 11/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

@objc
protocol PoiCalloutDelegate: class {
    
    func zoomOnPoi(sender: UIButton)
    func showURL(sender: UIButton)
    func startPhoneCall(sender:UIButton)
    func startEmail(sender:UIButton)
    func startRoute(sender:UIButton)
    
    func trashWayPoint(sender:UIButton)
    func addWayPoint(sender:UIButton)
}


class MapUtils {
    
    struct MapColors {
        static let pinColorForRouteStart = UIColor.greenColor()
        static let pinColorForRouteEnd = UIColor.redColor()
        
        static let routeColorForCar = UIColor.blueColor()
        static let routeColorForWalking = UIColor.purpleColor()
        static let routeColorForTransit = UIColor.yellowColor()
        static let routeColorForCurrentPosition = UIColor.greenColor()
        static let routeColorForUnknown = UIColor.blackColor()

}
    
    struct MapConstantes {
        static let defaultCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
    }

    
    static func getNameFromPlacemark(newPlacemark:CLPlacemark) -> String? {
        if let newLocality = newPlacemark.locality {
            if let name = newPlacemark.name {
                return "\(newLocality), \(name)"
            } else {
                return "\(newLocality)"
            }
        } else {
            if let name = newPlacemark.name {
                return "\(name)"
            } else {
                return nil
            }
        }

    }
    
    static func transportTypeToSegmentIndex(transportType:MKDirectionsTransportType) -> Int {
        switch transportType {
        case MKDirectionsTransportType.Automobile:
            return 0
        case MKDirectionsTransportType.Walking:
            return 1
        case MKDirectionsTransportType.Any:
            return 2
        default:
            return 0
        }
        
    }
    
    static func segmentIndexToTransportType(segmentedControl:UISegmentedControl) -> MKDirectionsTransportType {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return MKDirectionsTransportType.Automobile
        case 1:
            return MKDirectionsTransportType.Walking
        case 2:
            return MKDirectionsTransportType.Transit
        case 3:
            return MKDirectionsTransportType.Any
        default:
            return MKDirectionsTransportType.Automobile
        }
        
    }

    static func transportTypeDisplayName(transportType:MKDirectionsTransportType) -> String {
        switch transportType {
        case MKDirectionsTransportType.Automobile:
            return "Automobile"
        case MKDirectionsTransportType.Walking:
            return "Walking"
        case MKDirectionsTransportType.Transit:
            return "Transit"
        default:
            return "Unknown"
        }
    }
    
    static func convertToLaunchOptionsDirection(transportType:MKDirectionsTransportType) -> String {
        switch transportType {
        case MKDirectionsTransportType.Automobile:
            return MKLaunchOptionsDirectionsModeDriving
        case MKDirectionsTransportType.Walking:
            return MKLaunchOptionsDirectionsModeWalking
        case MKDirectionsTransportType.Transit:
            return MKLaunchOptionsDirectionsModeTransit
        case MKDirectionsTransportType.Any:
            return MKLaunchOptionsDirectionsModeDriving
        default:
            return MKLaunchOptionsDirectionsModeDriving
        }
    }

    //MARK: Bounding box
    static func boundingBoxForAnnotations(annotations:[MKAnnotation]) -> MKCoordinateRegion {
        if annotations.count == 0 {
            return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0,0), MKCoordinateSpanMake(90, 180))
        } else {
        
            var topLeftCoord = CLLocationCoordinate2DMake(-90, 180)
            var bottomRightCoord = CLLocationCoordinate2DMake(90, -180)
            
            for annotation in annotations {
                topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude)
                topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude)
                bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude)
                bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2DMake(topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5,
                topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5)
            
            let span = MKCoordinateSpanMake(fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1,
                fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1)
            
            return MKCoordinateRegionMake(center, span)
        }
    }

    static func appendMargingToBoundBox(topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2DMake(topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5,
            topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5)

        let span = MKCoordinateSpanMake(fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2,
            fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2)

        return MKCoordinateRegionMake(center, span)
    }

    // Not used
    static func boundingBoxForAnnotationsNew(annotations:[MKAnnotation]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        var topLeftCoord = CLLocationCoordinate2DMake(-90, 180)
        var bottomRightCoord = CLLocationCoordinate2DMake(90, -180)

        for annotation in annotations {
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude)
        }
        return (topLeftCoord, bottomRightCoord)
    }
    
    // Extend a bounding box with a list of annotations
    static func extendBoundingBox(topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, annotations:[MKAnnotation]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        
        var newTopLeftCoord = topLeftCoord
        var newBottomRightCoord = bottomRightCoord
        
        for currentAnnotation in annotations {
            (newTopLeftCoord, newBottomRightCoord) = extendBoundingBox(newTopLeftCoord, bottomRightCoord: newBottomRightCoord, annotation: currentAnnotation)
        }
        
        return (newTopLeftCoord, newBottomRightCoord)
    }
    
    // Extend a bouding box to include an annotation
    static func extendBoundingBox(topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, annotation:MKAnnotation) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        return extendBoundingBox(topLeftCoord, bottomRightCoord: bottomRightCoord, newPoint: annotation.coordinate)
    }

    // Extend a bounding box with an additional point
    static func extendBoundingBox(topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, newPoint:CLLocationCoordinate2D) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {

        var newTopLeftCoord = topLeftCoord
        newTopLeftCoord.longitude = fmin(topLeftCoord.longitude, newPoint.longitude)
        newTopLeftCoord.latitude = fmax(topLeftCoord.latitude, newPoint.latitude)
        
        var newBottomRightCoord = bottomRightCoord
        newBottomRightCoord.longitude = fmax(bottomRightCoord.longitude, newPoint.longitude)
        newBottomRightCoord.latitude = fmin(bottomRightCoord.latitude, newPoint.latitude)

        return (newTopLeftCoord, newBottomRightCoord)
    }
    
    static func extendBoundingBox(topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, multiPointOverlay:MKMultiPoint) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        
        var newTopLeftCoord = topLeftCoord
        var newBottomRightCoord = bottomRightCoord
        
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(multiPointOverlay.pointCount)
        multiPointOverlay.getCoordinates(coordinates, range: NSMakeRange(0, multiPointOverlay.pointCount))
        
        for index in 0..<multiPointOverlay.pointCount {
            let currentCoordinate = coordinates[index]
            (newTopLeftCoord, newBottomRightCoord) = extendBoundingBox(newTopLeftCoord, bottomRightCoord: newBottomRightCoord, newPoint: currentCoordinate)
        }
        
        coordinates.dealloc(multiPointOverlay.pointCount)
        return (newTopLeftCoord, bottomRightCoord)
    }

    // Compute the bounding box for a list of MKMultiPoint overlay
    static func boundingBoxForOverlays(multiPointOverlays:[MKMultiPoint]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {

        var topLeftCoord = CLLocationCoordinate2DMake(-90, 180)
        var bottomRightCoord = CLLocationCoordinate2DMake(90, -180)

        for currentOverlay in multiPointOverlays {
            let (currentTopLeft, currentBottomRight) = boundingBoxForOverlay(currentOverlay)

            topLeftCoord.longitude = fmin(topLeftCoord.longitude, currentTopLeft.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, currentTopLeft.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, currentTopLeft.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, currentTopLeft.latitude)

            topLeftCoord.longitude = fmin(topLeftCoord.longitude, currentBottomRight.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, currentBottomRight.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, currentBottomRight.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, currentBottomRight.latitude)
        }

        return (topLeftCoord, bottomRightCoord)
    }

    // Compute the bounding box for an MKMultiPoint overlay
    static func  boundingBoxForOverlay(multiPointOverlay:MKMultiPoint) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(multiPointOverlay.pointCount)
        multiPointOverlay.getCoordinates(coordinates, range: NSMakeRange(0, multiPointOverlay.pointCount))

        var topLeftCoord = CLLocationCoordinate2DMake(-90, 180)
        var bottomRightCoord = CLLocationCoordinate2DMake(90, -180)

        for index in 0..<multiPointOverlay.pointCount {
            let currentCoordinate = coordinates[index]

            topLeftCoord.longitude = fmin(topLeftCoord.longitude, currentCoordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, currentCoordinate.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, currentCoordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, currentCoordinate.latitude)
        }

        coordinates.dealloc(multiPointOverlay.pointCount)
        return (topLeftCoord, bottomRightCoord)
    }

    // MARK: Pin customization
    static func customizePinForTableView(thePinAnnotation: MKPinAnnotationView, poi:PointOfInterest) {
        thePinAnnotation.animatesDrop = false
        thePinAnnotation.canShowCallout = false
        thePinAnnotation.pinTintColor = poi.parentGroup?.color
    }
    
    
    private struct NibIdentifier {
        static let calloutAccessoryView = "CallOutAccessoryView"
    }
    
    static func refreshDetailCalloutAccessoryView(poi:PointOfInterest, annotationView:MKAnnotationView, delegate:PoiCalloutDelegate) {
        let view = annotationView.detailCalloutAccessoryView as! CustomCalloutAccessoryView
        view.initWith(poi, delegate: delegate)
    }

    static func refreshPin(annotationView:WayPointPinAnnotationView, poi:PointOfInterest, delegate:PoiCalloutDelegate, type:PinAnnotationType, isFlyover:Bool = false) {
        annotationView.pinTintColor = getPinRouteColor(type, poi: poi)
        
        if isFlyover {
            annotationView.configureForFlyover(poi, delegate: delegate)
        } else {
            annotationView.configureWith(poi, delegate: delegate, type: type)
        }
    }

    enum PinAnnotationType {
        case routeStart, routeEnd, waypoint, normal
    }
    
    private static func getPinRouteColor(type:PinAnnotationType, poi:PointOfInterest) -> UIColor {
        switch type {
        case .routeStart:
            return MapColors.pinColorForRouteStart
        case .routeEnd:
            return MapColors.pinColorForRouteEnd
        case .waypoint:
            return poi.parentGroup!.color
        case .normal:
            return poi.parentGroup!.color
        }

    }
    
    static func createPin(poi:PointOfInterest) -> WayPointPinAnnotationView {
        let thePinAnnotation = WayPointPinAnnotationView(poi: poi)
        thePinAnnotation.animatesDrop = false
        thePinAnnotation.canShowCallout = true
        
        return thePinAnnotation
    }
    
    
    struct PolyLineType {
        static let automobile = "Auto"
        static let wakling = "Walk"
        static let transit = "Transit"
        static let fromCurrentPosition = "CurrentPosition"
    }
    
    static func customizePolyLine(overlay:MKPolyline) -> MKPolylineRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        if let title = overlay.title {
            switch title {
            case PolyLineType.automobile:
                renderer.strokeColor = MapColors.routeColorForCar
            case PolyLineType.wakling:
                renderer.strokeColor = MapColors.routeColorForWalking
            case PolyLineType.transit:
                renderer.strokeColor = MapColors.routeColorForTransit
            case PolyLineType.fromCurrentPosition:
                renderer.strokeColor = MapColors.routeColorForCurrentPosition
            default:
                renderer.strokeColor = MapColors.routeColorForUnknown
            }
        }
        renderer.lineWidth = 3.0
        return renderer
    }
    
    static func getRendererForMonitoringRegion(overlay:MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.greenColor()
        renderer.lineWidth = 1.0
        renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.3)
        return renderer
    }

    static func getSnapshot(view:UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, (view.window?.screen.scale)!)
        view.drawViewHierarchyInRect(view.frame, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return snapshotImage!
    }
    
    // MARK: Utils
    
    static func distanceFromTo(fromCoordinate:CLLocationCoordinate2D, toCoordinate:CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distanceFromLocation(toLocation)
        return distanceFromTo
    }
    
    // MARK: MapSnapshot utils
    static func addCircleInMapSnapshot(centerCoordinate:CLLocationCoordinate2D, radius:Double, mapSnapshot:MKMapSnapshot) {
        // Append the monitoring region
        let background = CAShapeLayer()
        
        // Compute Point to display the circle area
        let regionForMonitoring = MKCoordinateRegionMakeWithDistance(centerCoordinate, radius, radius)
        let maxLatitude = regionForMonitoring.center.latitude + regionForMonitoring.span.latitudeDelta
        let minLatitude = regionForMonitoring.center.latitude - regionForMonitoring.span.latitudeDelta
        
        let maxLongitude = regionForMonitoring.center.longitude + regionForMonitoring.span.longitudeDelta
        let minLongitude = regionForMonitoring.center.longitude - regionForMonitoring.span.longitudeDelta
        
        let minPoint = mapSnapshot.pointForCoordinate(CLLocationCoordinate2DMake(minLatitude, regionForMonitoring.center.longitude))
        let maxPoint = mapSnapshot.pointForCoordinate(CLLocationCoordinate2DMake(maxLatitude, regionForMonitoring.center.longitude))
        let deltaLatPoint = abs(maxPoint.y - minPoint.y)
        
        let minLongPoint = mapSnapshot.pointForCoordinate(CLLocationCoordinate2DMake(regionForMonitoring.center.latitude, minLongitude))
        let maxLongPoint = mapSnapshot.pointForCoordinate(CLLocationCoordinate2DMake(regionForMonitoring.center.latitude, maxLongitude))
        let deltaLongPoint = abs(maxLongPoint.x - minLongPoint.x)
        
        let rectMonitoringRegion = CGRectMake(mapSnapshot.pointForCoordinate(centerCoordinate).x - (deltaLatPoint/2),
                                              mapSnapshot.pointForCoordinate(centerCoordinate).y - (deltaLongPoint/2),
                                              deltaLatPoint, deltaLongPoint)
        let path = UIBezierPath(ovalInRect: rectMonitoringRegion)
        background.path = path.CGPath
        background.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.3).CGColor
        background.strokeColor = UIColor.greenColor().CGColor
        background.lineWidth = 1
        background.setNeedsDisplay()
        background.renderInContext(UIGraphicsGetCurrentContext()!)
    }
    
    static func addAnnotationInMapSnapshot(annotation:MKAnnotation, tintColor:UIColor, mapSnapshot:MKMapSnapshot) {
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "")
        pinAnnotation.pinTintColor = tintColor
        if let pinImage = pinAnnotation.image {
            // Convert the Geo Coordinates of the POI into point coordinate in the Map
            var pinImagePoint = mapSnapshot.pointForCoordinate(annotation.coordinate)
            
            // We want to have the bottom point of the Pin to show the POI position
            // then we need to substract the height of the Pin
            pinImagePoint.y = pinImagePoint.y - pinAnnotation.frame.size.height
            // Draw the Pin image in the graphic context
            pinImage.drawAtPoint(pinImagePoint)
            
//            let rect = CGRectMake(
//                mapSnapshot.pointForCoordinate(annotation.coordinate).x,
//                mapSnapshot.pointForCoordinate(annotation.coordinate).y - pinAnnotation.frame.size.height,
//                pinAnnotation.frame.size.width,
//                pinAnnotation.frame.size.height)
            
            // Not very clear!
           // pinAnnotation.drawViewHierarchyInRect(rect, afterScreenUpdates: true)
        }
    }

    


}
