//
//  LocationManagerDelegate.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 07/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreLocation

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
            if let locationMgr = locationManager {
                locationMgr.delegate = self
                locationMgr.requestWhenInUseAuthorization()
                if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
                    NSLog("\(#function): Warning significantLocationChangeMonitoringAvailable is not available on this device")
                }
            } else {
                NSLog("\(#function): error CLLocationManager cannot be created!")
            }
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            NSLog("\(#function): Authorization is: \(LocationManager.getStatus(status: authorizationStatus))")
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
        if isMaxMonitoredRegionReached() {
            NSLog("\(#function): Error, max numnber of monitored POI is already reached")
            return .maxMonitoredRegionAlreadyReached
        }
        
        requestAlwaysAuthorization()
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.startMonitoring(for: CLCircularRegion(center: poi.coordinate,
                                                                   radius: poi.poiRegionRadius,
                                                                   identifier: poi.poiRegionId!))
            return .noError
         } else {
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
    fileprivate func requestAlwaysAuthorization() {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .denied {
            let title = authorizationStatus == .denied ? NSLocalizedString("LocationServicesOffLocationManager", comment: "") : NSLocalizedString("BackgroundLocationDisabledLocationManager", comment: "")

            // Create the AlertController to display the request
            let alertController = DBAlertController(title: title, message: NSLocalizedString("BackgroundMessageLocationManager", comment: ""), preferredStyle: .alert)
            
            let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil)
            let settingsButton = UIAlertAction(title: NSLocalizedString("SettingsLocationManager", comment: ""), style: UIAlertActionStyle.default) { action in
                let settingURL = URL(string: UIApplicationOpenSettingsURLString)
                UIApplication.shared.openURL(settingURL!)
            }
            
            alertController.addAction(cancelButton)
            alertController.addAction(settingsButton)
            alertController.show()
        } else if authorizationStatus == .notDetermined {
            locationManager?.requestAlwaysAuthorization()
        }
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
    
  
    /// Translate the status code to a human readable string
    ///
    /// - parameter status: status code to analyze
    ///
    /// - returns: String description of the status
    fileprivate static func getStatus(status: CLAuthorizationStatus) -> String {
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
    //MARK: CLLocationManagerDelegate
    
    // Called when a SignificantLocationChanges has occured
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("\(#function): Location Manager didFailWithError: \(error.localizedDescription)")
    }
    
    // IMPORTANT: didEnterRegion and didExitRegion require .AuthorizedAlways. If it's not .AuthorizedAlways
    // it will not detect enter & exit region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(region.identifier) {
            if poi.poiRegionNotifyEnter {
                AppDelegate.notifyRegionUpdate(poi: poi, isEntering:true)
            }
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
    }
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
    }
    
    // Post an internal notification when the Authorization status has been changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("\(#function): Warning the authorization status of Location Manager has changed to \(LocationManager.getStatus(status: status))")
        NotificationCenter.default.post(name: Notification.Name(rawValue: LocationNotifications.AuthorizationHasChanged), object: manager)
    }

}
