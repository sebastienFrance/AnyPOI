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

    override func setEditing(editing: Bool, animated: Bool) {
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
    func initializePOI(poi:PointOfInterest) {
        poiTitle.text = poi.poiDisplayName
        poiDescription.text = poi.poiDescription
        poiAddress.text = poi.address
        
        MapUtils.customizePinForTableView(poiPinView, poi: poi)
        
        routeDistance.text = ""
        transportType.enabled = false
        
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.blackColor()
            poiCategoryImage.hidden = false
        } else {
            poiCategoryImage.hidden = true
        }

        transportTypeStackView.hidden = true
    }

    // Initialize transportType, distance... from the WayPoint
    func initializeWayPoint(fromWayPoint:WayPoint, index:Int) {
        if let route = fromWayPoint.calculatedRoute {
            let distanceFormatter = NSLengthFormatter()
            distanceFormatter.unitStyle = .Short

            routeDistance.text = "\(distanceFormatter.stringFromMeters(route.distance)) in " + (Utilities.shortStringFromTimeInterval(route.expectedTravelTime) as String)
        }

        transportType.selectedSegmentIndex = MapUtils.transportTypeToSegmentIndex(fromWayPoint.transportType!)

        transportTypeStackView.hidden = false
        transportType.enabled = true
        transportType.tag = index
    }
    
    func updateIndex(index:Int) {
        transportType.tag = index
    }


}


