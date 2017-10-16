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
    
    private var watchPOIs = [WatchPointOfInterest]()
    
    func nearestPOI() -> WatchPointOfInterest? {
        if watchPOIs.count > 0 {
            return watchPOIs[0]
        } else {
            return nil
        }
    }
    
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
                                        
                                        // Extract all new WatchPointOfInterests from the result
                                        var newestWatchPOIs = [WatchPointOfInterest]()
                                        for props in pois {
                                            let watchPOI = WatchPointOfInterest(properties:props)
                                            newestWatchPOIs.append(watchPOI)
                                        }
                                        
                                        self.refreshWatchPointOfInterest(newWatchPOIs: newestWatchPOIs)
                                    }
            }) { error in
                NSLog("\(#function) an error has oocured: \(error.localizedDescription)")
            }
        } else {
            NSLog("\(#function) userlocation not available")
        }
    }

    func refreshWatchPointOfInterest(newWatchPOIs:[WatchPointOfInterest]) {
        
        // When the watchPOIs contains nothing we just need to put all our new content
        if watchPOIs.count == 0 {
            self.anyPOITable.setNumberOfRows(newWatchPOIs.count, withRowType: Storyboard.poiRowId)
            var i = 0
            for watchPOI in newWatchPOIs {
                if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                    InterfaceController.updateRowWith(row: controller, watchPOI: watchPOI)
                }
                i += 1
            }
            
            watchPOIs = newWatchPOIs
            refreshComplication()
        } else {
            
            // Add missing rows
            if newWatchPOIs.count > watchPOIs.count {
                var indexes = IndexSet()
                for i in watchPOIs.count..<newWatchPOIs.count {
                    indexes.insert(i)
                }
                
                anyPOITable.insertRows(at: indexes, withRowType: Storyboard.poiRowId)
            } else if newWatchPOIs.count < watchPOIs.count {
                // Remove useless rows
                var indexes = IndexSet()
                for i in newWatchPOIs.count..<watchPOIs.count {
                    indexes.insert(i)
                }
                
                anyPOITable.removeRows(at: indexes)
            }
            
            
            // There was at least one POIs display, let's update the screen
            for i in 0..<newWatchPOIs.count {
                let watchPOI = newWatchPOIs[i]
                if i < watchPOIs.count {
                    // Update the row only if it contains something different
                    if watchPOI != watchPOIs[i], let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: watchPOI)
                    }
                } else {
                    // It's a new row that need to be configured
                    if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: watchPOI)
                    }
                }
            }
            
            // Check if the nearest POI has changed, if it has changed then we refresh the complication
            var hasToRefreshComplication = false
            if newWatchPOIs.count > 0 {
                if newWatchPOIs[0] != watchPOIs[0] {
                    hasToRefreshComplication = true
                }
            } else {
                hasToRefreshComplication = true
            }
            
            watchPOIs = newWatchPOIs
            if hasToRefreshComplication {
                refreshComplication()
            }
        }
    }
    
    private func refreshComplication() {
        let server = CLKComplicationServer.sharedInstance()
        if let complications = server.activeComplications {
            for complication in complications {
                server.reloadTimeline(for: complication)
            }
        }
    }
    
    
    /*
     // Extract all new WatchPointOfInterests from the result
     var newestWatchPOIs = [WatchPointOfInterest]()
     for props in pois {
     let watchPOI = WatchPointOfInterest(properties:props)
     newestWatchPOIs.append(watchPOI)
     }
     
     // If something has changed then we refresh the table
     if newestWatchPOIs != self.watchPOIs {
     self.anyPOITable.setNumberOfRows(newestWatchPOIs.count, withRowType: Storyboard.poiRowId)
     
     var i = 0
     for watchPOI in newestWatchPOIs {
     if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
     InterfaceController.updateRowWith(row: controller, watchPOI: watchPOI)
     }
     i += 1
     }
     
     // Check if the nearest POI has changed, if it has changed then we refresh the complication
     let newNearestPOI = newestWatchPOIs[0]
     let oldNearestPOI = self.watchPOIs.count > 0 ? self.watchPOIs[0] : nil
     
     self.watchPOIs = newestWatchPOIs
     if newNearestPOI != oldNearestPOI {
     // Update all the complication if the new nearest POI has been changed
     let server = CLKComplicationServer.sharedInstance()
     if let complications = server.activeComplications {
     for complication in complications {
     server.reloadTimeline(for: complication)
     }
     }
     }
     

 */
    
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
        row.titleLabel.setText("\(watchPOI.title!)\n\(watchPOI.distance!)")
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
