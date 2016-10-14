//
//  LocationManagerDelegate.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 07/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreLocation
import AudioToolbox

// This class manage the user location 
// By default we just request the location when the user is using the App, not in Background. This location
// is used to display the user location on the Map.
//
// When the user activate the Region Monitoring on a POI then we ask for the Background location update with
// AlwaysAuthorization
//
// When the Region Monitoring is enabled, the App trigger notifications to warn the user when he enters/exits a POI region
//
// Notifications: 
// - AuthorizationHasChanged is sent each time the location authorization has been changed. Currently it's not used by the App

class LocationManager : NSObject, CLLocationManagerDelegate {
    
    struct LocationNotifications {
        static let AuthorizationHasChanged = "AuthorizationHasChanged"
    }
    
    var locationManager:CLLocationManager?

    static let MAX_MONITORED_POIS = 20

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
            print("\(#function): No authorization granted for CLLocationManager")
        case .notDetermined:
            locationManager = CLLocationManager()
            if let locationMgr = locationManager {
                locationMgr.delegate = self
                locationMgr.requestWhenInUseAuthorization()
                if !CLLocationManager.significantLocationChangeMonitoringAvailable() {
                    print("\(#function): Warning significantLocationChangeMonitoringAvailable is not available on this device")
                }
            } else {
                print("\(#function): error CLLocationManager cannot be created!")
            }
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            print("\(#function): Authorization is: \(authorizationStatus.rawValue)")
        }
    }

    func isMaxMonitoredRegionReached() -> Bool {
        return POIDataManager.sharedInstance.getAllMonitoredPOI().count == LocationManager.MAX_MONITORED_POIS ? true : false
    }
    
    // When a POI must be monitored then:
    //  1- We check if the max # of Monitored region has been already reached
    //  2- We request the "Always Authorization" that is mandatory to use region monitoring
    //  3- We start the monitoring the of POI and it's recorded in the list of monitored POIs
    func startMonitoringRegion(_ poi:PointOfInterest) {
        if isMaxMonitoredRegionReached() {
            print("\(#function): Error, max numnber of monitored POI is already reached")
            return
        }

        requestAlwaysAuthorization()
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.startMonitoring(for: CLCircularRegion(center: poi.coordinate, radius: poi.poiRegionRadius, identifier: poi.poiRegionId!))
            if locationManager!.monitoredRegions.count != POIDataManager.sharedInstance.getAllMonitoredPOI().count {
                print("\(#function) Error: Number of Monitored region: in CLLLocationManager \(locationManager!.monitoredRegions.count) and in Database \(POIDataManager.sharedInstance.getAllMonitoredPOI().count) are not equals!")
               dumpMonitoredRegions()
            }
        } else {
            print("\(#function): Warning isMonitoringAvailableForClass is not available on this device")
        }
    }
    
    func dumpMonitoredRegions() {
        for region in locationManager!.monitoredRegions {
            print("RegionId from CLLocationManager: \(region.identifier)")
        }
        
        for currentPOI in POIDataManager.sharedInstance.getAllMonitoredPOI() {
            print("Monitored Poi: \(currentPOI.poiDisplayName!) with RegionId \(currentPOI.poiRegionId!) ")
        }
       
    }
    

    // When a POI must be removed from the Monitored region
    //  1- the POI is removed from the Monitored region
    //  2- It's removed from the internal list of monitored POIs
    func stopMonitoringRegion(_ poi:PointOfInterest) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.stopMonitoring(for: CLCircularRegion(center: poi.coordinate, radius: poi.poiRegionRadius, identifier: poi.poiRegionId!))
            if locationManager!.monitoredRegions.count != POIDataManager.sharedInstance.getAllMonitoredPOI().count {
                print("\(#function) Error: Number of Monitored region: in CLLLocationManager \(locationManager!.monitoredRegions.count) and in Database \(POIDataManager.sharedInstance.getAllMonitoredPOI().count) are not equals!")
                dumpMonitoredRegions()
            }
        } else {
            print("\(#function): Warning isMonitoringAvailableForClass is not available on this device")
        }
    }

    func updateMonitoringRegion(_ poi:PointOfInterest) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            stopMonitoringRegion(poi)
            startMonitoringRegion(poi)
        }
    }
 
    // Ask the user to enable the "Always Authorization"
    // The Settings button open the App Setting to enable the "Always Authorization"
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
    
    // Return true when at the App has WhenInUser or Always authorization, otherwise it returns false
    func isLocationAuthorized() -> Bool {
        let authorizationStatus  = CLLocationManager.authorizationStatus()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            return true
        } else {
            return false
        }
    }
    
    //MARK: SignificantLocationChanges
   // Called when a SignificantLocationChanges has occured
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\(#function): Location Manager didUpdateLocations")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(#function): Location Manager didFailWithError: \(error.localizedDescription)")
    }
    
    //MARK: Enter/Exit region
    
    // IMPORTANT: didEnterRegion and didExitRegion require .AuthorizedAlways. If it's not .AuthorizedAlways
    // it will not detect enter & exit region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(region.identifier) {
            if poi.poiRegionNotifyEnter {
                LocationManager.notifyRegionUpdate(poi, message:"\(NSLocalizedString("EnteringRegionLocationManager", comment: "")) \(poi.poiDisplayName!)")
            }
        } else {
            print("\(#function): Error, didEnterRegion but not found the related POI! We should remove this CLRegion for the monitored list")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let poi = POIDataManager.sharedInstance.findPOIWithRegiondId(region.identifier) {
            if poi.poiRegionNotifyExit {
                LocationManager.notifyRegionUpdate(poi, message:"\(NSLocalizedString("ExitingRegionLocationManager", comment: "")) \(poi.poiDisplayName!)")
            }
        } else {
            print("\(#function): Error, didEnterRegion but not found the related POI! We should remove this CLRegion for the monitored list")
        }
    }
    
    // Used to notify the user when he's entering/exiting a POI
    //  1- Send a notification to the Notification Center
    //  2- Update the Badge with Notification Number -> Always 1 !!!!
    //  3- Vibrate the device
    fileprivate static func notifyRegionUpdate(_ poi:PointOfInterest, message:String) {
        let notification = UILocalNotification()
        notification.fireDate = Date()
        // SEB: Swift3
        //notification.timeZone = TimeZone()
        notification.alertBody = message
        //notification.repeatCalendar = .Day
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.applicationIconBadgeNumber = 1
        UIApplication.shared.presentLocalNotificationNow(notification)
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    //MARK: Not yet used
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("Location Manager didFinishDeferredUpdatesWithError")
    }
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location Manager locationManagerDidPauseLocationUpdates")
    }
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("Location Manager locationManagerDidResumeLocationUpdates")
    }
    
    // Post an internal notification when the Authorization status has been changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("\(#function): Warning the authorization status of Location Manager has changed to \(status.rawValue)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: LocationNotifications.AuthorizationHasChanged), object: manager)
    }
}
