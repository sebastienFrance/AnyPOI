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
    
    func showPOIOnMap(_ poi : PointOfInterest, isSelected:Bool)
    func showGroupOnMap(_ group : GroupOfInterest)
    func showMapLocation(_ mapItem: MKMapItem)
    func showWikipediaOnMap(_ wikipedia : Wikipedia)

    var theSearchController:UISearchController? {
        get 
    }
}
