//
//  LocalSearchTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 20/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import AddressBookUI

class LocalSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    
    func initWith(mapItem:MKMapItem, index:Int, region:MKCoordinateRegion) {
        let foundPois = POIDataManager.sharedInstance.findPOIWith(mapItem.name!, coordinates: mapItem.placemark.coordinate)
        if foundPois.count > 0 {
            addButton.enabled = false
        } else {
            addButton.enabled = true
        }
        
        if mapItem.url != nil {
            webSiteButton.hidden = false
            webSiteButton.tag = index
        } else {
            webSiteButton.hidden = true
        }
        
        name.text = mapItem.name
        address.text = Utilities.getAddressFrom(mapItem.placemark)
        addButton.tag = index

        let distance = MapUtils.distanceFromTo(region.center, toCoordinate: mapItem.placemark.coordinate)
        let distanceFormater = MKDistanceFormatter()
        name.text  = "\(mapItem.name!)"
        distanceLabel.text = "\(distanceFormater.stringFromDistance(distance))"
    }
}
