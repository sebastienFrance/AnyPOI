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
    

    fileprivate(set) static var sharedInstance:InterfaceController?
    
    @IBOutlet var anyPOITable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        InterfaceController.sharedInstance = self
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        
        
        // Start Location Manager and add delegate to get update
        LocationManager.sharedInstance.startLocationManager()
        _ = LocationManager.sharedInstance.isLocationAuthorized()
        LocationManager.sharedInstance.delegate = self

    }
    
    override func didAppear() {
        super.didAppear()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        
    }
    
    func refresh() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
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
                    
                    session.sendMessage([ "latitude" : location.coordinate.latitude, "longitude" : location.coordinate.longitude],
                                        replyHandler: { result in
                                            NSLog("\(#function) get a result!")
                                          
                                            
                                            self.anyPOITable.setNumberOfRows(result.count, withRowType: "AnyPOIRow")
                                            var i = 0
                                            for currentResult in result {
                                                if let props = currentResult.value as? [String:String] {
                                                    for currentProps in props {
                                                        NSLog("contains: \(currentProps.key) with \(currentProps.value)")
                                                        if currentProps.key == "title" {
                                                            if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                                                                controller.titleLabel.setText(currentProps.value)
                                                            }
                                                        }

                                                    }
                                                }
                                                i += 1
                                            }
  
                                            
                                            
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
