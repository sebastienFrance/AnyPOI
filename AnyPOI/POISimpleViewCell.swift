//
//  POISimpleViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import MapKit

class POISimpleViewCell: UITableViewCell {

    @IBOutlet weak var POITitle: UILabel!
    @IBOutlet weak var POIDescription: UILabel!
    @IBOutlet weak var POIAddress: UILabel!
    @IBOutlet weak var poiPinView: MKMarkerAnnotationView!
    

    func initializeWith(_ poi:PointOfInterest, index:Int) {
        POITitle.text = poi.poiDisplayName
        POIDescription.text = poi.poiDescription
        POIAddress.text = poi.address
    }
    
    func configureMarker(poi:PointOfInterest) {
        MapUtils.customizePinForTableView(poiPinView, poi: poi)
    }

}
