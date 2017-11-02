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
    
    private var displayedWatchPOIs = [WatchPointOfInterest]()
    
    var nearestPOI:WatchPointOfInterest? = nil

    
    @IBOutlet var anyPOITable: WKInterfaceTable!
    
    
    private var internalState = false
    private let internalQueue = DispatchQueue(label:"protectSendMsg") // Serial or Concurrent?
    
    var msgInProgress: Bool {
        get {
            return internalQueue.sync { internalState }
        }
        
        set (newState) {
            internalQueue.sync { internalState = newState }
        }
    }
    
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
    }
    
    override func didAppear() {
        super.didAppear()
        NSLog("\(#function) called")

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
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
    
    
    /// Send a Message to the iPhone to get the list of POIs around the current user location
    /// This method must be called only if the session is activated
    ///
    /// - Parameter session: active session used to send message to the iPhone
    func getPOIsAround(session: WCSession) {
        
        
        NSLog("\(#function) isMainThread: \(Thread.isMainThread)")
       // Check again the session is activated and the session is reachable
        guard session.activationState == .activated else {
            NSLog("\(#function) Warning: Session is not activated")
            return
        }
        
        guard session.isReachable else {
            NSLog("\(#function) Warning: cannot send a Message when the session is no more reachable")
            DispatchQueue.main.async {
                self.refreshTableWith(error: CommonProps.MessageStatusCode.errorWatchAppSendingMsgToiPhone)
            }
            return
        }
        
        // Check if a message is already ongoing
        // If not then we update the internal state and we continue to send the message
        internalQueue.sync {
            if internalState {
                NSLog("A message is already in progress, do nothing")
            } else {
                internalState = true
                requestPOIsFromiPhone(session: session)
            }
        }
    }
    
    struct DebugInfos {
        static var sendMsgError = 0
        static var nothingToRefresh = 0
    }
    
    
    /// Send a Message to the iPhone to request POIs around the current location
    ///
    /// - Parameter session: reachable session with the iPhone
    private func requestPOIsFromiPhone(session:WCSession) {
        NSLog("\(#function) isMainThread: \(Thread.isMainThread)")
        // Must cast all value to Any else it raises an error because CLLLocationDegree and Int would create
        // an hetereogenous dictionary
        let messageContent = [
            CommonProps.maxRadius : Cste.radiusInKm as Any,
            CommonProps.maxResults : Cste.maxRequestedResults as Any
        ]
        
        session.sendMessage(messageContent,
                            replyHandler: { result in
                                self.msgInProgress = false
                                if let status = result[CommonProps.messageStatus] as? Int, let resultStatus = CommonProps.MessageStatusCode(rawValue:status) {
                                    switch resultStatus {
                                    case .ok:
                                        var newestWatchPOIs = [WatchPointOfInterest]()
                                        if let pois = result[CommonProps.listOfPOIs] as? [[String:String]] {
                                            // Extract all new WatchPointOfInterests from the result
                                            newestWatchPOIs = pois.map() { WatchPointOfInterest(properties:$0) }
                                        }
                                        DispatchQueue.main.async {
                                            self.refreshTableWith(newWatchPOIs: newestWatchPOIs)
                                        }
                                    default:
                                        self.refreshTableWith(error: resultStatus)
                                    }
                                } else {
                                    NSLog("\(#function) unknown error, message status is missing in the reply")
                                    DispatchQueue.main.async {
                                        self.refreshTableWith(error: CommonProps.MessageStatusCode.errorUnknown)
                                    }
                                }
        }) { error in
            self.msgInProgress = false
            NSLog("\(#function) an error has occured: \(error.localizedDescription)")
            DebugInfos.sendMsgError += 1
            DispatchQueue.main.async {
                self.refreshTableWith(error: CommonProps.MessageStatusCode.errorWatchAppSendingMsgToiPhone)
            }
        }
    }
    
    private func refreshTableWith(error:CommonProps.MessageStatusCode) {
        
        // when an error has occured, we must reset the content of the displayed POIs
        displayedWatchPOIs.removeAll()
        
        var message:String
        
        switch error {
        case .ok:
            NSLog("\(#function) Warning, this method should not be called when no error")
            return
        case .erroriPhoneLocationNotAuthorized:
            NSLog("\(#function) iPhone not authorized to get user location")
            message = "Please enable location on iPhone App"
        case .erroriPhoneLocationNotAvailable:
            NSLog("\(#function) user location not available on the iPhone")
            message = "Check user location is enabled on iPhone"
        case .erroriPhoneCannotExtractCoordinatesFromMessage:
            NSLog("\(#function) iPhone cannot extract coordinates from Message")
            message = "internal error"
        case .errorWatchAppSendingMsgToiPhone:
            NSLog("\(#function) error when sending message from Watch -> iPhone")
            message = "Watch cannot send msg to iPhone"
        case .errorUnknown:
            NSLog("\(#function) unknown error")
            message = "Unknown error"
        }

        
        // When there's no POI around the user, we just display a table with a message displaying there's no POI
        self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
        
        if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
            controller.titleLabel.setText("(\(String(DebugInfos.sendMsgError)))(\(String(DebugInfos.nothingToRefresh))) \(message)")
        }
    }
    
    /// Refresh the table with a new set of POIs
    ///
    /// - Parameter newWatchPOIs: List of POIs to be displayed in the table
    private func refreshTableWith(newWatchPOIs:[WatchPointOfInterest]) {
        
        NSLog("\(#function)")
        
        if newWatchPOIs.count == 0 {
            NSLog("\(#function) update with an empty list")

            // When there's no POI around the user, we just display a table with a message displaying there's no POI
            self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
            
            if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
                controller.titleLabel.setText("(\(String(DebugInfos.sendMsgError)))(\(String(DebugInfos.nothingToRefresh)))No data available")
            }
        } else {
            // A list of POIs were already displayed and we need to display a new one
            // We want to change only what is needed
            
            if displayedWatchPOIs.count == 0 && anyPOITable.numberOfRows == 1 {
                // specific case when the previous content was empty (no POI) because we still have a row to show we have no POI around user location
                // => Replace table content with the new data
                anyPOITable.setNumberOfRows(newWatchPOIs.count, withRowType: Storyboard.poiRowId)
            } else {
                // Make the delta between two lists of POIs
                // Add or Remove rows when the new list of rows is greater or lower than the previous list
                if newWatchPOIs.count > displayedWatchPOIs.count {
                    var indexes = IndexSet()
                    for i in displayedWatchPOIs.count..<newWatchPOIs.count {
                        indexes.insert(i)
                    }
                    
                    anyPOITable.insertRows(at: indexes, withRowType: Storyboard.poiRowId)
                } else if newWatchPOIs.count < displayedWatchPOIs.count {
                    // Remove useless rows
                    var indexes = IndexSet()
                    for i in newWatchPOIs.count..<displayedWatchPOIs.count {
                        indexes.insert(i)
                    }
                    
                    anyPOITable.removeRows(at: indexes)
                }
            }
            
            
            // There is at least one POI to display, let's update the screen
            var hasUpdate = false
            for i in 0..<newWatchPOIs.count {
                if i < displayedWatchPOIs.count {
                    // Update the row only if it contains something different
                    if newWatchPOIs[i] != displayedWatchPOIs[i], let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: newWatchPOIs[i])
                        hasUpdate = true
                    }
                } else {
                    // It's a new row that need to be configured
                    if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: newWatchPOIs[i])
                        hasUpdate = true
                    }
                }
            }
            
            if !hasUpdate {
                NSLog("\(#function) no update")
                DebugInfos.nothingToRefresh += 1
            } else {
                NSLog("\(#function) has update")
            }
        }
        
        displayedWatchPOIs = newWatchPOIs

        // If needed, update the complication
        if displayedWatchPOIs.count > 0 && displayedWatchPOIs[0] != nearestPOI {
            nearestPOI = displayedWatchPOIs[0]
            refreshComplications()
        } else {
            if displayedWatchPOIs.count == 0 && nearestPOI != nil {
                nearestPOI = nil
                refreshComplications()
            }
        }
    }
    
    private func refreshComplications() {
        NSLog("\(#function)")
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
        row.titleLabel.setText("(\(String(DebugInfos.sendMsgError)))(\(String(DebugInfos.nothingToRefresh)))\(watchPOI.title!)\n\(watchPOI.distance!)")
        row.theCategory.setImage(watchPOI.category?.glyph)
        row.theCategory.setTintColor(UIColor.white)
        row.theGroupOfCategoryImage.setBackgroundColor(watchPOI.color)
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return displayedWatchPOIs[rowIndex]
    }
    
}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function)")
        if let theError = error {
            NSLog("\(#function) an error has occured: \(theError.localizedDescription)")
        } else {
            switch activationState {
            case .activated:
                NSLog("\(#function) session is activated")
                getPOIsAround(session:session)
            case .inactive:
                NSLog("\(#function) Warning, session is inactive")
            case .notActivated:
                NSLog("\(#function) Warning, session is not activated")
            }
            
        }
    }
    
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        NSLog("\(#function) received user info")
        
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
            let newNearestPOI = WatchPointOfInterest(properties:pois)
            if newNearestPOI != nearestPOI {
                NSLog("\(#function) nearest POI is \(nearestPOI?.title! ?? "no POI")")
                DispatchQueue.main.async {
                    self.refreshComplications()
                }
            } else {
                NSLog("\(#function) nearest POI has not changed")
            }
        } else {
            NSLog("\(#function) probably no POI around, still need to refresh the complication")
            if nearestPOI != nil {
                nearestPOI = nil
                DispatchQueue.main.async {
                    self.refreshComplications()
                }
            } else {
                NSLog("\(#function) nearest POI was already nil")
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("\(#function) has changed to \(session.isReachable ? "reachable" : "unreachable")")
        if session.isReachable {
            getPOIsAround(session:session)
        }
    }
    
    
}
        
        


