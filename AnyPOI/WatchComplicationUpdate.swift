//
//  WatchComplicationUpdate.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 05/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation
import WatchConnectivity

class WatchComplicationUpdate {
    
    /// Cache
    private(set) var nearestPOI:PointOfInterest? = nil
    private var nearestDistance:CLLocationDistance = -1
    
    private var debugNotUrgentMsgCounter = 0
    
    private var latestTransferContext:WCSessionUserInfoTransfer? = nil
    
    private enum NeedUpdate { case urgent, notUrgent, none }
    
    func resetWith(poi:PointOfInterest?, currentLocation:CLLocation) {
        nearestPOI = poi
        
        if let thePoi = poi {
            nearestDistance = thePoi.distanceFrom(location: currentLocation)
        } else {
            nearestDistance = -1
        }
    }
    
    /// Request an update of the complication with a new location
    func updateComplicationWith(poi:PointOfInterest? = nil) {
        
        if WatchSessionManager.sharedInstance.isComplicationReady {
            if let thePoi = poi, let location = LocationManager.sharedInstance.locationManager?.location {
                sendComplicationUpdate(poi: thePoi, currentLocation: location)
            } else {
                sendEmptyComplicationUpdate()
            }
        } else {
            NSLog("\(#function) No update because the complication is not ready")
        }
    }
    
    struct Debug {
        static var sendEmptyComplicationUpdate = 0
        static var sendUrgentComplicationUpdate = 0
        static var notUrgentComplicationUpdate = 0
        static var cancelTransferComplicationUpdate = 0
    }
    
    /// Send to the Apple Watch an urgent complication update when there's no more a POI around user location
    private func sendEmptyComplicationUpdate() {
        NSLog("\(#function)")
        if nearestPOI != nil {
            NSLog("\(#function) There was a POI before but not now -> update the complication with no POI!")
            
            if let transferContext = latestTransferContext, transferContext.isTransferring {
                transferContext.cancel()
                WatchComplicationUpdate.Debug.cancelTransferComplicationUpdate += 1
            }
            
            latestTransferContext = WatchSessionManager.sharedInstance.session.transferCurrentComplicationUserInfo([String:Any]())
            
            // update cache
            nearestPOI = nil
            nearestDistance = -1
            
            WatchComplicationUpdate.Debug.sendEmptyComplicationUpdate += 1
        } else {
            NSLog("\(#function) No change, there was no POI before and there's still no POI around current location -> No update")
        }
    }
    
    
    /// Send a complication update to the Apple Watch. It can be an urgent update (when it's a new POI) or
    /// a not urgent update when only the distance has changed
    ///
    /// - Parameters:
    ///   - poi: the nearest POI
    ///   - currentLocation: user current location, use to compute the distance between the POI and the user location
    private func sendComplicationUpdate(poi:PointOfInterest, currentLocation: CLLocation) {
        NSLog("\(#function)")
        switch isComplicationUpdateNeeded(poi: poi, distanceFromUser: poi.distanceFrom(location:currentLocation)) {
        case .urgent:
            let distance = poi.distanceFrom(location:currentLocation)

            let result = createComplicationUserInfos(poi: poi, distanceFromUser: distance)
            
            if let transferContext = latestTransferContext, transferContext.isTransferring {
                transferContext.cancel()
                WatchComplicationUpdate.Debug.cancelTransferComplicationUpdate += 1
            }
           latestTransferContext = WatchSessionManager.sharedInstance.session.transferCurrentComplicationUserInfo(result)
            
            nearestPOI = poi
            nearestDistance = distance
            WatchComplicationUpdate.Debug.sendUrgentComplicationUpdate += 1
        case .notUrgent:
            debugNotUrgentMsgCounter += 1
            WatchComplicationUpdate.Debug.notUrgentComplicationUpdate += 1
        case .none:
            break
        }
    }
    
    /// Compute if the complication update is urgent, not urgent or none
    ///
    /// - Parameters:
    ///   - poi: nearest POI
    ///   - distanceFromUser: distance between the user and the POI
    /// - Returns: urgent if the complication must be updated quickly, not urgent when the complication update is not mandatory and none when there's no update
    private func isComplicationUpdateNeeded(poi:PointOfInterest, distanceFromUser:CLLocationDistance) -> NeedUpdate {
        if poi != nearestPOI {
            return .urgent
        } else {
            let distanceDiff = abs(nearestDistance - distanceFromUser)
            if distanceDiff >= CommonProps.Cste.diffDistanceForUrgentUpdate {
                return .urgent
            } else if distanceFromUser != 0 {
                return .notUrgent
            } else {
                return .none
            }
        }
    }
    
    /// Create a User Infos that can be used to update the complication
    ///
    /// - Parameters:
    ///   - poi: nearest POI
    ///   - distanceFromUser:  distance between the user and the POI
    /// - Returns: user infos to be send to update the complication
    private func createComplicationUserInfos(poi:PointOfInterest, distanceFromUser:CLLocationDistance) -> [String:Any] {
        var poiProps =  poi.props
        
        poiProps[CommonProps.POI.distance] = String(distanceFromUser)
        
        if CommonProps.isDebugEnabled {
            poiProps[CommonProps.debugRemainingComplicationTransferInfo] = String(WatchSessionManager.sharedInstance.session.remainingComplicationUserInfoTransfers)
            poiProps[CommonProps.debugNotUrgentComplicationTransferInfo] = String(debugNotUrgentMsgCounter)
        }
        
        var result = [String:Any]()
        result[CommonProps.singlePOI] = poiProps
        return result
    }
}
