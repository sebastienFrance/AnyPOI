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
        let theDetailsAccessoryView = configureDetailCalloutAccessory(poi: poi, delegate: delegate)
        
        theDetailsAccessoryView.configureRouteButtons(delegate, type:type)
        theDetailsAccessoryView.update(isFlyover:false)
    }
    
    func configureForFlyover(_ poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        disablePoiDetailsAccessory()
        
        let theDetailsAccessoryView = configureDetailCalloutAccessory(poi: poi, delegate: delegate, isFlyover: true)
        
        theDetailsAccessoryView.update(isFlyover:true)
   }
    
    // If the view for the detailedAccessoryView already exists it's refreshed else it's allocated
    fileprivate func configureDetailCalloutAccessory(poi:PointOfInterest, delegate:PoiCalloutDelegate, isFlyover:Bool = false) -> CustomCalloutAccessoryView {
        var theDetailsAccessoryView:CustomCalloutAccessoryView
        if let accessoryView = detailCalloutAccessoryView as? CustomCalloutAccessoryView {
            accessoryView.refreshWith(poi, delegate:delegate)
            theDetailsAccessoryView = accessoryView
        } else {
            let nib = UINib(nibName: NibIdentifier.calloutAccessoryView, bundle: nil)
            theDetailsAccessoryView = nib.instantiate(withOwner: nil, options: nil)[0] as! CustomCalloutAccessoryView
            theDetailsAccessoryView.initWith(poi, delegate: delegate)
            detailCalloutAccessoryView = theDetailsAccessoryView
        }
        
        return theDetailsAccessoryView
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
    
    
    
    func disableAddWayPointAccessory() {
        if let customCallout = rightCalloutAccessoryView as? CustomCalloutAccessoryView {
            customCallout.disableAddWayPoint()
        }
    }


    // This constructor is never used because this view is not created
    // by a storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
