//
//  TodayViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class TodayViewCell: UITableViewCell {
    
    @IBOutlet weak var pinAnnotation: MKPinAnnotationView!
    @IBOutlet weak var poiDisplayName: UILabel!
    
    static func customizePinForTableView(thePinAnnotation: MKPinAnnotationView, poi:PointOfInterest) {
        thePinAnnotation.animatesDrop = false
        thePinAnnotation.canShowCallout = false
        
        thePinAnnotation.pinTintColor = NSKeyedUnarchiver.unarchiveObjectWithData(poi.parentGroup?.groupColor as! NSData) as! UIColor
    }
    
    func initWith(poi:PointOfInterest) {
        
        TodayViewCell.customizePinForTableView(pinAnnotation, poi: poi)
        
        if let currentLocation = LocationManager.sharedInstance.locationManager?.location {
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distanceFromLocation(targetLocation)
            let distanceFormater = MKDistanceFormatter()
            
            poiDisplayName.text = "\(poi.poiDisplayName!) ➔ \(distanceFormater.stringFromDistance(distance))"
        } else {
            poiDisplayName.text = "\(poi.poiDisplayName!)"
        }
        
    }
}
