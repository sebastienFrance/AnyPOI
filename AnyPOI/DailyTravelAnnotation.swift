//
//  DailyTravelAnnotation.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 19/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class DailyTravelAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D

    var title:String?

    init(location: CLLocation, title:String) {
        coordinate = location.coordinate
        self.title = title
    }

}
