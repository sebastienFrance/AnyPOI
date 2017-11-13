//
//  NotificationViewController.swift
//  AnyPOINotificationContentExtension
//
//  Created by Sébastien Brugalières on 13/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MapKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var theMapView: MKMapView!
    @IBOutlet weak var theOtherLabel: UILabel!
    @IBOutlet weak var theCategoryImage: UIImageView!
    @IBOutlet weak var theAddress: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        
        //let size = view.bounds.size
       // preferredContentSize = CGSize(width: size.width, height: size.height)
    }
    
    func didReceive(_ notification: UNNotification) {
        topLabel.text = notification.request.content.body
        
        let userInfo = notification.request.content.userInfo
        
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
            let poi = WatchPointOfInterest(properties:pois)
            theMapView.setRegion(MKCoordinateRegionMakeWithDistance(poi.coordinate!, 200, 200), animated: false)
            theOtherLabel.text = poi.category?.localizedString
            theCategoryImage.image = poi.category?.glyph
            theAddress.text = poi.address
        } 
        
        
    }

}
