//
//  WatchSessionManager.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 03/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedInstance = WatchSessionManager()
    private let session = WCSession.default
    
    private var internalMsgInProgress = false
    private let internalQueue = DispatchQueue(label:"protectSendMsg") // Serial or Concurrent?

    private var msgInProgress: Bool {
        get {
            return internalQueue.sync { internalMsgInProgress }
        }
        
        set (newState) {
            internalQueue.sync { internalMsgInProgress = newState }
        }
    }


    private let msgGetPOIsAround = [
        CommonProps.maxRadius : CommonProps.Cste.radiusInKm as Any,
        CommonProps.maxResults : CommonProps.Cste.maxRequestedResults as Any
    ]

    
    private override init() {
        super.init()
    }
    
    // Activate Session
    // This needs to be called to activate the session before first use!
    func startSession() {
        session.delegate = self
        session.activate()
    }
    
    /// Send a Message to the iPhone to get the list of POIs around the current user location
    /// This method must be called only if the session is activated
    ///
    /// - Parameter session: active session used to send message to the iPhone
    func getPOIsAround() {
        NSLog("\(#function) isMainThread: \(Thread.isMainThread)")
        NSLog("\(#function) Session state is: \(Debug.showAll(session: session))")
        
        guard WKExtension.shared().applicationState == .active || (WKExtension.shared().applicationState == .inactive && WKExtension.shared().isApplicationRunningInDock) else {
            NSLog("\(#function) Warning: cannot get POIs with live messaging when App is inactive or in background")
            return
        }
        
        
       // Check again the session is activated and the session is reachable
        guard session.activationState == .activated else {
            NSLog("\(#function) Warning: Session is not activated")
            return
        }
        
        
        // Check if a message is already ongoing
        // If not then we update the internal state and we continue to send the message
        internalQueue.sync {
            if internalMsgInProgress {
                NSLog("\(#function) A message is already in progress, do nothing")
            } else {
                internalMsgInProgress = true
                
                session.sendMessage(msgGetPOIsAround,
                                    replyHandler: { result in
                                        if let status = result[CommonProps.messageStatus] as? Int, let resultStatus =
                                            
                                            
                                            CommonProps.MessageStatusCode(rawValue:status) {
                                            switch resultStatus {
                                            case .ok:
                                                var newestWatchPOIs = [WatchPointOfInterest]()
                                                if let pois = result[CommonProps.listOfPOIs] as? [[String:String]] {
                                                    // Extract all new WatchPointOfInterests from the result
                                                    newestWatchPOIs = pois.map() { WatchPointOfInterest(properties:$0) }
                                                }
                                                WatchDataSource.sharedInstance.updateWith(newPOIs: newestWatchPOIs)
                                            default:
                                                WatchDataSource.sharedInstance.updateWith(error:resultStatus)
                                            }
                                        } else {
                                            NSLog("\(#function) unknown error, message status is missing in the reply")
                                            WatchDataSource.sharedInstance.updateWith(error:CommonProps.MessageStatusCode.errorUnknown)
                                        }
 
                                        self.msgInProgress = false
                }) { error in
                    self.msgInProgress = false
                    NSLog("\(#function) an error has occured: \(error.localizedDescription)")
                    if CommonProps.isDebugEnabled {
                        WatchDataSource.sharedInstance.updateWith(error:CommonProps.MessageStatusCode.errorWatchAppSendingMsgToiPhone, msg:error.localizedDescription)
                    }
                }
                
            }
        }
    }

    
    /// Process a message that should contain a list of POIs
    /// When the POIs are extracted the datasource is updated and the WatchApp UI is refreshed (if needed)
    ///
    /// - Parameter message: Message that contains a status and the list of POIs (in a property list)
    private func processIncomingPOIs(message: [String : Any]) {
        NSLog("\(#function)")
        
        if let status = message[CommonProps.messageStatus] as? Int, let resultStatus = CommonProps.MessageStatusCode(rawValue:status) {
            
            switch resultStatus {
            case .ok:
                var watchPOIs = [WatchPointOfInterest]()
                if let receivedPOIs = message[CommonProps.listOfPOIs] as? [[String:String]] {
                    // Extract all new WatchPointOfInterests from the result
                    watchPOIs = receivedPOIs.map() { WatchPointOfInterest(properties:$0) }
                }
                NSLog("\(#function) has received: \(watchPOIs.count)")
                WatchDataSource.sharedInstance.updateWith(newPOIs: watchPOIs)
            default:
                WatchDataSource.sharedInstance.updateWith(error:resultStatus)
            }
        } else {
            NSLog("\(#function) unknown error, message status is missing in the reply")
        }
    }

    //MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function) \(Debug.showAll(session: session))")
        if let theError = error {
            NSLog("\(#function) an error has occured: \(theError.localizedDescription)")
        } else if activationState == .activated {
            getPOIsAround()
        }
    }
    
    /// Update the WatchApp with a new list of POIs
    ///
    /// - Parameters:
    ///   - session: Watch Connectivity session
    ///   - applicationContext: Message that contains the list of POIs
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        NSLog("\(#function) \(Debug.showAll(session: session))")
        
        processIncomingPOIs(message: applicationContext)
    }
    
    /// Update the Watchpp with a list of POIs (in an Live Messaging)
    ///
    /// - Parameters:
    ///   - session: Watch Connectivity session
    ///   - message: List of POIs
    ///   - replyHandler: handler used to say OK to the IOS App when the message has been processed
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        NSLog("\(#function) \(Debug.showAll(session: session))")
        
        processIncomingPOIs(message: message)
        
        var result = [String:Any]()
        result[CommonProps.messageStatus] = CommonProps.MessageStatusCode.ok.rawValue
        replyHandler(result)
    }
    
    /// Called when the IOS App has called transferCurrentComplicationUserInfo or transferUserInfo
    /// to update the complication
    ///
    /// - Parameters:
    ///   - session: Watch session connectivity
    ///   - userInfo: contains the POI that should be displayed in the complication
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        NSLog("\(#function) \(Debug.showAll(session: session))")
        var newNearestPOI:WatchPointOfInterest? = nil
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
             newNearestPOI = WatchPointOfInterest(properties:pois)
        }
        WatchDataSource.sharedInstance.updateNearestPOIWith(poi: newNearestPOI)
    }
    
    /// When the Watch Connectivity session becomes reachable then we try to
    /// refresh the WatchApp with a new list of POIs
    ///
    /// - Parameter session: Watch session connectivity
    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("\(#function) \(Debug.showAll(session: session))")
        if session.isReachable {
           getPOIsAround()
        }
    }
}
