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
    
    struct properties {
        static let wayPointRouteInfos = "wayPointRouteInfos"
    }


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
    
    var transportTypeString: String {
        return MapUtils.transportTypeDisplayName(transportType!)
    }
    
    var transportTypeFormattedEmoji:String {
        return MapUtils.transportTypeDisplayNameEmoji(transportType!)
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
            if let theUnarchivedRouteInfos = unarchivedRouteInfos {
                return theUnarchivedRouteInfos
            } else if let theRouteInfos = wayPointRouteInfos as? Data {
                 unarchivedRouteInfos = NSKeyedUnarchiver.unarchiveObject(with: theRouteInfos) as? RouteInfos
                return unarchivedRouteInfos
            } else {
                return nil
            }
        }
        set {
            if let newRouteInfos = newValue {
                unarchivedRouteInfos = newValue
                wayPointDistance = newRouteInfos.distance
                wayPointDuration = newRouteInfos.expectedTravelTime
                wayPointRouteInfos = NSKeyedArchiver.archivedData(withRootObject: newRouteInfos) as NSObject?
            } else {
                unarchivedRouteInfos = nil
                wayPointRouteInfos = nil
                wayPointDuration = Double.nan
                wayPointDistance = Double.nan
            }
        }
    }
    
    // Gives the distance & time of the full route or of the WayPoint currently displayed
    var distanceAndTime:String {
        get {
            if routeInfos != nil {
                if !wayPointDistance.isNaN && !wayPointDistance.isInfinite {
                    let distanceFormatter = LengthFormatter()
                    distanceFormatter.unitStyle = .short
                    let expectedTravelTime = Utilities.shortStringFromTimeInterval(wayPointDuration) as String
                    return String(format:("\(NSLocalizedString("RouteDatasource %@ in %@", comment: ""))"),
                                  distanceFormatter.string(fromMeters: wayPointDistance),
                                  expectedTravelTime)
                } else {
                    return NSLocalizedString("WayPointNoInfos", comment:"")
                }
            } else {
                return NSLocalizedString("RouteDetailsRouteNotAvailable", comment: "")
            }
        }
    }

    
    fileprivate var unarchivedRouteInfos: RouteInfos? = nil

    func initializeWith(poi:PointOfInterest, withTransportType:MKDirectionsTransportType) {
        transportType = withTransportType
        wayPointPoi = poi
        wayPointDistance = Double.nan
        wayPointDuration = Double.nan
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
    
    
    // This method is called at every commit (update, delete or create) to update SpotLight
    override func didSave() {
        wayPointParent?.updateInSpotLight()
    }
 }

extension WayPoint {
    
    func toGPXElement() -> XMLElement {
        let wptAttributes = [XSD.wptLatitudeAttr : "\(wayPointPoi!.coordinate.latitude)",
            XSD.wptLongitudeAttr : "\(wayPointPoi!.coordinate.longitude)"]
        var wptElement = XMLElement(elementName: XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.name, attributes: wptAttributes)
        
        let wptNameElement = XMLElement(elementName: XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.name.name, withValue: wayPointPoi!.poiDisplayName!)
        wptElement.addSub(element: wptNameElement)
        
        var extensionElement = XMLElement(elementName: XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.name)
        extensionElement.addSub(element: addWayPointToGPX(poiPointInternalURL: wayPointPoi!.objectID.uriRepresentation().absoluteString))
        
        wptElement.addSub(element: extensionElement)
        return wptElement
    }

    fileprivate func addWayPointToGPX(poiPointInternalURL:String) -> XMLElement {
        let attributes = [ XSD.wayPointInternalUrlAttr : objectID.uriRepresentation().absoluteString,
                           XSD.wayPointPoiInternalUrlAttr : poiPointInternalURL,
                           XSD.wayPointTransportTypeAttr : "\(wayPointTransportType)",
                           XSD.wayPointDistanceAttr: "\(wayPointDistance)",
                           XSD.wayPointDurationAttr: "\(wayPointDuration)"]
        
        return XMLElement(elementName: XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.name, attributes: attributes)
    }
    

}
