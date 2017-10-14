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
    
    override init() {
        super.init()
        NSLog("\(#function) called")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NSLog("\(#function) called")

        InterfaceController.sharedInstance = self
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            NSLog("\(#function) WCSession is supported")
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

        NSLog("\(#function) called")

    }
    
    func refresh() {
        NSLog("\(#function) called")
        if WCSession.isSupported() {
            NSLog("\(#function) session is supported")
            let session = WCSession.default
            
            if session.activationState == .activated {
                getPOIsAround(session:session)
            } else {
                
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("\(#function) called")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NSLog("\(#function) called")

    }

    private struct Cste {
        static let radiusInKm = 10.0
        static let maxRequestedResults = 10
    }

    private struct Storyboard {
        static let poiRowId = "AnyPOIRow"
    }
    
    var watchPOIs = [WatchPointOfInterest]()
    
    func getPOIsAround(session: WCSession) {
        if let location = LocationManager.sharedInstance.locationManager?.location {
            
            // Must cast all value to Any else it raises an error because CLLLocationDegree and Int would create
            // an hetereogenous dictionary
            let messageContent = [ CommonProps.userLocation.latitude : location.coordinate.latitude as Any,
                                   CommonProps.userLocation.longitude : location.coordinate.longitude as Any,
                                   CommonProps.maxRadius : Cste.radiusInKm as Any,
                                   CommonProps.maxResults : Cste.maxRequestedResults as Any]
            
            session.sendMessage(messageContent,
                                replyHandler: { result in
                                    
                                    if let pois = result[CommonProps.listOfPOIs] as? [[String:String]] {
                                        
                                        self.anyPOITable.setNumberOfRows(pois.count, withRowType: Storyboard.poiRowId)
                                        var i = 0
                                        self.watchPOIs.removeAll()
                                        for props in pois {
                                            if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                                                let watchPOI = WatchPointOfInterest(properties:props)
                                                self.watchPOIs.append(watchPOI)
                                                InterfaceController.updateRowWith(row: controller, watchPOI: watchPOI)
                                            }
                                            i += 1
                                        }
                                    }
             }) { error in
                NSLog("\(#function) an error has oocured: \(error.localizedDescription)")
            }
        } else {
            NSLog("\(#function) userlocation not available")
        }
    }
    
    /* Example of sendMessage with Data
     
     var theCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate
     let data = Data(bytes: &theCoordinate, count: MemoryLayout<CLLocationCoordinate2D>.size)
     session.sendMessageData(data, replyHandler: { resultData in
     NSLog("\(#function) has received result data")
     }, errorHandler: { error in
     NSLog("\(#function) error with resultData: \(error.localizedDescription)")
     })
     
     */
    
    
    static func updateRowWith(row:AnyPOIRowController, watchPOI:WatchPointOfInterest) {
        row.titleLabel.setText(watchPOI.title)
        row.theCategory.setImage(watchPOI.category?.glyph)
        row.theCategory.setTintColor(UIColor.white)
        row.theGroupOfCategoryImage.setBackgroundColor(watchPOI.color)
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        
        NSLog("\(#function) row selected  \(rowIndex)")
        
        return watchPOIs[rowIndex]
    }
    
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
                getPOIsAround(session:session)
            } else {
                NSLog("\(#function) session is not reachable or not activated")
            }
        }
    }
}
        
        

extension InterfaceController: LocationUpdateDelegate {
    
    // Update the list of POIs when the user location has changed
    func locationUpdated(_ locations: [CLLocation]) {
        NSLog("\(#function) userlocation has changed")
    }
}
