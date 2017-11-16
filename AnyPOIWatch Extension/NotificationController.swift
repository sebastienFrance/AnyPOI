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
    @IBOutlet var theMessage: WKInterfaceLabel!
    @IBOutlet var theCategoryImage: WKInterfaceImage!
    @IBOutlet var thePoiName: WKInterfaceLabel!
    @IBOutlet var thePoiCategory: WKInterfaceLabel!
    @IBOutlet var theDescriptionGroup: WKInterfaceGroup!
    @IBOutlet var theAddress: WKInterfaceLabel!
    
    override init() {
        super.init()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
 
        if let thePoi = poi {
            theMap.addAnnotation(thePoi.coordinate, with: WKInterfaceMapPinColor.green)
            theMap.setRegion(MKCoordinateRegionMakeWithDistance(thePoi.coordinate, 200, 200))
            
            theCategoryImage.setImage(thePoi.category?.glyph)
            theCategoryImage.setTintColor(UIColor.white)
            thePoiName.setText(thePoi.title)
            thePoiCategory.setText(thePoi.category?.localizedString)
            theDescriptionGroup.setBackgroundColor(thePoi.color.withAlphaComponent(0.3))
            theAddress.setText(thePoi.address)
        }
    }

    override func didAppear() {
        super.didAppear()
   }
    
    override func didDeactivate() {
        super.didDeactivate()
   }

    
    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
        NSLog("\(#function) notification has been received")
        
        let userInfo = notification.request.content.userInfo
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
            poi = WatchPointOfInterest(properties:pois)
        }
        
        theMessage.setText(notification.request.content.body)
        
        completionHandler(.custom)
    }
    
}
