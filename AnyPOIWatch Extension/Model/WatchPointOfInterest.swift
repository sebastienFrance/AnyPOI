//
//  WatchPointOfInterest.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit
import ClockKit

class WatchPointOfInterest : Equatable {
    static func == (lhs: WatchPointOfInterest, rhs: WatchPointOfInterest) -> Bool {
        if lhs.title == rhs.title && lhs.distance == rhs.distance && lhs.color == rhs.color && lhs.category == rhs.category {
            return true
        } else {
            return false
        }
    }
    
    
    private let theProps:[String:String]
    
    init(properties:[String:String]) {
        theProps = properties
        category = CommonProps.categoryFrom(props: theProps)
        
        if let theColor = CommonProps.poiColorFrom(props: theProps) {
            color = theColor
        } else {
            color = UIColor.white
        }
    }
    
    var complicationTitle:CLKTextProvider {
        return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: title)
    }
    
    var complicationGlyph:CLKImageProvider {
        if let theCatgory = category {
            return CLKImageProvider(onePieceImage: theCatgory.glyph)
        } else {
            return CLKImageProvider(onePieceImage: CategoryUtils.defaultGroupCategory.glyph)
        }
    }
    
    var complicationCategory: CLKTextProvider {
        if let theCatgory = category {
            return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: theCatgory.localizedString)
        } else {
            return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "?")
        }
    }
    
    var complicationDistance: CLKTextProvider {
        return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: distance)
    }
    
    var title:String {
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
    
    var category: CategoryUtils.Category?
    var color: UIColor
    
    var coordinate: CLLocationCoordinate2D? {
        if let latitudeString = theProps[CommonProps.POI.latitude],
            let longitudeString = theProps[CommonProps.POI.longitude],
            let latitude = CLLocationDegrees(latitudeString),
            let longitude = CLLocationDegrees(longitudeString) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            return nil
        }
    }
    
    
}
