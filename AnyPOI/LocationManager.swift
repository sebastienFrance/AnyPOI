//
//  LocationManagerDelegate.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 07/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreLocation
import WatchConnectivity

/// This class manage the user location
/// By default we just request the location when the user is using the App, not in Background. This location
/// is used to display the user location on the Map.
///
/// When the user activate the Region Monitoring on a POI then we ask for the Background location update with
/// AlwaysAuthorization
///
/// When the Region Monitoring is enabled, the App trigger notifications to warn the user when he enters/exits a POI region
///
/// Notifications:
/// - AuthorizationHasChanged is sent each time the location authorization has been changed. Currently it's not used by the App
class LocationManager : NSObject {
    
    struct LocationNotifications {
        static let AuthorizationHasChanged = "AuthorizationHasChanged"
    }
    
    enum MonitoringStatus {
        case noError, deviceNotSupported, maxMonitoredRegionAlreadyReached, internalError
    }
    
    struct constants {
        static let maxMonitoredPois = 20
        static let maxRadius = Double(400.0)
    }
    
    fileprivate(set) var locationManager:CLLocationManager?

    struct DebugLocationUpdateInfos {
        let locationInfos:CLLocation
        let dateInfos:Date = Date()
        let reason:String
        let nearestPOI:String
        let distanceNearestPOI:CLLocationDistance
        let isWatchAppReachable = WatchSessionManager.sharedInstance.isWatchAppReachable
        let isWatchAppReachableBefore:Bool
        
        struct WatchSessionMsg {
            let sendMsgSuccess = WatchSessionManager.Debug.sendMsgSuccess
            let sendMsgErrorResult = WatchSessionManager.Debug.sendMsgErrorResult
            let sendMsgError = WatchSessionManager.Debug.sendMsgError
            let sendMsgLatestError = WatchSessionManager.Debug.sendMsgLatestError
            
            let sendApplicationContextSuccess = WatchSessionManager.Debug.sendApplicationContextSuccess
            let sendApplicationContextError = WatchSessionManager.Debug.sendApplicationContextError
            
            let remainingComplication = WatchSessionManager.sharedInstance.session.remainingComplicationUserInfoTransfers
            
            let debugReceiveSendMsgSuccess = WatchSessionManager.Debug.receiveSendMsgSuccess
            let debugReceiveSendMsgError = WatchSessionManager.Debug.receiveSendMsgError
            
            let enterRegionTriggered = AppDelegate.DebugInfo.Notification.enterRegionTriggered
            let enterRegionSuccess = AppDelegate.DebugInfo.Notification.enterRegionSuccess
            let enterRegionFailure = AppDelegate.DebugInfo.Notification.enterRegionFailure
            
            let exitRegionTriggered = AppDelegate.DebugInfo.Notification.exitRegionTriggered
            let exitRegionSuccess = AppDelegate.DebugInfo.Notification.exitRegionSuccess
            let exitRegionFailure = AppDelegate.DebugInfo.Notification.exitRegionFailure

        }
        
        let watchSessionMsg = WatchSessionMsg()
        
        
        struct WatchComplication {
            let sendEmptyComplicationUpdate = WatchComplicationUpdate.Debug.sendEmptyComplicationUpdate
            let sendUrgentComplicationUpdate = WatchComplicationUpdate.Debug.sendUrgentComplicationUpdate
            let notUrgentComplicationUpdate = WatchComplicationUpdate.Debug.notUrgentComplicationUpdate
            let cancelTransferComplicationUpdate = WatchComplicationUpdate.Debug.cancelTransferComplicationUpdate
        }
        
        let watchComplicationUpdate = WatchComplication()
        
        var debugTrace:String {
            let dateLocation = DateFormatter.localizedString(from: locationInfos.timestamp, dateStyle: .medium, timeStyle: .medium)
            let dateEvent = DateFormatter.localizedString(from: dateInfos, dateStyle: .medium, timeStyle: .medium)
            
            return """
            WatchReach B4/after: \(isWatchAppReachableBefore)/\(isWatchAppReachable)
            SendMsg ok/errRes/err: \(watchSessionMsg.sendMsgSuccess)/\(watchSessionMsg.sendMsgErrorResult)/\(watchSessionMsg.sendMsgError)
            SendMsg Latest error: \(watchSessionMsg.sendMsgLatestError)
            SendAppCtxt ok/err: \(watchSessionMsg.sendApplicationContextSuccess)/\(watchSessionMsg.sendApplicationContextError)
            RemainCompUpd: \(watchSessionMsg.remainingComplication)
            CompUpdate Urg/NotUrg/Empty: \(watchComplicationUpdate.sendUrgentComplicationUpdate)/\(watchComplicationUpdate.notUrgentComplicationUpdate)/\(watchComplicationUpdate.sendEmptyComplicationUpdate)
            CompUpdate cancelled: \(watchComplicationUpdate.cancelTransferComplicationUpdate)
            ReceivedMsg ok/err: \(watchSessionMsg.debugReceiveSendMsgSuccess)/\(watchSessionMsg.debugReceiveSendMsgError)
            EventType: \(reason)
            POI: \(nearestPOI)
            POI Distance: \(distanceNearestPOI)
            EventDate: \(dateEvent)
            LocDate: \(dateLocation)
            Latitude: \(locationInfos.coordinate.latitude)
            Longitude: \(locationInfos.coordinate.longitude)
            EnterRegionNofif Count/Succ/Fail:\(watchSessionMsg.enterRegionTriggered)/\(watchSessionMsg.enterRegionSuccess)/\(watchSessionMsg.enterRegionFailure)
            ExitRegionNofif Count/Succ/Fail:\(watchSessionMsg.exitRegionTriggered)/\(watchSessionMsg.exitRegionSuccess)/\(watchSessionMsg.exitRegionFailure)
            """
        }
    }
    
    var debugLocationUpdates = [DebugLocationUpdateInfos]()
    
    // Initialize the Singleton
    class var sharedInstance: LocationManager {
        struct Singleton {
            static let instance = LocationManager()
        }
        return Singleton.instance
    }

    // Called at the App startup to ask for the user Location when the "App is in used" only
    func startLocationManager() {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        switch (authorizationStatus) {
        case .denied, .restricted:
            NSLog("\(#function): No authorization granted for CLLocationManager")
        case .notDetermined:
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.showsBackgroundLocationIndicator = true
            locationManager?.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.showsBackgroundLocationIndicator = true
            NSLog("\(#function): Authorization is: \(LocationManager.getDebugStatus(status: authorizationStatus))")
        }
    }

    
    /// Check if the max POI that can be monitored has been reached
    ///
    /// - returns: true when the max has been reached otherwise it returns false
    func isMaxMonitoredRegionReached() -> Bool {
        return locationManager!.monitoredRegions.count == constants.maxMonitoredPois ? true : false
    }
    
    /// Start the monitoring of a POI
    ///  1) We check if the max # of Monitored region has been already reached
    ///  2) We request the "Always Authorization" that is mandatory to use region monitoring
    ///  3) We start the monitoring the of POI and it's recorded in the list of monitored POIs
    ///
    /// - parameter poi: POI to be monitored
    ///
    /// - returns: noError if the POI can be monitored otherwise an error is returned
    func startMonitoringRegion(poi:PointOfInterest) -> MonitoringStatus {
        requestAlwaysAuthorization()

        if isMaxMonitoredRegionReached() {
            NSLog("\(#function): Error, max number of monitored POI is already reached. Cannot start monitoring for \(poi.poiDisplayName!)")
            return .maxMonitoredRegionAlreadyReached
        }
        
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.startMonitoring(for: CLCircularRegion(center: poi.coordinate,
                                                                   radius: poi.poiRegionRadius,
                                                                   identifier: poi.poiRegionId!))
            return .noError
         } else {
            NSLog("\(#function): Error, device not supporting region monitoring")
            return .deviceNotSupported
        }
    }
    
    
    

    /// Stop the monitoring of a POI
    ///
    /// - parameter poi: POI for which the monitoring must be stopped
    ///
    /// - returns: noError when the monitoring has been stopped otherwise it returns an error
    func stopMonitoringRegion(poi:PointOfInterest) -> MonitoringStatus {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.stopMonitoring(for: CLCircularRegion(center: poi.coordinate, radius: poi.poiRegionRadius, identifier: poi.poiRegionId!))
            return .noError
        } else {
            return .deviceNotSupported
        }
    }
    
    func stopMonitoringRegions() {
        NSLog("\(#function)")
        if let regions = locationManager?.monitoredRegions {
            NSLog("\(#function) number of monitored regions: \(regions.count)")
            for region in regions {
                locationManager?.stopMonitoring(for: region)
            }
            NSLog("\(#function) number of monitored regions after the stop: \(locationManager?.monitoredRegions.count ?? -1)")
        }
    }
    
    func startMonitoringRegions() {
        NSLog("\(#function) will start monitoring of \(POIDataManager.sharedInstance.getAllMonitoredPOI().count)")
        for poi in POIDataManager.sharedInstance.getAllMonitoredPOI() {
            _ = startMonitoringRegion(poi: poi)
        }
    }

    /// Update monitoring of a POI (called when the radius has been changed...)
    ///
    /// - parameter poi: POI for which the monitoring must be updated
    ///
    /// - returns: noError when the update has been done successfully otherwise it returns an error
    func updateMonitoringRegion(_ poi:PointOfInterest) -> MonitoringStatus {
        let status = stopMonitoringRegion(poi: poi)
        return status == .noError ? startMonitoringRegion(poi:poi) : status
    }
 
    /// Ask the user to enable the "Always Authorization"
    func requestAlwaysAuthorization() {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        if  authorizationStatus == .denied {
            // Open an Alert to request the user to enable the location services
            let title = authorizationStatus == .denied ? NSLocalizedString("LocationServicesOffLocationManager", comment: "") : NSLocalizedString("BackgroundLocationDisabledLocationManager", comment: "")

            // Create the AlertController to display the request
            let alertController = DBAlertController(title: title, message: NSLocalizedString("BackgroundMessageLocationManager", comment: ""), preferredStyle: .alert)
            
            let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil)
            let settingsButton = UIAlertAction(title: NSLocalizedString("SettingsLocationManager", comment: ""), style: UIAlertActionStyle.default) { action in
                let settingURL = URL(string: UIApplicationOpenSettingsURLString)
                UIApplication.shared.open(settingURL!, options:[ : ], completionHandler: nil)
            }
            
            alertController.addAction(cancelButton)
            alertController.addAction(settingsButton)
            alertController.show()
        } else if authorizationStatus == .notDetermined || authorizationStatus == .authorizedWhenInUse  {
            locationManager?.requestAlwaysAuthorization()
        }
    }
    
    func startLocationUpdateForWatchApp() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            startSignificantLocationChanges()
        }
    }
    
    func stopLocationUpdateForWatchApp() {
        stopSignificantLocationChanges()
    }
    
    private func startSignificantLocationChanges() {
        NSLog("\(#function) called")
        if WatchSessionManager.sharedInstance.isWatchAppReady {
            NSLog("\(#function) WatchApp is installed then we can enable significantLocationChange")
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                locationManager?.startMonitoringSignificantLocationChanges()
                locationManager?.pausesLocationUpdatesAutomatically = true
                locationManager?.activityType = .other
                NSLog("\(#function) enabled")
            }
        }
    }

    private func stopSignificantLocationChanges() {
        NSLog("\(#function) called")
        locationManager?.stopMonitoringSignificantLocationChanges()
    }
    
    
    /// Used to check if the App has the authorization of localization
    ///
    /// - returns: Return true when at the App has WhenInUser or Always authorization, otherwise it returns false
    func isLocationAuthorized() -> Bool {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            return true
        } else {
            return false
        }
    }
    
    func isRegionMonitoringAuthorized() -> Bool {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        return authorizationStatus == .authorizedAlways ? true : false
    }
    
    var isAlwaysLocationAuthorized: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways ? true : false
    }

    
  
    /// Translate the status code to a human readable string for debugging only
    ///
    /// - parameter status: status code to analyze
    ///
    /// - returns: String description of the status
    fileprivate static func getDebugStatus(status: CLAuthorizationStatus) -> String {
        var authorizationStatus = "Always"
        switch status {
        case .authorizedAlways:
            authorizationStatus = "Always"
        case .authorizedWhenInUse:
            authorizationStatus = "When in use"
        case .denied:
            authorizationStatus = "Denied"
        case .notDetermined:
            authorizationStatus = "Not determined"
        case .restricted:
            authorizationStatus = "Restricted"
        }
        return authorizationStatus
    }
    
    fileprivate func dumpMonitoredRegions() {
        for region in locationManager!.monitoredRegions {
            NSLog("RegionId from CLLocationManager: \(region.identifier)")
        }
        
        for currentPOI in POIDataManager.sharedInstance.getAllMonitoredPOI() {
            NSLog("Monitored Poi: \(currentPOI.poiDisplayName!) with RegionId \(currentPOI.poiRegionId!) ")
        }
    }

}

extension LocationManager: CLLocationManagerDelegate {
  
    private func addDebugLocationUpdate(sourceUpdate:String, watchAppReachableBefore:Bool) {
        #if DEBUG
        if let location = locationManager?.location {
            
            var poiName = "no POI"
            var distanceFromPOI:CLLocationDistance = -1
            if let poi = WatchSessionManager.sharedInstance.complicationNearestPOI {
                poiName = poi.title!
                let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
                distanceFromPOI = location.distance(from: poiLocation)
            }
            
            let debugInfos = DebugLocationUpdateInfos(locationInfos: location,
                                                      reason: sourceUpdate,
                                                      nearestPOI: poiName,
                                                      distanceNearestPOI: distanceFromPOI,
                                                      isWatchAppReachableBefore: watchAppReachableBefore)
            debugLocationUpdates.append(debugInfos)
        }
        #endif
    }

    // Called when a SignificantLocationChanges has occured
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("\(#function) with latest location \(locations.last?.coordinate.latitude ?? -1) / \(locations.last?.coordinate.longitude ?? -1)")

        let debugWatchAppReachableBefore = WatchSessionManager.sharedInstance.isWatchAppReachable
        WatchSessionManager.sharedInstance.refreshWatchApp()
        
        addDebugLocationUpdate(sourceUpdate: "Update Locations", watchAppReachableBefore: debugWatchAppReachableBefore)
    }
    
    
    // IMPORTANT: didEnterRegion and didExitRegion require .AuthorizedAlways. If it's not .AuthorizedAlways
    // it will not detect enter & exit region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(region.identifier) {
            if poi.poiRegionNotifyEnter {
                AppDelegate.notifyRegionUpdate(poi: poi, isEntering:true)
            }
            let debugWatchAppReachableBefore = WatchSessionManager.sharedInstance.isWatchAppReachable
            WatchSessionManager.sharedInstance.refreshWatchApp()
            addDebugLocationUpdate(sourceUpdate: "Enter Region", watchAppReachableBefore: debugWatchAppReachableBefore)
        } else {
            NSLog("\(#function): Error, POI not found! This CLRegion \(region.identifier) will be removed!")
            dumpMonitoredRegions()
            
            locationManager?.stopMonitoring(for: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(region.identifier) {
            if poi.poiRegionNotifyExit {
                AppDelegate.notifyRegionUpdate(poi: poi, isEntering:false)
            }
            let debugWatchAppReachableBefore = WatchSessionManager.sharedInstance.isWatchAppReachable
            WatchSessionManager.sharedInstance.refreshWatchApp()
            addDebugLocationUpdate(sourceUpdate: "Exit Region", watchAppReachableBefore: debugWatchAppReachableBefore)
        } else {
            NSLog("\(#function): Error, POI not found! This CLRegion \(region.identifier) will be removed!")
            dumpMonitoredRegions()
            
            locationManager?.stopMonitoring(for: region)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        NSLog("\(#function) has failed to start monitoring for \(region.debugDescription) with error \(error.localizedDescription)")
        dumpMonitoredRegions()
        
        // If we have a POI related to this region we force it to stop the monitoring
        if let failedRegion = region {
            if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(failedRegion.identifier) {
                poi.poiRegionNotifyExit = false
                poi.poiRegionNotifyEnter = false
                POIDataManager.sharedInstance.updatePOI(poi)
                POIDataManager.sharedInstance.commitDatabase()
            }
            
            NSLog("\(#function): Error, POI not found! This CLRegion \(failedRegion.identifier) will be removed!")
            dumpMonitoredRegions()
            locationManager?.stopMonitoring(for: failedRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
    }
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("\(#function)")
    }
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        NSLog("\(#function)")
    }
    
    // Post an internal notification when the Authorization status has been changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("\(#function): Warning the authorization status of Location Manager has changed to \(LocationManager.getDebugStatus(status: status))")
        if status == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
            startMonitoringRegions()
            startSignificantLocationChanges()
        } else {
            stopMonitoringRegions()
            stopSignificantLocationChanges()
        }
        NSLog("\(#function) background location update: \(locationManager?.allowsBackgroundLocationUpdates ?? false)")

        
        NotificationCenter.default.post(name: Notification.Name(rawValue: LocationNotifications.AuthorizationHasChanged), object: manager)
    }

}
