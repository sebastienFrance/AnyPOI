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

    @IBOutlet weak var webSiteButton: UIButton!
    
    func initWith(_ mapItem:MKMapItem, index:Int, region:MKCoordinateRegion) {
        
        if mapItem.url != nil {
            webSiteButton.isHidden = false
            webSiteButton.tag = index
        } else {
            webSiteButton.isHidden = true
        }
        
        name.text = mapItem.name
        address.text = Utilities.getAddressFrom(mapItem.placemark)

        let distance = MapUtils.distanceFromTo(region.center, toCoordinate: mapItem.placemark.coordinate)
        let distanceFormater = MKDistanceFormatter()
        name.text  = "\(mapItem.name!)"
        distanceLabel.text = "\(distanceFormater.string(fromDistance: distance))"
    }
}
