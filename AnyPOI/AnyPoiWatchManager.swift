//
//  AnyPoiWatchManager.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 22/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation
import WatchConnectivity

class AnyPoiWatchManager {
    
    static let sharedInstance = AnyPoiWatchManager()
    
    private var nearestPOI:PointOfInterest? = nil
    private var nearestDistance:Int = -1
    
    private var debugNotUrgentMsgCounter = 0

    private enum NeedUpdate { case urgent, notUrgent, none }
    
    // We want to enable Significant Location Changes only when a Watch is paired when our WatchApp is installed
    // otherwise we do not enable it
    // TBC: Maybe we should enable it only when the Complication is installed???
    func isReadyForSignificantLocationUpdate() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
        } else {
            return false
        }
    }

    private func isComplicationReady() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled && session.isComplicationEnabled
        } else {
            return false
        }
    }


    func updateComplicationWith(newestLocation:CLLocation) {
        if isComplicationReady() {
            let pois = PoiBoundingBox.getPoiAroundCurrentLocation(newestLocation, radius: 10, maxResult: 1)
            if pois.count >= 1 {
                sendComplicationUpdate(poi: pois[0], currentLocation: newestLocation)
            } else {
                sendEmptyComplicationUpdate()
            }
        } else {
            NSLog("\(#function) No update because the complication is not ready")
        }
        
    }
    
    private func sendEmptyComplicationUpdate() {
        if nearestPOI != nil {
            NSLog("\(#function) There was a POI before but not now -> update the complication with no POI!")
            WCSession.default.transferCurrentComplicationUserInfo([String:Any]())
            
            // update cache
            nearestPOI = nil
            nearestDistance = -1
        } else {
            NSLog("\(#function) No change, there was no POI before and there's still no POI around current location -> No update")
        }
    }
    
    private func sendComplicationUpdate(poi:PointOfInterest, currentLocation: CLLocation) {
        let updateType = isComplicationUpdateNeeded(poi: poi, currentLocation: currentLocation)
        if updateType == .none {
            return
        }
        
        if updateType == .notUrgent {
            debugNotUrgentMsgCounter += 1
        }
            
        if let result = createComplicationUserInfos(poi: poi, currentLocation: currentLocation) {
            switch updateType {
            case .urgent:
                WCSession.default.transferCurrentComplicationUserInfo(result)
            case .notUrgent:
                WCSession.default.transferUserInfo(result)
            default:
                break
            }
            // Update cache
            nearestPOI = poi
            
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distance(from: targetLocation)
            nearestDistance = Int(distance)
        } else {
            NSLog("\(#function) Error, cannot create a user infos")
        }
    }
    
    private func isComplicationUpdateNeeded(poi:PointOfInterest, currentLocation:CLLocation) -> NeedUpdate {
        if poi != nearestPOI {
            NSLog("\(#function) complication update because POI has changed")
            return .urgent
        } else {
            // When only the distance is changed, don't need to send the update urgently
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distance(from: targetLocation)
            return nearestDistance != Int(distance) ? .notUrgent : .none
        }
    }
    
    private func createComplicationUserInfos(poi:PointOfInterest, currentLocation: CLLocation) -> [String:Any]? {
        guard var poiProps =  poi.props else { return nil }
        
        // Append the distance
        let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
        let distance = currentLocation.distance(from: targetLocation)
        poiProps[CommonProps.POI.distance] = String(distance)
        poiProps[CommonProps.debugRemainingComplicationTransferInfo] = String(WCSession.default.remainingComplicationUserInfoTransfers)
        poiProps[CommonProps.debugNotUrgentComplicationTransferInfo] = String(debugNotUrgentMsgCounter)
        
        var result = [String:Any]()
        result[CommonProps.singlePOI] = poiProps
        return result
    }
}
