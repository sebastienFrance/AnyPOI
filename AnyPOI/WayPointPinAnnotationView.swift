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
    
    fileprivate struct NibIdentifier {
        static let calloutAccessoryView = "CallOutAccessoryView"
    }
    
    struct AnnotationId {
        static let wayPointAnnotationId = "WayPointAnnotationId"
    }
 
    init(poi:PointOfInterest) {
        super.init(annotation: poi, reuseIdentifier: AnnotationId.wayPointAnnotationId)
    }
    
    func configureWith(_ poi:PointOfInterest, delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        enablePoiDetailsAccessory()
        updateDetailCalloutAccessory(poi, delegate: delegate)
        configureWayPointLeftAccessory(delegate, type: type)
    }
    
    func configureForFlyover(_ poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        disablePoiDetailsAccessory()
        disableWayPointAccessory()
        
        updateDetailCalloutAccessory(poi, delegate: delegate, isFlyover: true)
    }
    
    // If the view for the detailedAccessoryView already exists it's refreshed else it's allocated
    fileprivate func updateDetailCalloutAccessory(_ poi:PointOfInterest, delegate:PoiCalloutDelegate, isFlyover:Bool = false) {
        var theDetailsAccessoryView:CustomCalloutAccessoryView
        if let accessoryView = detailCalloutAccessoryView as? CustomCalloutAccessoryView {
            accessoryView.refreshWith(poi)
            theDetailsAccessoryView = accessoryView
        } else {
            let nib = UINib(nibName: NibIdentifier.calloutAccessoryView, bundle: nil)
            theDetailsAccessoryView = nib.instantiate(withOwner: nil, options: nil)[0] as! CustomCalloutAccessoryView
            theDetailsAccessoryView.initWith(poi, delegate: delegate)
            detailCalloutAccessoryView = theDetailsAccessoryView
        }
        
        theDetailsAccessoryView.navigationStackView.isHidden = isFlyover
        theDetailsAccessoryView.actionsStackView.isHidden = isFlyover
    }

    fileprivate func configureWayPointLeftAccessory(_ delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        if let leftAccessoryView = leftCalloutAccessoryView {
            if leftAccessoryView.subviews.count == 1 {
                let leftCustomCallout = leftAccessoryView as! CustomCalloutLeftAccessoryView
                leftCustomCallout.configureWith(delegate, type:type)
            }
        } else {
            let nib = UINib(nibName: "CallOutLeftAccessoryView", bundle: nil)
            let view = nib.instantiate(withOwner: nil, options: nil)[0] as! CustomCalloutLeftAccessoryView
            view.configureWith(delegate, type:type)
            leftCalloutAccessoryView = view
        }
    }
        
    func enablePoiDetailsAccessory() {
        let rightButton = UIButton(type: .detailDisclosure)
        // SEB: Swift3 don't understand this command?
        //rightButton.addTarget(nil, action: nil, for: .touchUpInside)
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
        

    // This constructor is never used because this view is not created
    // by a storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
