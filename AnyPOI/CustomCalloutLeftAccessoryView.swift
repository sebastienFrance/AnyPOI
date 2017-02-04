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
    
    func configureWith(_ delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        
        switch type {
        case .normal:
            disableRemoveWayPoint()
            enableAddWayPoint(delegate)
            disableRouteFromCurrentLocation()
            break
        case .routeEnd:
            enableRemoveWayPoint(delegate)
            disableAddWayPoint()
            enableRouteFromCurrentLocation(delegate)
        case .routeStart:
            // Do not authorize to add the route start as a new WayPoint when the route contains only the start
            if let wayPoints = MapViewController.instance?.routeDatasource?.wayPoints, wayPoints.count > 1 {
                enableAddWayPoint(delegate)
            } else {
                disableAddWayPoint()
            }
            enableRemoveWayPoint(delegate)
            enableRouteFromCurrentLocation(delegate)
        case .waypoint:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
            disableRouteFromCurrentLocation()
        }
    }
    
    fileprivate func enableAddWayPoint(_ delegate:PoiCalloutDelegate) {
        addWayPointButton.isHidden = false
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
        addWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
    }
    
    func disableAddWayPoint() {
        addWayPointButton.isHidden = true
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func enableRemoveWayPoint(_ delegate:PoiCalloutDelegate) {
        removeWayPointButton.isHidden = false
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
        removeWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func disableRemoveWayPoint() {
        removeWayPointButton.isHidden = true
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func enableRouteFromCurrentLocation(_ delegate:PoiCalloutDelegate) {
        if let fullRouteMode = MapViewController.instance?.routeDatasource?.isFullRouteMode, !fullRouteMode {
            
            if let routeManager = MapViewController.instance?.routeManager {
                // SEB SEB
                if let _ = routeManager.fromCurrentLocation {
                    routeFromCurrentLocationButton.tintColor = UIColor.red
                } else {
                    routeFromCurrentLocationButton.tintColor = MapViewController.instance!.view.tintColor
                }
            }
            
            routeFromCurrentLocationButton.isHidden = false
            routeFromCurrentLocationButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
            routeFromCurrentLocationButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
        } else {
            disableRouteFromCurrentLocation()
        }
    }
    
    fileprivate func disableRouteFromCurrentLocation() {
        routeFromCurrentLocationButton.isHidden = true
        routeFromCurrentLocationButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
    }


}
