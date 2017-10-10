//
//  InterfaceController.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 30/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import Foundation

import WatchConnectivity

class InterfaceController: WKInterfaceController {
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        
        
        // Start Location Manager and add delegate to get update
        LocationManager.sharedInstance.startLocationManager()
        _ = LocationManager.sharedInstance.isLocationAuthorized()
        LocationManager.sharedInstance.delegate = self

        // get the list of POIs around the current position
//        if let location = LocationManager.sharedInstance.locationManager?.location {
//            let pois = getPoisAround(location)
//            for currentPoi in pois {
//                NSLog("\(#function) poi: \(currentPoi.poiDisplayName!)")
//            }
//        }

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

    fileprivate struct Cste {
        static let radiusInKm = 10.0
        static let maxRequestedResults = 5
    }

//    fileprivate func getPoisAround(_ location:CLLocation) -> [PointOfInterest] {
//        return PoiBoundingBox.getPoiAroundCurrentLocation(location, radius: Cste.radiusInKm, maxResult: Cste.maxRequestedResults)
//    }

}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function)")
        if let theError = error {
            NSLog("\(#function) an error has oocured: \(theError.localizedDescription)")
        } else {
            NSLog("\(#function) activation is completed with : \(activationState)")
            if session.isReachable, session.activationState == .activated {
                NSLog("\(#function) session is activated, send a message")
                
                if let location = LocationManager.sharedInstance.locationManager?.location {
                    
                    session.sendMessage([ "value" : "hello", "latitude" : location.coordinate.latitude],
                                        replyHandler: { result in
                                            NSLog("\(#function) get a result!")
                                            NSLog("Result contains \(result["response"]!)")
                                            
                    }) { error in
                        NSLog("\(#function) an error has oocured: \(error.localizedDescription)")
                    }
                    var theCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate
                    let data = Data(bytes: &theCoordinate, count: MemoryLayout<CLLocationCoordinate2D>.size)
                    session.sendMessageData(data, replyHandler: { resultData in
                        NSLog("\(#function) has received result data")
                    }, errorHandler: { error in
                        NSLog("\(#function) error with resultData: \(error.localizedDescription)")
                    })
                    
                } else {
                    NSLog("\(#function) userlocation not available")
                }
            } else {
                NSLog("\(#function) session is not reachable or not activated")
            }
        }
    }
}
        
        

extension InterfaceController: LocationUpdateDelegate {
    
    // Update the list of POIs when the user location has changed
    func locationUpdated(_ locations: [CLLocation]) {
    }
}
