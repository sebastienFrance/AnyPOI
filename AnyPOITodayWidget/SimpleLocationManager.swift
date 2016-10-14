//
//  SimpleLocationManager.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreLocation

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

protocol LocationUpdateDelegate: class {
    func locationUpdated(_ locations: [CLLocation])
}


//FIXME: 😡😡⚡️⚡️ Code should be shared with Main App
class LocationManager : NSObject, CLLocationManagerDelegate {
    
    struct LocationNotifications {
        static let AuthorizationHasChanged = "AuthorizationHasChanged"
    }
    
    var locationManager:CLLocationManager?
    
    weak var delegate:LocationUpdateDelegate?
    
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
        delegate?.locationUpdated(locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(#function): Location Manager didFailWithError: \(error.localizedDescription)")
    }
    
    //MARK: Enter/Exit region not used
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("\(#function) Location Manager ")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("\(#function) Location Manager")
    }
    
    //MARK: Not yet used
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("\(#function) Location Manager")
    }
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("\(#function) Location Manager")
    }
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("\(#function) Location Manager")
    }
    
    // Post an internal notification when the Authorization status has been changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("\(#function): Warning the authorization status of Location Manager has changed to \(status.rawValue)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: LocationNotifications.AuthorizationHasChanged), object: manager)
    }
}
