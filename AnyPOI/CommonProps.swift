//
//  CommonProps.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

struct CommonProps {
    
    struct Cste {
        static let radiusInKm = 10.0
        static let maxRequestedResults = 10
        static let diffDistanceForUrgentUpdate : CLLocationDistance = 300
    }
    
    static let isDebugEnabled = false

    struct userLocation {
        static let latitude = "lat"
        static let longitude = "long"
    }
    
    static let regionRadius = "regionRadius"
    static let listOfPOIs = "pois"
    static let singlePOI = "poi"
    static let maxRadius = "maxRadius"
    static let maxResults = "maxRes"
    static let debugRemainingComplicationTransferInfo = "dCompRemain"
    static let debugNotUrgentComplicationTransferInfo = "dNotUrgent"
    
    static let messageStatus = "status"
    
    enum MessageStatusCode:Int {
        case ok, erroriPhoneLocationNotAuthorized, erroriPhoneLocationNotAvailable, erroriPhoneCannotExtractCoordinatesFromMessage, errorWatchAppSendingMsgToiPhone, errorUnknown
    }
    
    struct POI {
        static let title = "title"
        static let address = "address"
        static let categoryId = "catId"
        static let groupCategory = "group"
        static let color = "color"
        static let distance = "dist"
        static let latitude = "lat"
        static let longitude = "long"
        static let phones = "phones"
    }
    
    static func categoryFrom(props:[String:String]) -> CategoryUtils.Category? {
        if let groupCategory = props[CommonProps.POI.groupCategory], let categoryId = props[CommonProps.POI.categoryId] {
            if let groupCategoryInt = Int16(groupCategory),
                let categoryIdInt = Int16(categoryId) {
                return CategoryUtils.findCategory(groupCategory: groupCategoryInt, categoryId: categoryIdInt, inCategories: CategoryUtils.localSearchCategories)
            }
        }
        
        return nil
    }
    
    static func poiColorFrom(props:[String:String]) -> UIColor? {
        if let colorString = props[CommonProps.POI.color] {
            return  ColorsUtils.getColor(rgba: colorString)
        }
        return nil
    }
    
    static func titleFrom(properties:[String:String]) -> String? {
        if CommonProps.isDebugEnabled {
            if let remaining = properties[CommonProps.debugRemainingComplicationTransferInfo],
                let urgentCounter = properties[CommonProps.debugNotUrgentComplicationTransferInfo] {
                if let title = properties[CommonProps.POI.title] {
                    return  "(\(remaining)/\(urgentCounter)) \(title)"
                }
            } else {
                return  properties[CommonProps.POI.title]  ?? nil
            }
        } else if let theTitle = properties[CommonProps.POI.title] {
                return theTitle
        }
        return nil
    }
    
    static func phonesFrom(properties:[String:String]) -> [String]? {
        if let phoneList = properties[CommonProps.POI.phones], phoneList.count > 0 {
            return phoneList.components(separatedBy: ",")
        }
        return nil
    }
    
    static func addressFrom(properties:[String:String]) -> String? {
        if let theAddress = properties[CommonProps.POI.address] {
            return theAddress
        }
        return nil
    }
    
    static func coordinateFrom(properties:[String:String]) -> CLLocationCoordinate2D? {
        if let latitudeString = properties[CommonProps.POI.latitude],
            let longitudeString = properties[CommonProps.POI.longitude],
            let latitude = CLLocationDegrees(latitudeString),
            let longitude = CLLocationDegrees(longitudeString) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return nil
    }
    
    static func distanceFrom(properties:[String:String]) -> String? {
        if let distanceString = properties[CommonProps.POI.distance], let measuredDistance = CLLocationDistance(distanceString) {
            return "\(MKDistanceFormatter().string(fromDistance: measuredDistance))"
        }
        return nil
    }

}
