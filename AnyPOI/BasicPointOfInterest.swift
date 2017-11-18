//
//  BasicPointOfInterest.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//


import Foundation
import CoreLocation
import MapKit
import UIKit

class BasicPointOfInterest : NSObject {
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? BasicPointOfInterest {
            if poiTitle == other.poiTitle && distance == other.distance && color == other.color && category == other.category {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    
    var poiTitle:String = "unknown"
    var phones = [String]()
    var address = "no Address available"
    var distance = "?"
    var category: CategoryUtils.Category?
    var color = UIColor.white
    var poiCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    init(properties:[String:String]) {
        category = CommonProps.categoryFrom(props: properties) ?? CategoryUtils.defaultGroupCategory
        
        if let theColor = CommonProps.poiColorFrom(props: properties) {
            color = theColor
        }
        
        if let theTitle = CommonProps.titleFrom(properties: properties) {
            poiTitle = theTitle
        }
        
        if let phoneList = CommonProps.phonesFrom(properties: properties) {
            phones = phoneList
        }
        
        if let theAddress = CommonProps.addressFrom(properties: properties){
            address = theAddress
        }
        
        if let theCoordinate = CommonProps.coordinateFrom(properties: properties) {
            poiCoordinate = theCoordinate
        }
        
        if let distanceString = CommonProps.distanceFrom(properties: properties) {
            distance = distanceString
        }
    }
    
}
