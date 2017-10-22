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
    
    private var watchPOIs = [WatchPointOfInterest]()
    
    var nearestPOI:WatchPointOfInterest? = nil

    
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

        
        
//        // Start Location Manager and add delegate to get update
//        LocationManager.sharedInstance.startLocationManager()
//        _ = LocationManager.sharedInstance.isLocationAuthorized()
//        LocationManager.sharedInstance.delegate = self

    }
    
    override func didAppear() {
        super.didAppear()
        NSLog("\(#function) called")

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
                NSLog("\(#function) Warning: not activated")

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
        static let emptyTableId = "EmptyPOITable"
    }
    
    
    func getPOIsAround(session: WCSession) {
       // if let location = LocationManager.sharedInstance.locationManager?.location {
            
            // Must cast all value to Any else it raises an error because CLLLocationDegree and Int would create
            // an hetereogenous dictionary
            let messageContent = [ //CommonProps.userLocation.latitude : location.coordinate.latitude as Any,
                                   //CommonProps.userLocation.longitude : location.coordinate.longitude as Any,
                                   CommonProps.maxRadius : Cste.radiusInKm as Any,
                                   CommonProps.maxResults : Cste.maxRequestedResults as Any]
        
        if session.isReachable {
            NSLog("\(#function) Session is reachable")
        } else {
            NSLog("\(#function) Warning: Session is not reachable")
        }
        
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
                                    } else {
                                        self.refreshWatchPointOfInterest(newWatchPOIs: [])
                                    }
            }) { error in
                NSLog("\(#function) an error has oocured: \(error.localizedDescription)")
            }
//        } else {
//            NSLog("\(#function) userlocation not available")
//            self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
//            if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
//                controller.titleLabel.setText("Please, enable user location")
//            }
//
//        }
    }

    func refreshWatchPointOfInterest(newWatchPOIs:[WatchPointOfInterest]) {
        
        // When there's no POI around the user, we just display a table with a message displaying there's no POI
        if newWatchPOIs.count == 0 {
            self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
            if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
                controller.titleLabel.setText("No data available")
            }
            let hasToRefreshComplication = watchPOIs.count > 0
            watchPOIs = newWatchPOIs
            if hasToRefreshComplication {
                nearestPOI = watchPOIs[0]
                refreshComplication()
            }
            return
        }
        
        
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
            nearestPOI = watchPOIs[0]
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
                nearestPOI = watchPOIs[0]
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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        NSLog("\(#function) received user info")
        
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
            nearestPOI = WatchPointOfInterest(properties:pois)
            NSLog("\(#function) nearest POI is \(nearestPOI?.title! ?? "no POI")")
            refreshComplication()
        } else {
            NSLog("\(#function) probably no POI around, still need to refresh the complication")
            nearestPOI = nil
            refreshComplication()
        }
    }
}
        
        


