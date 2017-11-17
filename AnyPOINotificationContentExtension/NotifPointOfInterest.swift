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

class NotifPointOfInterest : BasicPointOfInterest, MKAnnotation {
    
    var title:String? = "unknown"
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    override init(properties:[String:String]) {
        super.init(properties: properties)
        title = poiTitle
        coordinate = poiCoordinate
    }
    
}
