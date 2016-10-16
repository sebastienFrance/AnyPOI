//
//  RouteDetailsViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 03/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class RouteDetailsViewCell: UITableViewCell {

    @IBOutlet weak var poiTitle: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var poiAddress: UILabel!
    @IBOutlet weak var routeDistance: UILabel!
    @IBOutlet weak var poiPinView: MKPinAnnotationView!
    @IBOutlet weak var transportType: UISegmentedControl!
    @IBOutlet weak var poiCategoryImage: UIImageView!
    @IBOutlet weak var transportTypeStackView: UIStackView!

    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing == false {
            return // ignore any attempts to turn it off
        }
        
        super.setEditing(editing, animated: animated)
    }

    override var showsReorderControl: Bool {
        get {
            return true // short-circuit to on
        }
        set { }
    }


    // Initialize the cell properties from the POI
    func initializePOI(_ poi:PointOfInterest) {
        poiTitle.text = poi.poiDisplayName
        poiDescription.text = poi.poiDescription
        poiAddress.text = poi.address
        
        MapUtils.customizePinForTableView(poiPinView, poi: poi)
        
        routeDistance.text = ""
        transportType.isEnabled = false
        
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.black
            poiCategoryImage.isHidden = false
        } else {
            poiCategoryImage.isHidden = true
        }

        transportTypeStackView.isHidden = true
    }

    // Initialize transportType, distance... from the WayPoint
    func initializeWayPoint(_ fromWayPoint:WayPoint, index:Int) {
        if let route = fromWayPoint.routeInfos {
            let distanceFormatter = LengthFormatter()
            distanceFormatter.unitStyle = .short

            routeDistance.text = "\(distanceFormatter.string(fromMeters: route.distance)) in " + (Utilities.shortStringFromTimeInterval(route.expectedTravelTime) as String)
        }

        transportType.selectedSegmentIndex = MapUtils.transportTypeToSegmentIndex(fromWayPoint.transportType!)

        transportTypeStackView.isHidden = false
        transportType.isEnabled = true
        transportType.tag = index
    }
    
    func updateIndex(_ index:Int) {
        transportType.tag = index
    }


}


