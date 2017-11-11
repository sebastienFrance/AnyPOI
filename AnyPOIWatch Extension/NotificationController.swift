//
//  NotificationController.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 30/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import Foundation
import UserNotifications


class NotificationController: WKUserNotificationInterfaceController {

    var poi:WatchPointOfInterest? = nil
    
    @IBOutlet var theMap: WKInterfaceMap!
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("\(#function)")

        if let thePoi = poi {
            NSLog("\(#function) poi is not null")
            theMap.addAnnotation(thePoi.coordinate!, with: WKInterfaceMapPinColor.green)
            theMap.setRegion(MKCoordinateRegionMakeWithDistance(thePoi.coordinate!, 200, 200))
        }
    }

    override func didAppear() {
        super.didAppear()
        NSLog("\(#function)")
//        if let thePoi = poi {
//            NSLog("\(#function) poi is not null")
//           theMap.addAnnotation(thePoi.coordinate!, with: WKInterfaceMapPinColor.green)
//            theMap.setRegion(MKCoordinateRegionMakeWithDistance(thePoi.coordinate!, 200, 200))
//        }
   }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NSLog("\(#function)")
   }

    
    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
        NSLog("\(#function) notification has been received")
        
        let userInfo = notification.request.content.userInfo
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
            poi = WatchPointOfInterest(properties:pois)
            NSLog("\(#function) found poi : \(poi!.title)")
        } else {
            NSLog("\(#function) poi not found in notification")
        }
        
        // This method is called when a notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.custom)
    }
    
}
