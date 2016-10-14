//
//  searchPoiViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class searchPoiViewCell: UITableViewCell {

    @IBOutlet weak var poiTitle: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var poiAddress: UILabel!
    @IBOutlet weak var poiCategoryImage: UIImageView!
    
    @IBOutlet weak var poiDistance: UILabel!

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var pinImage: UIImageView!
    
    func initWith(_ poi:PointOfInterest, index:Int, region:MKCoordinateRegion) {

        poiTitle.text = poi.poiDisplayName
        poiDescription.text = poi.poiDescription
        poiAddress.text = poi.address
        
        //MapUtils.customizePinForTableView(poiPinView, poi: poi)
        pinImage.image = poi.parentGroup!.pinImage
        editButton.tag = index

        
        let distance = MapUtils.distanceFromTo(poi.coordinate, toCoordinate: region.center)
        let distanceFormater = MKDistanceFormatter()
        poiTitle.text = "\(poi.poiDisplayName!)"
        poiDistance.text = "\(distanceFormater.string(fromDistance: distance))"
        
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.isHidden = false
            poiCategoryImage.tintColor = UIColor.black
        } else {
            poiCategoryImage.isHidden = true
        }
    }
}
