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
    
    var nearestPOI:PointOfInterest? = nil
    var nearestDistance:CLLocationDistance = -1

    
    // We want to enable Significant Location Changes only when a Watch is paired when our WatchApp is installed
    // otherwise we do not enable it
    // TBC: Maybe we should enable it only when the Complication is installed???
    func isWatchAppReadyForSignificantLocationUpdate() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
        } else {
            return false
        }
    }

    private func isWatchAppComplicationReady() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            return session.activationState == .activated && session.isPaired && session.isWatchAppInstalled && session.isComplicationEnabled
        } else {
            return false
        }
    }


    func updateWatchComplicationWith(newestLocation:CLLocation) {
        if isWatchAppComplicationReady() {
            let pois = PoiBoundingBox.getPoiAroundCurrentLocation(newestLocation, radius: 10, maxResult: 1)
            if pois.count >= 1 {
                if isWatchComplicationNeedUpdateWith(poi: pois[0], currentLocation: newestLocation) {
                    if let result = AnyPoiWatchManager.createComplicationUserInfos(poi: pois[0], currentLocation: newestLocation) {
                        WCSession.default.transferCurrentComplicationUserInfo(result)
                        
                        // Update cache
                        nearestPOI = pois[0]
                        
                        let targetLocation = CLLocation(latitude: pois[0].poiLatitude , longitude: pois[0].poiLongitude)
                        let distance = newestLocation.distance(from: targetLocation)
                        nearestDistance = distance
                    } else {
                        NSLog("\(#function) Error, cannot create a user infos")
                    }
                }
            } else {
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
        } else {
            NSLog("\(#function) No update because the complication is not ready")
        }
        
    }
    
    private func isWatchComplicationNeedUpdateWith(poi:PointOfInterest, currentLocation:CLLocation) -> Bool {
        if poi != nearestPOI {
            NSLog("\(#function) complication update because POI has changed")
            return true
        } else {
            let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
            let distance = currentLocation.distance(from: targetLocation)
            return nearestDistance != distance ? true : false
        }
    }
    
    private static func createComplicationUserInfos(poi:PointOfInterest, currentLocation: CLLocation) -> [String:Any]? {
        guard var poiProps =  poi.props else { return nil }
        
        // Append the distance
        let targetLocation = CLLocation(latitude: poi.poiLatitude , longitude: poi.poiLongitude)
        let distance = currentLocation.distance(from: targetLocation)
        poiProps[CommonProps.POI.distance] = String(distance)
        poiProps[CommonProps.debugRemainingComplicationTransferInfo] = String(WCSession.default.remainingComplicationUserInfoTransfers)
        
        var result = [String:Any]()
        result[CommonProps.singlePOI] = poiProps
        return result
    }
}
