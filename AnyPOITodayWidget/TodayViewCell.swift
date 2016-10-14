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
    
    fileprivate static func createPinImageForGroup(_ poi:PointOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        let annotationView = MKPinAnnotationView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        annotationView.pinTintColor = NSKeyedUnarchiver.unarchiveObject(with: poi.parentGroup?.groupColor as! Data) as! UIColor
        return annotationView.image
    }

    
    func initWith(_ poi:PointOfInterest) {
        
        //TodayViewCell.customizePinForTableView(pinAnnotation, poi: poi)
        pinImage.image = TodayViewCell.createPinImageForGroup(poi)
        if let currentLocation = LocationManager.sharedInstance.locationManager?.location {
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distance(from: targetLocation)
            let distanceFormater = MKDistanceFormatter()
            
            poiDisplayName.text = "\(poi.poiDisplayName!) ➔ \(distanceFormater.string(fromDistance: distance))"
        } else {
            poiDisplayName.text = "\(poi.poiDisplayName!)"
        }
        
        if #available(iOSApplicationExtension 10.0, *) {
            poiDisplayName.textColor = UIColor.black
        } else {
            poiDisplayName.textColor = UIColor.lightGray
        }
        
    }
}
