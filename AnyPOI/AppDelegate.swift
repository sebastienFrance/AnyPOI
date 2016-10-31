//
//  AppDelegate.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 06/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import LocalAuthentication
import CoreSpotlight
//import UberRides

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UserAuthenticationDelegate {

    var window: UIWindow?
    
    fileprivate var userAuthentication:UserAuthentication!
    
    fileprivate var poiToShowOnMap:PointOfInterest?
    fileprivate var routeToShowOnMap:Route?
    
    fileprivate var shortcutMarkCurrentLocation = false
    fileprivate var shortcutSearchPOIs = false
    
    fileprivate struct ShortcutAction {
        static let markCurrentLocation = "com.sebastien.AnyPOI.POICurrentLocation"
        static let searchPOIs = "com.sebastien.AnyPOI.SearchPOI"
    }

    // This method is called only when the App start from scratch. 
    // We must:
    // 1- Initialize the User Authentication
    // 2- Start user location
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("\(#function)")
       
        if userAuthentication == nil {
            userAuthentication = UserAuthentication(delegate: self)
        }
        
        LocationManager.sharedInstance.startLocationManager()
        
        if (UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:)))) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound] , categories: nil))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyContactsSynchronizationDone(_:)), name: NSNotification.Name(rawValue:ContactsSynchronization.Notifications.synchronizationDone), object: ContactsSynchronization.sharedInstance)
        
        //SEB: Swift3 put in comment UBER
        // If true, all requests will hit the sandbox, useful for testing
//        Configuration.setSandboxEnabled(true)
//        // If true, Native login will try and fallback to using Authorization Code Grant login (for privileged scopes). Otherwise will redirect to App store
//        Configuration.setFallbackEnabled(false)
        
        return true
    }
    
    func notifyContactsSynchronizationDone(_ notification:NSNotification) {
        if let vc = Utilities.getCurrentViewController() {
             Utilities.showAlertMessage(vc, title: NSLocalizedString("Information", comment: ""), message: NSLocalizedString("ContactsSynchronozationDone", comment: ""))
        }
    }

    
    // This method is called when the App is started by the Notification Center (or by another App)
    // Message flow when the App is started from scratch:
    // application:didFinishLaunchingWithOptions
    // application:openURL
    // MapViewController::viewDidLoad
    // MapViewController::viewWillAppear
    // applicationDidBecomeActive -> Request Authentication
    //    authenticationDone
    //       performNavigation
    //
    // When the Application is already started then we have the following message flow
    // application:openURL
    // applicationDidBecomeActive -> Request Authentication
    //    authenticationDone
    //       performNavigation
    //
    // When TouchId is enabled, we have one more applicationWillResignActive() + applicationDidBecomeActive() due to request authentication
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        print("\(#function)")
       
        if let poiId = NavigationURL(openURL: url).getPoi(), let poi = POIDataManager.sharedInstance.getPOIWithURI(URL(string: poiId)!) {
            poiToShowOnMap = poi
            return true
        } else {
            poiToShowOnMap = nil
            return false
        }
    }
    
    // This method is called when the App is started by SpotLight or UserActivity
    // Here messages flow when the App is started from scratch from Spotlight
    // application:didFinishLaunchingWithOptions
    // applicationDidBecomeActive -> Request Authentication
    //    authenticationDone
    //       performNavigation
    // MapViewController::viewDidLoad
    // MapViewController::viewWillAppear
    // application:continueUserActivity
    //       performNavigation
    //
    // When the App is already started 
    // application:continueUserActivity
    //       performNavigation
    // applicationDidBecomeActive -> Request Authentication
    //    authenticationDone
    //       performNavigation
    //
    // When TouchId is enabled, we have one more applicationWillResignActive() + applicationDidBecomeActive() due to request authentication
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("\(#function)")
        poiToShowOnMap = nil
        routeToShowOnMap = nil

       if userActivity.activityType == CSSearchableItemActionType,
          let uniqueIdentifier = userActivity.userInfo? [CSSearchableItemActivityIdentifier] as? String {
            if let poi = POIDataManager.sharedInstance.getPOIWithURI(URL(string: uniqueIdentifier)!) {
                poiToShowOnMap = poi
                
                if UserAuthentication.isUserAuthenticated {
                    DispatchQueue.main.async {
                        self.performNavigation()
                    }
                }

                return true
            } else if let route = POIDataManager.sharedInstance.getRouteWithURI(URL(string: uniqueIdentifier)!) {
                routeToShowOnMap = route
                
                if UserAuthentication.isUserAuthenticated {
                    DispatchQueue.main.async {
                        self.performNavigation()
                    }
                }

                return true
            }
        }
        
       return false
    }
    
    // Called when the Application is started by a Shortcut from the home screen
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleActionShortcut(shortcutItem)
    }
    
    // Warning: When TouchId is requesting authentication, this method is called
    // When the Authentication has been done successfully then the applicationDidBecomeActive is called
    func applicationWillResignActive(_ application: UIApplication) {
    }

    // When the App goes to background it is no more authenticated
    func applicationDidEnterBackground(_ application: UIApplication) {
       // askForUserAuthentication = true
        UserAuthentication.resignAuthentication()
    }

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("\(#function)")
    }

    // When the App becomes active and if we need authentication then we request it
    // Warning: applicationDidBecomeActive is also called when the User has performed authentication with TouchId
    func applicationDidBecomeActive(_ application: UIApplication) {
        if !UserAuthentication.isUserAuthenticated {
            userAuthentication.loopWhileNotAuthenticated()
        } else {
            performNavigation()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        DatabaseAccess.sharedInstance.saveContext()
    }
    
    //MARK: UserAuthenticationDelegate
    func authenticationDone() {
        performNavigation()
    }
    
    func authenticationFailure() {
        print("\(#function) Warning, we should never enter in this code")
    }

    func performActionOnStartup() {
        performNavigation()
    }
    
    //MARK: Utilities
    fileprivate func handleActionShortcut(_ shortcutItem: UIApplicationShortcutItem) {
        
        if shortcutItem.type == ShortcutAction.markCurrentLocation {
            shortcutMarkCurrentLocation = true
        } else if shortcutItem.type == ShortcutAction.searchPOIs {
            shortcutSearchPOIs = true

        } else {
            return
        }
        
        if UserAuthentication.isUserAuthenticated {
            DispatchQueue.main.async {
                self.performNavigation()
            }
        }

    }
    

    
    fileprivate func performNavigation() {
        // Perform navigation to the Poi or Route if needed
        if let mapController = MapViewController.instance , mapController.isViewLoaded {
            if let poi = poiToShowOnMap {
                poiToShowOnMap = nil
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                mapController.showPOIOnMap(poi)
            } else if let route = routeToShowOnMap {
                routeToShowOnMap = nil
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                mapController.enableRouteModeWith(route)
            } else if shortcutMarkCurrentLocation {
                shortcutMarkCurrentLocation = false
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                if let userCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate {
                    mapController.showLocationOnMap(userCoordinate)
                    let addedPOI = mapController.addPoiOnOnMapLocation(userCoordinate)
                    mapController.selectPoiOnMap(addedPOI)
                } else {
                    Utilities.showAlertMessage(mapController, title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("UserLocationNotAvailableAppDelegate", comment: ""))
                }
            } else if shortcutSearchPOIs {
                shortcutSearchPOIs = false
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                mapController.showSearchController()
            } else {
                print("\(#function) unknown action")
            }
        }
    }
    
    // Put the MapViewController on the top view
    // - Dismiss modal view controller
    // - Move the Navigation controller on the top view, which is the MapViewController
    // - Prepare the MapViewController (stop Flyover, ...)
    fileprivate func navigateToMapViewControllerFromAnywhere(_ application: UIApplication) {
        if let mapController = MapViewController.instance {
            if let presentedVC = application.keyWindow?.rootViewController?.presentedViewController {
                presentedVC.dismiss(animated: true, completion: nil)
            }
            
            ContainerViewController.sharedInstance.goToMap()
            
            mapController.prepareViewFromNavigation()
        }
    }
 }

