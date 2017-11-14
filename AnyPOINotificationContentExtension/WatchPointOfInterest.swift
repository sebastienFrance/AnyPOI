//
//  WatchPointOfInterest.swift
//  AnyPOINotificationContentExtension
//
//  Created by Sébastien Brugalières on 13/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//



import Foundation
import CoreLocation
import MapKit
import UIKit

class WatchPointOfInterest : NSObject, MKAnnotation {
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? WatchPointOfInterest {
            if title == other.title && distance == other.distance && color == other.color && category == other.category {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    
    private let theProps:[String:String]
    
    init(properties:[String:String]) {
        theProps = properties
    }
    
    

    var phones:[String] {
        if let phones = theProps[CommonProps.POI.phones], phones.count > 0 {
            return phones.components(separatedBy: ",")
        } else {
            return [String]()
        }
    }
    
    var address:String {
        if let theAddress = theProps[CommonProps.POI.address] {
            return theAddress
        } else {
            return "no Address available"
        }
    }
    
    var distance:String {
        if let distanceString = theProps[CommonProps.POI.distance], let distance = CLLocationDistance(distanceString) {
            return "\(MKDistanceFormatter().string(fromDistance: distance))"
        } else {
            return "?"
        }
    }
    
    var category: CategoryUtils.Category? {
        return CommonProps.categoryFrom(props: theProps)
    }
    
    var color: UIColor {
        if let color = CommonProps.poiColorFrom(props: theProps) {
            return color
        } else {
            return UIColor.white
        }
    }
    
    //MARK: MKAnnotation protocol
    var title:String? {
        if CommonProps.isDebugEnabled {
            if let remaining = theProps[CommonProps.debugRemainingComplicationTransferInfo], let urgentCounter = theProps[CommonProps.debugNotUrgentComplicationTransferInfo] {
                return  "(\(remaining)/\(urgentCounter)) \(theProps[CommonProps.POI.title]!)"
            } else {
                return  theProps[CommonProps.POI.title]  ?? "unknown"
            }
        } else {
            if let theTitle = theProps[CommonProps.POI.title] {
                return theTitle
            } else {
                return "unknown"
            }
        }
    }
    
    var subtitle: String? {
        return "subTitle"
    }
    
    var coordinate: CLLocationCoordinate2D {
        if let latitudeString = theProps[CommonProps.POI.latitude],
            let longitudeString = theProps[CommonProps.POI.longitude],
            let latitude = CLLocationDegrees(latitudeString),
            let longitude = CLLocationDegrees(longitudeString) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }

    
}
