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

class WayPoint: NSManagedObject {

    // Contain the direction from this WayPoint to the next
    // The latest wayPoint of a route is nil
    var calculatedRoute:MKRoute?

    
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
            if let theRoute = calculatedRoute {
                let (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(theRoute.polyline)
                return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
            } else {
                return nil
            }
        }
    }

    override func prepareForDeletion() {
        wayPointParent?.willRemoveWayPoint(self)
    }
    
    func regionWith(_ annotations:[MKAnnotation]) -> MKCoordinateRegion? {
        if let theRoute = calculatedRoute {
            var (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(theRoute.polyline)
            (topLeft, bottomRight) = MapUtils.extendBoundingBox(topLeft, bottomRightCoord: bottomRight, annotations: annotations)
            return MapUtils.appendMargingToBoundBox(topLeft, bottomRightCoord: bottomRight)
        } else {
            return nil
        }
    }
    
    // get the bounding box to display the calculated route
    // SEB: Warning maybe the computation is not correct because the calculatedRoute is from current WayPoint to the next one??
    func boundingBox() -> (topLeft:CLLocationCoordinate2D, bottomRight:CLLocationCoordinate2D) {
        if let theRoute = calculatedRoute {
            let (topLeft, bottomRight) = MapUtils.boundingBoxForOverlay(theRoute.polyline)
            return (topLeft, bottomRight)
        } else {
            return (CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(0, 0))
        }
    }
}
