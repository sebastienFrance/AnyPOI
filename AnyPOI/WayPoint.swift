//
//  WayPoint.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(WayPoint)
class WayPoint: NSManagedObject {

    // Contains the transportType from the previous WayPoint to this WayPoint
    // For the first WayPoint, it has no meaning
    var transportType : MKDirectionsTransportType? {
        get {
            return MKDirectionsTransportType(rawValue: UInt(wayPointTransportType))
        }
        
        set {
            if let transportType = newValue?.rawValue {
                wayPointTransportType = Int64(transportType)
            } else {
                wayPointTransportType = Int64(MKDirectionsTransportType.automobile.rawValue)
            }
            
            // When we create a new WayPoint its parent route is not yet initialized
            if let parentRoute = wayPointParent {
                parentRoute.resetDirectionTo(self)
             }
            
        }
    }
   
    var region: MKCoordinateRegion? {
        get {
            if let routePolyline = routeInfos?.polyline {
                let (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(routePolyline)
                return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
            } else {
                return nil
            }
        }
    }

    // Contain the direction from this WayPoint to the next
    // The latest wayPoint of a route is nil
    var routeInfos: RouteInfos? {
        get {
            if let theRouteInfos = wayPointRouteInfos as? Data {
                return NSKeyedUnarchiver.unarchiveObject(with: theRouteInfos) as? RouteInfos
            } else {
                return nil
            }
        }
        set {
            if let newRouteInfos = newValue {
                wayPointRouteInfos = NSKeyedArchiver.archivedData(withRootObject: newRouteInfos) as NSObject?
            }
        }
    }

 
    override func prepareForDeletion() {
        wayPointParent?.willRemoveWayPoint(self)
    }
    
    func regionWith(_ annotations:[MKAnnotation]) -> MKCoordinateRegion? {
        if let theRoutePolyline = routeInfos?.polyline {
            var (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(theRoutePolyline)
            (topLeft, bottomRight) = MapUtils.extendBoundingBox(topLeft, bottomRightCoord: bottomRight, annotations: annotations)
            return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
        } else {
            return nil
        }
    }
    
    // get the bounding box to display the calculated route
    // SEB: Warning maybe the computation is not correct because the calculatedRoute is from current WayPoint to the next one??
    func boundingBox() -> (topLeft:CLLocationCoordinate2D, bottomRight:CLLocationCoordinate2D) {
        if let theRoutePolyline = routeInfos?.polyline {
            let (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(theRoutePolyline)
            return (topLeft, bottomRight)
        } else {
            return (CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(0, 0))
        }
    }
}
