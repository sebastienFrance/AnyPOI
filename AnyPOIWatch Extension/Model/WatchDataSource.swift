//
//  WatchDataSource.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 04/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchKit


class WatchDataSource {
    
    static let sharedInstance = WatchDataSource()
    
    private(set) var pois = [WatchPointOfInterest]()
    private(set) var status = CommonProps.MessageStatusCode.ok
    private(set) var errorMsg = ""
    
    private(set) var nearestPOI: WatchPointOfInterest? = nil
    
    
    private init() {
    }
    
    func updateNearestPOIWith(poi:WatchPointOfInterest?) {
        if poi != nearestPOI {
            nearestPOI = poi
            updateComplications()
        }
    }
    
    func updateWith(newPOIs:[WatchPointOfInterest]) {
        status = CommonProps.MessageStatusCode.ok
        
        if pois != newPOIs {
            
            var updateComplication = false
            if newPOIs.count > 0 && newPOIs[0] != nearestPOI {
                nearestPOI = newPOIs[0]
                updateComplication = true
            } else if nearestPOI != nil && newPOIs.count == 0 {
                nearestPOI = nil
                updateComplication = true
            }
            
            pois = newPOIs
            if updateComplication {
                updateComplications()
            }
            
            updateWatchUI()
        } else {
            NSLog("\(#function) no change => no UI update")
        }
    }
    
    func updateWith(error:CommonProps.MessageStatusCode, msg:String = "") {
        status = error
        errorMsg = msg
        pois = [WatchPointOfInterest]()
        updateWatchUI()
    }
    
    private func updateComplications() {
        NSLog("\(#function)")
        let server = CLKComplicationServer.sharedInstance()
        if let complications = server.activeComplications {
            for complication in complications {
                server.reloadTimeline(for: complication)
            }
        }
    }

    
    private func updateWatchUI() {
        if Thread.isMainThread {
            InterfaceController.sharedInstance?.refreshTable()
        } else {
            DispatchQueue.main.async {
                InterfaceController.sharedInstance?.refreshTable()
            }
        }
    }
}
