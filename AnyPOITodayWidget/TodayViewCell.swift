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
    
    @IBOutlet weak var pinImage: UIImageView!
//    static func customizePinForTableView(thePinAnnotation: MKPinAnnotationView, poi:PointOfInterest) {
//        thePinAnnotation.animatesDrop = false
//        thePinAnnotation.canShowCallout = false
//        
//        thePinAnnotation.pinTintColor = NSKeyedUnarchiver.unarchiveObjectWithData(poi.parentGroup?.groupColor as! NSData) as! UIColor
//    }
    
    private static func createPinImageForGroup(poi:PointOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        let annotationView = MKPinAnnotationView(frame: CGRectMake(0, 0, imageSize, imageSize))
        annotationView.pinTintColor = NSKeyedUnarchiver.unarchiveObjectWithData(poi.parentGroup?.groupColor as! NSData) as! UIColor
        return annotationView.image
    }

    
    func initWith(poi:PointOfInterest) {
        
        //TodayViewCell.customizePinForTableView(pinAnnotation, poi: poi)
        pinImage.image = TodayViewCell.createPinImageForGroup(poi)
        if let currentLocation = LocationManager.sharedInstance.locationManager?.location {
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distanceFromLocation(targetLocation)
            let distanceFormater = MKDistanceFormatter()
            
            poiDisplayName.text = "\(poi.poiDisplayName!) ➔ \(distanceFormater.stringFromDistance(distance))"
        } else {
            poiDisplayName.text = "\(poi.poiDisplayName!)"
        }
        
        if #available(iOSApplicationExtension 10.0, *) {
            poiDisplayName.textColor = UIColor.blackColor()
        } else {
            poiDisplayName.textColor = UIColor.lightGrayColor()
        }
        
    }
}
