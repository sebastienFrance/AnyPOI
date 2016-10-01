//
//  CustomCalloutLeftAccessoryView.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CustomCalloutLeftAccessoryView: UIView {
    
    @IBOutlet weak var addWayPointButton: UIButton!
    @IBOutlet weak var removeWayPointButton: UIButton!
    @IBOutlet weak var routeFromCurrentLocationButton: UIButton!
    
    func configureWith(delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        
        switch type {
        case .normal:
            disableRemoveWayPoint()
            enableAddWayPoint(delegate)
            disableRouteFromCurrentLocation()
          break
        case .routeEnd:
            enableRemoveWayPoint(delegate)
            disableAddWayPoint()
            if !(MapViewController.instance?.routeDatasource?.isBeforeRouteSections)! {
                enableRouteFromCurrentLocation(delegate)
            } else {
                disableRouteFromCurrentLocation()
            }
        case .routeStart:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
            disableRouteFromCurrentLocation()
        case .waypoint:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
            disableRouteFromCurrentLocation()
       }
    }
    
    private func enableAddWayPoint(delegate:PoiCalloutDelegate) {
        addWayPointButton.hidden = false
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), forControlEvents: .TouchUpInside)
        addWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), forControlEvents: .TouchUpInside)
    }
    
    func disableAddWayPoint() {
        addWayPointButton.hidden = true
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func enableRemoveWayPoint(delegate:PoiCalloutDelegate) {
        removeWayPointButton.hidden = false
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), forControlEvents: .TouchUpInside)
        removeWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func disableRemoveWayPoint() {
        removeWayPointButton.hidden = true
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func enableRouteFromCurrentLocation(delegate:PoiCalloutDelegate) {
        if let routeManager = MapViewController.instance?.routeManager {
            if routeManager.isRouteFromCurrentLocationDisplayed {
                routeFromCurrentLocationButton.tintColor = UIColor.redColor()
            } else {
                routeFromCurrentLocationButton.tintColor = MapViewController.instance!.view.tintColor
            }
        }
        
        routeFromCurrentLocationButton.hidden = false
        routeFromCurrentLocationButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), forControlEvents: .TouchUpInside)
        routeFromCurrentLocationButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func disableRouteFromCurrentLocation() {
        routeFromCurrentLocationButton.hidden = true
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), forControlEvents: .TouchUpInside)
    }


}
