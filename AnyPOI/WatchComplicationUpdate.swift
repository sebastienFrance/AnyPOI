//
//  WatchComplicationUpdate.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 05/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation

class WatchComplicationUpdate {
    
    /// Cache
    private var nearestPOI:PointOfInterest? = nil
    private var nearestDistance:Int = -1
    
    private var debugNotUrgentMsgCounter = 0
    
    private enum NeedUpdate { case urgent, notUrgent, none }
    
    
    
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
    
    
    
    /// Send to the Apple Watch an urgent complication update when there's no more a POI around user location
    private func sendEmptyComplicationUpdate() {
        if nearestPOI != nil {
            NSLog("\(#function) There was a POI before but not now -> update the complication with no POI!")
            WatchSessionManager.sharedInstance.session.transferCurrentComplicationUserInfo([String:Any]())
            
            // update cache
            nearestPOI = nil
            nearestDistance = -1
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
        
        // Compute distance between POI and user
        let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
        let distance = currentLocation.distance(from: targetLocation)
        
        let updateType = isComplicationUpdateNeeded(poi: poi, distanceFromUser: distance)
        if updateType == .none {
            return
        }
        
        let result = createComplicationUserInfos(poi: poi, distanceFromUser: distance)
        switch updateType {
        case .urgent:
            // As we sent an urgent message, cancel all previous msg which are useless
            WatchSessionManager.sharedInstance.session.transferCurrentComplicationUserInfo(result)
        case .notUrgent:
            debugNotUrgentMsgCounter += 1
        default:
            break
        }
        
        // Update cache
        nearestPOI = poi
        nearestDistance = Int(distance)
    }
    
    
    /// Compute if the complication update is urgent, not urgent or none
    ///
    /// - Parameters:
    ///   - poi: nearest POI
    ///   - distanceFromUser: distance between the user and the POI
    /// - Returns: urgent if the complication must be updated quickly, not urgent when the complication update is not mandatory and none when there's no update
    private func isComplicationUpdateNeeded(poi:PointOfInterest, distanceFromUser:CLLocationDistance) -> NeedUpdate {
        if poi != nearestPOI {
            NSLog("\(#function) complication update because POI has changed")
            return .urgent
        } else {
            return nearestDistance != Int(distanceFromUser) ? .notUrgent : .none
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
