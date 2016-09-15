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
    
    func configureWith(delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        
        switch type {
        case .normal:
            disableRemoveWayPoint()
            enableAddWayPoint(delegate)
          break
        case .routeEnd:
            enableRemoveWayPoint(delegate)
            disableAddWayPoint()
        case .routeStart:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
        case .waypoint:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
       }
    }
    
    private func enableAddWayPoint(delegate:PoiCalloutDelegate) {
        addWayPointButton.hidden = false
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), forControlEvents: .TouchUpInside)
        addWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), forControlEvents: .TouchUpInside)
    }
    
    func disableAddWayPoint() {
        addWayPointButton.hidden = true
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), forControlEvents: .TouchUpInside)
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

}
