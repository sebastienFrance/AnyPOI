//
//  WayPointPinAnnotationView.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 13/06/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class WayPointPinAnnotationView : MKPinAnnotationView {
    
    private struct NibIdentifier {
        static let calloutAccessoryView = "CallOutAccessoryView"
    }
    
    struct AnnotationId {
        static let wayPointAnnotationId = "WayPointAnnotationId"
    }
 
    init(poi:PointOfInterest) {
        super.init(annotation: poi, reuseIdentifier: AnnotationId.wayPointAnnotationId)
    }
    
    func configureWith(poi:PointOfInterest, delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        enablePoiDetailsAccessory()
        updateDetailCalloutAccessory(poi, delegate: delegate)
        configureWayPointLeftAccessory(delegate, type: type)
    }
    
    func configureForFlyover(poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        disablePoiDetailsAccessory()
        disableWayPointAccessory()
        
        let view = updateDetailCalloutAccessory(poi, delegate: delegate)
        
        view.navigationStackView.hidden = true
        view.actionsStackView.hidden = true
        detailCalloutAccessoryView = view
    }
    
    // If the view for the detailedAccessoryView already exists it's refreshed else it's allocated
    private func updateDetailCalloutAccessory(poi:PointOfInterest, delegate:PoiCalloutDelegate) -> CustomCalloutAccessoryView {
        if let accessoryView = detailCalloutAccessoryView as? CustomCalloutAccessoryView {
            accessoryView.refreshWith(poi)
            accessoryView.navigationStackView.hidden = false
            accessoryView.actionsStackView.hidden = false
            return accessoryView
        } else {
            let nib = UINib(nibName: NibIdentifier.calloutAccessoryView, bundle: nil)
            let view = nib.instantiateWithOwner(nil, options: nil)[0] as! CustomCalloutAccessoryView
            view.initWith(poi, delegate: delegate)
            detailCalloutAccessoryView = view
            return view
        }
    }

    private func configureWayPointLeftAccessory(delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        if let leftAccessoryView = leftCalloutAccessoryView {
            if leftAccessoryView.subviews.count == 1 {
                let leftCustomCallout = leftAccessoryView.subviews[0] as! CustomCalloutLeftAccessoryView
                leftCustomCallout.configureWith(delegate, type:type)
            }
        } else {
            let nib = UINib(nibName: "CallOutLeftAccessoryView", bundle: nil)
            let view = nib.instantiateWithOwner(nil, options: nil)[0] as! CustomCalloutLeftAccessoryView
            view.configureWith(delegate, type:type)
            let myView = UIView(frame: view.frame)
            myView.addSubview(view)
            leftCalloutAccessoryView = myView
        }
    }
        
    func enablePoiDetailsAccessory() {
        let rightButton = UIButton(type: .DetailDisclosure)
        rightButton.addTarget(nil, action: nil, forControlEvents: .TouchUpInside)
        rightCalloutAccessoryView = rightButton
    }
    
    func disablePoiDetailsAccessory() {
        rightCalloutAccessoryView = nil
    }
    
    func disableWayPointAccessory() {
        leftCalloutAccessoryView = nil
    }
    
    func disableAddWayPointAccessory() {
        if let leftAccessoryView = leftCalloutAccessoryView {
            if leftAccessoryView.subviews.count == 1 {
                let leftCustomCallout = leftAccessoryView.subviews[0] as! CustomCalloutLeftAccessoryView
                leftCustomCallout.disableAddWayPoint()
            }
        }
    }
        
    // This init method is systematically called by the parent
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }

    // This constructor is never used because this view is not created
    // by a storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
