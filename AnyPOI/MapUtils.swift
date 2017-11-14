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
    
    func showDetails(_ sender:UIButton)
    
    func zoomOnPoi(_ sender: UIButton)
    func showURL(_ sender: UIButton)
    func startPhoneCall(_ sender:UIButton)
    func startEmail(_ sender:UIButton)
    func startRoute(_ sender:UIButton)
    
    func trashWayPoint(_ sender:UIButton)
    func addWayPoint(_ sender:UIButton)
    func showRouteFromCurrentLocation(_ sender:UIButton)
    
    func startOrStopMonitoring(_ sender:UIButton)
}

//class SimpleAnnotation : NSObject, MKAnnotation {
//    var coordinate: CLLocationCoordinate2D
//    var title: String?
//    var subtitle: String?
//
//    init(sourceCoordinate:CLLocationCoordinate2D, sourceTitle:String?, sourceSubtitle:String?) {
//        coordinate = sourceCoordinate
//        title = sourceTitle
//        subtitle = sourceSubtitle
//    }
//}

class MapUtils {
    
    struct MapColors {
        static let pinColorForRouteStart = UIColor.green
        static let pinColorForRouteEnd = UIColor.red
        
        static let routeColorForCar = UIColor.blue
        static let routeColorForWalking = UIColor.purple
        static let routeColorForTransit = UIColor.yellow
        static let routeColorForCurrentPosition = UIColor.green
        static let routeColorForUnknown = UIColor.black
    }
    
    struct MapConstantes {
        static let defaultCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
    }

    
    static func getNameFromPlacemark(_ newPlacemark:CLPlacemark) -> String? {
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
    
    static func transportTypeToSegmentIndex(_ transportType:MKDirectionsTransportType) -> Int {
        switch transportType {
        case MKDirectionsTransportType.automobile:
            return 0
        case MKDirectionsTransportType.walking:
            return 1
        case MKDirectionsTransportType.any:
            return 2
        default:
            return 0
        }
        
    }
    
    static func segmentIndexToTransportType(_ segmentedControl:UISegmentedControl) -> MKDirectionsTransportType {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return MKDirectionsTransportType.automobile
        case 1:
            return MKDirectionsTransportType.walking
        case 2:
            return MKDirectionsTransportType.transit
        case 3:
            return MKDirectionsTransportType.any
        default:
            return MKDirectionsTransportType.automobile
        }
        
    }

    static func transportTypeDisplayName(_ transportType:MKDirectionsTransportType) -> String {
        switch transportType {
        case MKDirectionsTransportType.automobile:
            return "Automobile"
        case MKDirectionsTransportType.walking:
            return "Walking"
        case MKDirectionsTransportType.transit:
            return "Transit"
        default:
            return "Unknown"
        }
    }
    
    static func transportTypeDisplayNameEmoji(_ transportType:MKDirectionsTransportType) -> String {
        switch transportType {
        case MKDirectionsTransportType.automobile:
            return "🚘"
        case MKDirectionsTransportType.walking:
            return "🚶"
        case MKDirectionsTransportType.transit:
            return "🚊"
        default:
            return "Unknown"
        }
    }

    
    static func convertToLaunchOptionsDirection(_ transportType:MKDirectionsTransportType) -> String {
        switch transportType {
        case MKDirectionsTransportType.automobile:
            return MKLaunchOptionsDirectionsModeDriving
        case MKDirectionsTransportType.walking:
            return MKLaunchOptionsDirectionsModeWalking
        case MKDirectionsTransportType.transit:
            return MKLaunchOptionsDirectionsModeTransit
        case MKDirectionsTransportType.any:
            return MKLaunchOptionsDirectionsModeDriving
        default:
            return MKLaunchOptionsDirectionsModeDriving
        }
    }

    //MARK: Bounding box
    static func boundingBoxForAnnotations(_ annotations:[MKAnnotation]) -> MKCoordinateRegion {
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

    static func appendMargingToBoundBox(_ topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2DMake(topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5,
            topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5)

        let span = MKCoordinateSpanMake(fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2,
            fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2)

        return MKCoordinateRegionMake(center, span)
    }

    // Not used
    static func boundingBoxForAnnotationsNew(_ annotations:[MKAnnotation]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
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
    static func extendBoundingBox(_ topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, annotations:[MKAnnotation]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        
        var newTopLeftCoord = topLeftCoord
        var newBottomRightCoord = bottomRightCoord
        
        for currentAnnotation in annotations {
            (newTopLeftCoord, newBottomRightCoord) = extendBoundingBox(newTopLeftCoord, bottomRightCoord: newBottomRightCoord, annotation: currentAnnotation)
        }
        
        return (newTopLeftCoord, newBottomRightCoord)
    }
    
    // Extend a bouding box to include an annotation
    static func extendBoundingBox(_ topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, annotation:MKAnnotation) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        return extendBoundingBox(topLeftCoord, bottomRightCoord: bottomRightCoord, newPoint: annotation.coordinate)
    }

    // Extend a bounding box with an additional point
    static func extendBoundingBox(_ topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, newPoint:CLLocationCoordinate2D) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {

        var newTopLeftCoord = topLeftCoord
        newTopLeftCoord.longitude = fmin(topLeftCoord.longitude, newPoint.longitude)
        newTopLeftCoord.latitude = fmax(topLeftCoord.latitude, newPoint.latitude)
        
        var newBottomRightCoord = bottomRightCoord
        newBottomRightCoord.longitude = fmax(bottomRightCoord.longitude, newPoint.longitude)
        newBottomRightCoord.latitude = fmin(bottomRightCoord.latitude, newPoint.latitude)

        return (newTopLeftCoord, newBottomRightCoord)
    }
    
    static func extendBoundingBox(_ topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D, multiPointOverlay:MKMultiPoint) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        
        var newTopLeftCoord = topLeftCoord
        var newBottomRightCoord = bottomRightCoord
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: multiPointOverlay.pointCount)
        multiPointOverlay.getCoordinates(coordinates, range: NSMakeRange(0, multiPointOverlay.pointCount))
        
        for index in 0..<multiPointOverlay.pointCount {
            let currentCoordinate = coordinates[index]
            (newTopLeftCoord, newBottomRightCoord) = extendBoundingBox(newTopLeftCoord, bottomRightCoord: newBottomRightCoord, newPoint: currentCoordinate)
        }
        
        coordinates.deallocate(capacity: multiPointOverlay.pointCount)
        return (newTopLeftCoord, bottomRightCoord)
    }

    // Compute the bounding box for a list of MKMultiPoint overlay
    static func boundingBoxForOverlays(_ multiPointOverlays:[MKMultiPoint]) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {

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
    static func  boundingBoxForOverlay(_ multiPointOverlay:MKMultiPoint) -> (topLeftCoord: CLLocationCoordinate2D, bottomRightCoord:CLLocationCoordinate2D) {
        // SEB: Swift3 to be checked
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: multiPointOverlay.pointCount)
       // let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>(allocatingCapacity: multiPointOverlay.pointCount)
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

        coordinates.deallocate(capacity: multiPointOverlay.pointCount)
        return (topLeftCoord, bottomRightCoord)
    }

    // MARK: Pin customization
    static func customizePinForTableView(_ thePinAnnotation: MKMarkerAnnotationView, poi:PointOfInterest) {
        thePinAnnotation.animatesWhenAdded = false
        thePinAnnotation.canShowCallout = false
        thePinAnnotation.markerTintColor = poi.parentGroup?.color
        thePinAnnotation.glyphImage = poi.glyphImage
    }
    
    
    fileprivate struct NibIdentifier {
        static let calloutAccessoryView = "CallOutAccessoryView"
    }
    
    static func refreshDetailCalloutAccessoryView(_ poi:PointOfInterest, annotationView:MKAnnotationView, delegate:PoiCalloutDelegate) {
        let view = annotationView.detailCalloutAccessoryView as! CustomCalloutAccessoryView
        view.initWith(poi, delegate: delegate)
    }

    static func refreshPin(_ annotationView:WayPointPinAnnotationView, poi:PointOfInterest, delegate:PoiCalloutDelegate, type:PinAnnotationType, isFlyover:Bool = false) {
        annotationView.markerTintColor = getAnnotationColor(type, poi: poi)
        annotationView.glyphImage =  poi.glyphImage
        
        if isFlyover {
            annotationView.configureForFlyover(poi, delegate: delegate)
        } else {
            annotationView.configureWith(poi, delegate: delegate, type: type)
        }
    }

    enum PinAnnotationType {
        case routeStart, routeEnd, waypoint, normal
    }
    
    fileprivate static func getAnnotationColor(_ type:PinAnnotationType, poi:PointOfInterest) -> UIColor {
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
    
    static func createPin(_ poi:PointOfInterest) -> WayPointPinAnnotationView {
        let annotation = WayPointPinAnnotationView(poi: poi)
        annotation.animatesWhenAdded = false
        annotation.canShowCallout = true

        return annotation
    }
    
    
    struct PolyLineType {
        static let automobile = "Auto"
        static let wakling = "Walk"
        static let transit = "Transit"
        static let fromCurrentPosition = "CurrentPosition"
    }
    
    static func customizePolyLine(_ overlay:MKPolyline) -> MKPolylineRenderer {
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
        } else {
            renderer.strokeColor = MapColors.routeColorForUnknown
        }
        renderer.lineWidth = 3.0
        return renderer
    }
    
    static func getRendererForMonitoringRegion(_ overlay:MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.green
        renderer.lineWidth = 1.0
        renderer.fillColor = UIColor.green.withAlphaComponent(0.3)
        return renderer
    }

    static func getSnapshot(_ view:UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, (view.window?.screen.scale)!)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return snapshotImage!
    }
    
    // MARK: Utils
    
    static func distanceFromTo(_ fromCoordinate:CLLocationCoordinate2D, toCoordinate:CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let distanceFromTo = fromLocation.distance(from: toLocation)
        return distanceFromTo
    }
    
    static func configureMapImageFor(poi:PointOfInterest, mapSnapshot:MKMapSnapshot) -> UIImage? {
        return MapUtils.configureMapImageFor(poi:poi,
                                             mapSnapshot: mapSnapshot,
                                             withColor:poi.parentGroup!.color,
                                             withMonitoringCircle: poi.poiRegionNotifyEnter || poi.poiRegionNotifyExit,
                                             radius: poi.poiRegionRadius)        
     }
    
    static func configureMapImageFor(poi:PointOfInterest,
                                     mapSnapshot:MKMapSnapshot,
                                     withColor:UIColor,
                                     withMonitoringCircle:Bool = false,
                                     radius:Double = 0.0) -> UIImage? {
        let mapImage = mapSnapshot.image
        UIGraphicsBeginImageContextWithOptions(mapImage.size, true, 0)
        // Put the Map in the Graphic Context
        mapImage.draw(at: CGPoint(x: 0, y: 0))
        
        if withMonitoringCircle {
            MapUtils.addCircleIn(mapSnapshot: mapSnapshot, centerCoordinate:poi.coordinate, radius: radius)
        }
        MapUtils.addAnnotationIn(mapSnapshot: mapSnapshot, poi:poi, tintColor: withColor)
        
        // Get the final image from the Grapic context
        let snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
    
    static func configureMapImageFor(pois:[PointOfInterest], mapSnapshot:MKMapSnapshot, poiSizeInMap:CGFloat) -> UIImage? {
        let mapImage = mapSnapshot.image
        
        UIGraphicsBeginImageContextWithOptions(mapImage.size, true, mapImage.scale)
        // Put the Map in the Graphic Context
        mapImage.draw(at: CGPoint(x: 0, y: 0))
        
        for currentPoi in pois {
            
            // Draw the Pin image in the graphic context
            let background = CAShapeLayer()
            let rect = CGRect(x: mapSnapshot.point(for: currentPoi.coordinate).x,
                              y: mapSnapshot.point(for: currentPoi.coordinate).y,
                              width: poiSizeInMap,height: poiSizeInMap)
            let path = UIBezierPath(ovalIn: rect)
            background.path = path.cgPath
            background.fillColor = currentPoi.parentGroup!.color.cgColor
            background.strokeColor = UIColor.black.cgColor
            background.lineWidth = 1
            background.setNeedsDisplay()
            background.render(in: UIGraphicsGetCurrentContext()!)
        }
        
        // Get the final image from the Graphic context
        let snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
    
    // MARK: MapSnapshot utils
    static fileprivate func addCircleIn(mapSnapshot:MKMapSnapshot, centerCoordinate:CLLocationCoordinate2D, radius:Double) {
        // Append the monitoring region
        let background = CAShapeLayer()
        
        // Compute Point to display the circle area
        let regionForMonitoring = MKCoordinateRegionMakeWithDistance(centerCoordinate, radius, radius)
        let maxLatitude = regionForMonitoring.center.latitude + regionForMonitoring.span.latitudeDelta
        let minLatitude = regionForMonitoring.center.latitude - regionForMonitoring.span.latitudeDelta
        
        let maxLongitude = regionForMonitoring.center.longitude + regionForMonitoring.span.longitudeDelta
        let minLongitude = regionForMonitoring.center.longitude - regionForMonitoring.span.longitudeDelta
        
        let minPoint = mapSnapshot.point(for: CLLocationCoordinate2DMake(minLatitude, regionForMonitoring.center.longitude))
        let maxPoint = mapSnapshot.point(for: CLLocationCoordinate2DMake(maxLatitude, regionForMonitoring.center.longitude))
        let deltaLatPoint = abs(maxPoint.y - minPoint.y)
        
        let minLongPoint = mapSnapshot.point(for: CLLocationCoordinate2DMake(regionForMonitoring.center.latitude, minLongitude))
        let maxLongPoint = mapSnapshot.point(for: CLLocationCoordinate2DMake(regionForMonitoring.center.latitude, maxLongitude))
        let deltaLongPoint = abs(maxLongPoint.x - minLongPoint.x)
        
        let rectMonitoringRegion = CGRect(x: mapSnapshot.point(for: centerCoordinate).x - (deltaLatPoint/2),
                                              y: mapSnapshot.point(for: centerCoordinate).y - (deltaLongPoint/2),
                                              width: deltaLatPoint, height: deltaLongPoint)
        let path = UIBezierPath(ovalIn: rectMonitoringRegion)
        background.path = path.cgPath
        background.fillColor = UIColor.green.withAlphaComponent(0.3).cgColor
        background.strokeColor = UIColor.green.cgColor
        background.lineWidth = 1
        background.setNeedsDisplay()
        background.render(in: UIGraphicsGetCurrentContext()!)
    }
    
    static func pinImageFor(poi:PointOfInterest, tintColor:UIColor? = nil, size:Int = 40) -> UIImage? {
        let annotation = MKMarkerAnnotationView()
        
        if let markerColor = tintColor {
            annotation.markerTintColor = markerColor
        } else {
            annotation.markerTintColor = poi.parentGroup!.color
        }
        
        annotation.glyphImage = poi.glyphImage
        
        annotation.animatesWhenAdded = false
        annotation.glyphTintColor = UIColor.white
        annotation.titleVisibility = .hidden
        annotation.subtitleVisibility = .hidden
        
        // Force to fit the annotation in the 40x40 pixels
        annotation.contentMode = .scaleAspectFit
        annotation.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(annotation.bounds.size, false, 0.0)
        let result = annotation.drawHierarchy(in: CGRect(x:0,
                                                         y:0,
                                                         width:annotation.bounds.width,
                                                         height:annotation.bounds.height),
                                              afterScreenUpdates: true)
        if !result {
            NSLog("\(#function) warning, drawHierarchy has not completed")
        }
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return snapshotImageFromMyView
    }
    
    static fileprivate func addAnnotationIn(mapSnapshot:MKMapSnapshot, poi:PointOfInterest, tintColor:UIColor) {
        if let snapshotImageFromMyView = MapUtils.pinImageFor(poi: poi, tintColor: tintColor, size: 40) {
            var pinImagePoint = mapSnapshot.point(for: poi.coordinate)
            
            // We want to have the bottom point of the Pin to show the POI position
            // then we need to substract the height of the Pin
            pinImagePoint.y = pinImagePoint.y - snapshotImageFromMyView.size.height
            pinImagePoint.x = pinImagePoint.x - (snapshotImageFromMyView.size.width / 2.0)
            // Draw the Pin image in the graphic context
            snapshotImageFromMyView.draw(at: pinImagePoint)

        }
    }
}
