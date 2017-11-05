//
//  Debug.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 04/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit


class Debug {
    
    static func debugSessionActivationState(session:WCSession) -> String {
        switch session.activationState {
        case .activated: return "activated"
        case .inactive: return "inactive"
        case .notActivated: return "notActivated"
        }
    }
    
    static func debugAppActivationState() -> String {
        switch WKExtension.shared().applicationState {
        case .active: return "active"
        case .background: return "background"
        case .inactive: return "inactive"
        }
    }
    
    static func watchExtension() -> String {
        var appStatus = "WatchExtension\nState: \(Debug.debugAppActivationState()) RunInDock: \(WKExtension.shared().isApplicationRunningInDock)\n"
        appStatus += "FrontTimeoutExt: \(WKExtension.shared().isFrontmostTimeoutExtended)"
        
        return appStatus
    }
    
    
    static func watchSession(session:WCSession) -> String {
        var sessionInfo = "WatchSession\nActivated: \(Debug.debugSessionActivationState(session:session)) Reachable: \(session.isReachable)\n"
        sessionInfo += "PendingContent: \(session.hasContentPending) NeedUnlock: \(session.iOSDeviceNeedsUnlockAfterRebootForReachability)"
        return sessionInfo
    }

    static func showAll(session:WCSession? = nil) -> String {
        var debugTrace = "\nisMainThread: \(Thread.isMainThread)\n\n"
        if let theSession = session {
            debugTrace += Debug.watchSession(session:theSession)
            debugTrace += "\n\n"
        }
        debugTrace += Debug.watchExtension()
        return debugTrace
    }

}
