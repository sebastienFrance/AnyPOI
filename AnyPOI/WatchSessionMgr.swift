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
    var session:WCSession {
        return WCSession.default
    }
    
    private let complicationUpdateManager = WatchComplicationUpdate()
    var complicationNearestPOI:PointOfInterest? {
        return complicationUpdateManager.nearestPOI
    }
    
    private override init() {
        super.init()
        
        // Subscribe or unsubscribe POI notification depending on the new App Watch state
        updatePoiNotificationsSubscription()
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
    
    /// Subscribe POI notification when the WatchApp is ready (paired/installed) otherwise
    /// it's just unsubscribing notifications
    private func updatePoiNotificationsSubscription() {
        NotificationCenter.default.removeObserver(self)
        if isWatchAppReady {
            // When something is changed we need to update the WatchApp
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(WatchSessionManager.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                                   name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                   object: DatabaseAccess.sharedInstance.managedObjectContext)
        }
    }

    
    /// When something has been changed we update the WatchApp
    @objc func ManagedObjectContextObjectsDidChangeNotification(_ notification : Notification) {
        
        // If a POI is created but the location Always is disabled we ask user to enable it
        if !LocationManager.sharedInstance.isAlwaysLocationAuthorized {
            let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
            if notifContent.insertedPois.count > 0 {
                LocationManager.sharedInstance.requestAlwaysAuthorization()
            }
        }
        refreshWatchApp()
    }
    
    struct Debug {
        static var sendMsgSuccess = 0
        static var sendMsgErrorResult = 0
        static var sendMsgError = 0
        static var sendMsgLatestError = ""
        static var sendApplicationContextSuccess = 0
        static var sendApplicationContextError = 0
        static var receiveSendMsgSuccess = 0
        static var receiveSendMsgError = 0
    }
        
    func refreshWatchApp() {
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
        guard isWatchAppReady else {
            NSLog("Watch App is not ready, so do nothing!")
            return }

        // TODO: Check if something has changed before to send the message for update
        let (propList, pois) = WatchUtilities.getPoisAround(maxRadius: CommonProps.Cste.radiusInKm, maxPOIResults: CommonProps.Cste.maxRequestedResults)

        if isWatchAppReachable {
            NSLog("\(#function) WatchApp is reachable -> Send Message")
            session.sendMessage(propList, replyHandler: { resultValue in
                
                if let status = resultValue[CommonProps.messageStatus] as? Int, let resultStatus = CommonProps.MessageStatusCode(rawValue:status) {
                    switch resultStatus {
                    case .ok:
                        NSLog("\(#function) Sucessful response from Apple Watch")
                        
                        // We can reset safely the cache for the complication
                        if let location = LocationManager.sharedInstance.locationManager?.location {
                            let nearestPOI = pois.count > 0 ? pois[0] : nil
                            self.complicationUpdateManager.resetWith(poi: nearestPOI, currentLocation: location)
                        }
                        WatchSessionManager.Debug.sendMsgSuccess += 1
                    default:
                        NSLog("\(#function) Apple watch has replied with an error")
                        WatchSessionManager.Debug.sendMsgErrorResult += 1
                        break
                    }
                } else {
                    NSLog("\(#function) get an unknown response from Apple Watch!")
                    WatchSessionManager.Debug.sendMsgErrorResult += 1
                }
                
            }) { error in
                NSLog("\(#function) error with sendMessage, error: \(error.localizedDescription) ")
                WatchSessionManager.Debug.sendMsgError += 1
                WatchSessionManager.Debug.sendMsgLatestError = error.localizedDescription
                
                // On error, just send an application update to try to resync the Watch with the new data
                self.sendApplicationUpdate(propList: propList, pois: pois)
            }
        } else {
            sendApplicationUpdate(propList: propList, pois: pois)
        }
    }
    
    /// Refresh the WatchApp using an updateApplicationContext and sends a complication
    /// update (if needed)
    func sendApplicationUpdate(propList: [String : Any], pois: [PointOfInterest]) {
        if isWatchAppReady {
            
            do {
                try session.updateApplicationContext(propList)
                NSLog("\(#function) updateApplicationContext has been sent")
                WatchSessionManager.Debug.sendApplicationContextSuccess += 1
            } catch let error {
                NSLog("\(#function) updateApplicationContext has failed \(error.localizedDescription)")
                WatchSessionManager.Debug.sendApplicationContextError += 1
            }
            
            complicationUpdateManager.updateComplicationWith(poi: pois.count > 0 ? pois[0] : nil)
        } else {
            NSLog("\(#function) WatchApp cannot be refreshed!")
        }
    }

    //MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
        
        // Subscribe or unsubscribe POI notification depending on the new App Watch state
        updatePoiNotificationsSubscription()
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
        // Called when the user prepare to switch to a new AppleWatch
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // When a new Watch has been paired we must activate the session again
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
        session.activate()
    }
    
    // Update the LocationManager when the WatchApp is installed/uninstalled, when the AppleWatch is paired/not paired...
    func sessionWatchStateDidChange(_ session: WCSession) {
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
        
        // Subscribe or unsubscribe POI notification depending on the new App Watch state
        updatePoiNotificationsSubscription()
        if isWatchAppReady {
            refreshWatchApp()
            LocationManager.sharedInstance.requestAlwaysAuthorization()
            LocationManager.sharedInstance.startLocationUpdateForWatchApp()
        } else {
            LocationManager.sharedInstance.stopLocationUpdateForWatchApp()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        NSLog("\(#function) \(WatchDebug.debugWCSession(session: session))")
        
        if  let maxRadius = message[CommonProps.maxRadius] as? Double,
            let maxPOIResults = message[CommonProps.maxResults] as? Int {
            
            let (propList, _) = WatchUtilities.getPoisAround(maxRadius: maxRadius, maxPOIResults: maxPOIResults)
            replyHandler(propList)
            WatchSessionManager.Debug.receiveSendMsgSuccess += 1
        } else {
            replyHandler([CommonProps.messageStatus : CommonProps.MessageStatusCode.erroriPhoneCannotExtractCoordinatesFromMessage.rawValue])
            WatchSessionManager.Debug.receiveSendMsgError += 1
        }
    }
}
