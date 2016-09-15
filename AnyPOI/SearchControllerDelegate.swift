//
//  SearchControllerDelegate.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 05/03/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

protocol SearchControllerDelegate: class {
    
    func showPOIOnMap(poi : PointOfInterest)
    func showGroupOnMap(group : GroupOfInterest)
    func showMapLocation(mapItem: MKMapItem)
    func showWikipediaOnMap(wikipedia : Wikipedia)

    var theSearchController:UISearchController? {
        get 
    }
}
