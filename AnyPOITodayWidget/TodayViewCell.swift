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
    
    @IBOutlet weak var poiDisplayName: UILabel!
    @IBOutlet weak var poiDistance: UILabel!
    
    @IBOutlet weak var markerAnnotation: MKMarkerAnnotationView!
    
    
    static func customizePinForTableView(_ thePinAnnotation: MKMarkerAnnotationView, poi:PointOfInterest) {
        thePinAnnotation.animatesWhenAdded = false
        thePinAnnotation.canShowCallout = false
        thePinAnnotation.markerTintColor = poi.parentGroup?.color
        thePinAnnotation.glyphImage = OnDemandCategoryUtils.getCategory(poi: poi).glyph 
    }

    func initMarker(poi:PointOfInterest) {
        TodayViewCell.customizePinForTableView(markerAnnotation, poi: poi)
    }

    
    func initWith(_ poi:PointOfInterest) {
        if let currentLocation = LocationManager.sharedInstance.locationManager?.location {
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distance(from: targetLocation)
            let distanceFormater = MKDistanceFormatter()
            
            let category = OnDemandCategoryUtils.getCategory(poi: poi).localizedString
            poiDistance.text = "\(category), \(distanceFormater.string(fromDistance: distance))"
            poiDisplayName.text = "\(poi.poiDisplayName!)"
        } else {
            poiDisplayName.text = "\(poi.poiDisplayName!)"
        }
        
        poiDisplayName.textColor = UIColor.black
    }
}
