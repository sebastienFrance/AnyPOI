//
//  WatchDebug.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 04/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchDebug {
    
    static func debugSessionActivationState(session:WCSession) -> String {
        switch session.activationState {
        case .activated: return "activated"
        case .inactive: return "inactive"
        case .notActivated: return "notActivated"
        }
    }
    
    static func debugWCSession(session:WCSession) -> String {
        var sessionInfo = "Session\nActivated: \(WatchDebug.debugSessionActivationState(session:session)) Reachable: \(session.isReachable)\n"
        sessionInfo += "isPaired: \(session.isPaired) isWatchAppInstalled: \(session.isWatchAppInstalled) \n"
        sessionInfo += "PendingContent: \(session.hasContentPending) isComplicationEnabled: \(session.isComplicationEnabled)\n"
        return sessionInfo
    }
    

}
