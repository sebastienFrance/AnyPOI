//
//  POIDetailsInterfaceController.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import Foundation


class POIDetailsInterfaceController: WKInterfaceController {

    @IBOutlet var theMap: WKInterfaceMap!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let watchPOI = context as? WatchPointOfInterest {
            NSLog("\(#function) get a WatchPOI")
            theMap.addAnnotation(watchPOI.coordinate!, with: WKInterfaceMapPinColor.green)
            theMap.setRegion(MKCoordinateRegionMakeWithDistance(watchPOI.coordinate!, 200, 200))
        }
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
