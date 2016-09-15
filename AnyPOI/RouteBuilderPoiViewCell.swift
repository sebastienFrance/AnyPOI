//
//  RouteBuilderPoiViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 03/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit


class RouteBuilderPoiViewCell: UITableViewCell {

    @IBOutlet weak var poiTitle: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var poiAddress: UILabel!
    @IBOutlet weak var poiCategoryImage: UIImageView!
    
    
    @IBOutlet weak var poiPinView: MKPinAnnotationView!
    
    func initWith(poi:PointOfInterest, index:Int) {
        poiTitle.text = poi.poiDisplayName
        poiDescription.text = poi.poiDescription
        poiAddress.text = poi.address
        
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.blackColor()
            poiCategoryImage.hidden = false
        } else {
            poiCategoryImage.hidden = true
        }
        
        MapUtils.customizePinForTableView(poiPinView, poi: poi)
     }
 }
