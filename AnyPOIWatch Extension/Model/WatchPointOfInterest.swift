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
    
    var title = "unknown"
    var phones = [String]()
    var address = "no Address available"
    var distance = "?"
    var category: CategoryUtils.Category?
    var color = UIColor.white
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    init(properties:[String:String]) {
        category = CommonProps.categoryFrom(props: properties) ?? CategoryUtils.defaultGroupCategory
        
        if let theColor = CommonProps.poiColorFrom(props: properties) {
            color = theColor
        }
        
        if let theTitle = CommonProps.titleFrom(properties: properties) {
            title = theTitle
        }
        
        if let phoneList = CommonProps.phonesFrom(properties: properties) {
            phones = phoneList
        }

        if let theAddress = CommonProps.addressFrom(properties: properties){
            address = theAddress
        }
        
        if let theCoordinate = CommonProps.coordinateFrom(properties: properties) {
            coordinate = theCoordinate
        }

        if let distanceString = CommonProps.distanceFrom(properties: properties) {
            distance = distanceString
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
}
