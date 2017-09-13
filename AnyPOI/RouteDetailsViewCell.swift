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
    @IBOutlet weak var poiPinView: MKMarkerAnnotationView!
    @IBOutlet weak var transportType: UISegmentedControl!
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
        
        
        
        routeDistance.text = ""
        transportType.isEnabled = false
        

        transportTypeStackView.isHidden = true
    }
    
    func configureMarker(poi:PointOfInterest) {
        MapUtils.customizePinForTableView(poiPinView, poi: poi)
    }

    // Initialize transportType, distance... from the WayPoint
    func initializeWayPoint(_ fromWayPoint:WayPoint, index:Int) {
        if let route = fromWayPoint.routeInfos {
            routeDistance.textColor = UIColor.black
            routeDistance.text = "\(route.distanceFormatted) in \(route.expectedTravelTimeFormatted)"
        } else {
            routeDistance.textColor = UIColor.red
            routeDistance.text = NSLocalizedString("RouteDetailsRouteNotAvailable", comment: "")
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


