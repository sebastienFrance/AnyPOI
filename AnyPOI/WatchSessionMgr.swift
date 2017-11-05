//
//  WatchSessionMgr.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 21/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreLocation

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedInstance = WatchSessionManager()
    let session = WCSession.default
    
    private let complicationUpdateManager = WatchComplicationUpdate()
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            // When something is changed we need to update the WatchApp
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(WatchSessionManager.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                                   name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                   object: DatabaseAccess.sharedInstance.managedObjectContext)
        }
    }
    
    // Activate Session
    // This needs to be called to activate the session before first use!
    func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    
    /// Enable Significant Location Changes only when a Watch is paired when the WatchApp is installed
    ///
    /// - Returns: True when the significant location should be enabled otherwise it returns false
    var isWatchAppReady: Bool {
        if WCSession.isSupported() {
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
        } else {
            return false
        }
    }
    
    /// True when the WatchApp is reachable for Live Messaging
    var isWatchAppReachable: Bool {
        return isWatchAppReady && session.isReachable
    }
    
    /// Check if the complication is ready on the Apple Watch
    ///
    /// - Returns: true when the complication is installed and enabled on the Watch, otherwise it returns false
    var isComplicationReady: Bool {
        if WCSession.isSupported() {
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled && session.isComplicationEnabled
        } else {
            return false
        }
    }

    
    /// When something has been changed we update the WatchApp
    @objc func ManagedObjectContextObjectsDidChangeNotification(_ notification : Notification) {
        refreshWatchApp()
    }
    
    func refreshWatchApp() {
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")

        // TODO: Check if something has changed before to send the message for update
        let (propList, pois) = WatchUtilities.getPoisAround(maxRadius: CommonProps.Cste.radiusInKm, maxPOIResults: CommonProps.Cste.maxRequestedResults)

        if isWatchAppReachable {
            NSLog("\(#function) WatchApp is reachable -> Send Message")
            session.sendMessage(propList, replyHandler: { resultValue in
            }) { error in
                NSLog("\(#function) error with sendMessage, error: \(error.localizedDescription) ")
            }
        } else if isWatchAppReady {

            do {
                try session.updateApplicationContext(propList)
                NSLog("\(#function) updateApplicationContext has been sent")
            } catch let error {
                NSLog("\(#function) updateApplicationContext has failed \(error.localizedDescription)")
            }
            
            if pois.count > 0 {
                complicationUpdateManager.updateComplicationWith(poi: pois[0])
            } else {
                complicationUpdateManager.updateComplicationWith()
            }
        } else {
            NSLog("\(#function) WatchApp cannot be refreshed!")
        }
    }

    //MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")
        if let theError = error {
            NSLog("\(#function) an error has occured: \(theError.localizedDescription)")
        } else {
            if isWatchAppReady {
                refreshWatchApp()
                LocationManager.sharedInstance.startLocationUpdateForWatchApp()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Nothing to do here
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // When a new Watch has been paired we must activate the session again
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")
        session.activate()
    }
    
    // Update the LocationManager when the WatchApp is installed/uninstalled, when the AppleWatch is paired/not paired...
    func sessionWatchStateDidChange(_ session: WCSession) {
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")
        if isWatchAppReady {
            refreshWatchApp()
            LocationManager.sharedInstance.startLocationUpdateForWatchApp()
        } else {
            LocationManager.sharedInstance.stopLocationUpdateForWatchApp()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        NSLog("\(#function) sessionState: \(WatchDebug.debugWCSession(session: session))")
        
        if  let maxRadius = message[CommonProps.maxRadius] as? Double,
            let maxPOIResults = message[CommonProps.maxResults] as? Int {
            
            let (propList, _) = WatchUtilities.getPoisAround(maxRadius: maxRadius, maxPOIResults: maxPOIResults)
            replyHandler(propList)
        } else {
            replyHandler([CommonProps.messageStatus : CommonProps.MessageStatusCode.erroriPhoneCannotExtractCoordinatesFromMessage.rawValue])
        }
        
    }
}
