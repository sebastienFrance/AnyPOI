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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UserAuthenticationDelegate {

    var window: UIWindow?
    
    private var userAuthentication:UserAuthentication!
    
    private var poiToShowOnMap:PointOfInterest?
    private var routeToShowOnMap:Route?
    
    private var markCurrentLocation = false
    
    private struct ShortcutAction {
        static let markCurrentLocation = "com.sebastien.AnyPOI.POICurrentLocation"
    }

    // This method is called only when the App start from scratch. 
    // We must:
    // 1- Initialize the User Authentication
    // 2- Start user location
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        print("\(#function)")
       
        if userAuthentication == nil {
            userAuthentication = UserAuthentication(delegate: self)
        }
        
        LocationManager.sharedInstance.startLocationManager()
        
        if (UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:)))) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound] , categories: nil))
        }
        
//        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
//            handleActionShortcut(shortcutItem)
//        }
//    

        
        return true
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
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        print("\(#function)")
       
        if let poiId = NavigationURL(openURL: url).getPoi(), poi = POIDataManager.sharedInstance.getPOIWithURI(NSURL(string: poiId)!) {
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
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        print("\(#function)")
        poiToShowOnMap = nil
        routeToShowOnMap = nil

       if userActivity.activityType == CSSearchableItemActionType,
          let uniqueIdentifier = userActivity.userInfo? [CSSearchableItemActivityIdentifier] as? String {
            if let poi = POIDataManager.sharedInstance.getPOIWithURI(NSURL(string: uniqueIdentifier)!) {
                poiToShowOnMap = poi
                
                if UserAuthentication.isUserAuthenticated {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.performNavigation()
                    }
                }

                return true
            } else if let route = POIDataManager.sharedInstance.getRouteWithURI(NSURL(string: uniqueIdentifier)!) {
                routeToShowOnMap = route
                
                if UserAuthentication.isUserAuthenticated {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.performNavigation()
                    }
                }

                return true
            }
        }
        
       return false
    }
    
    // Called when the Application is started by a Shortcut from the home screen
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        handleActionShortcut(shortcutItem)
    }
    
    private func handleActionShortcut(shortcutItem: UIApplicationShortcutItem) {
        
        if shortcutItem.type == ShortcutAction.markCurrentLocation {
            markCurrentLocation = true
            if UserAuthentication.isUserAuthenticated {
                dispatch_async(dispatch_get_main_queue()) {
                    self.performNavigation()
                }
            }

        } else {
            print("ApplicationShortcutItem unknown")
        }
        
    }
    
    // Warning: When TouchId is requesting authentication, this method is called
    // When the Authentication has been done successfully then the applicationDidBecomeActive is called
    func applicationWillResignActive(application: UIApplication) {
    }

    // When the App goes to background it is no more authenticated
    func applicationDidEnterBackground(application: UIApplication) {
       // askForUserAuthentication = true
        UserAuthentication.resignAuthentication()
    }

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    func applicationWillEnterForeground(application: UIApplication) {
    }

    // When the App becomes active and if we need authentication then we request it
    // Warning: applicationDidBecomeActive is also called when the User has performed authentication with TouchId
    func applicationDidBecomeActive(application: UIApplication) {
        if !UserAuthentication.isUserAuthenticated {
            userAuthentication.loopWhileNotAuthenticated()
        } else {
            performNavigation()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
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

    private func performNavigation() {
        // Perform navigation to the Poi or Route if needed
        if let mapController = MapViewController.instance where mapController.isViewLoaded() {
            if let poi = poiToShowOnMap {
                poiToShowOnMap = nil
                navigateToMapViewControllerFromAnywhere(UIApplication.sharedApplication())
                mapController.showPOIOnMap(poi)
            } else if let route = routeToShowOnMap {
                routeToShowOnMap = nil
                navigateToMapViewControllerFromAnywhere(UIApplication.sharedApplication())
                mapController.enableRouteModeWith(route)
            } else if markCurrentLocation {
                markCurrentLocation = false
                navigateToMapViewControllerFromAnywhere(UIApplication.sharedApplication())
                if let userCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate {
                    mapController.showLocationOnMap(userCoordinate)
                    let addedPOI = mapController.addPoiOnOnMapLocation(userCoordinate)
                    mapController.selectPoiOnMap(addedPOI)
                } else {
                    Utilities.showAlertMessage(mapController, title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("UserLocationNotAvailableAppDelegate", comment: ""))
                }
            } else {
                print("\(#function) unknown action")
            }
        }
    }
    
    // Put the MapViewController on the top view
    // - Dismiss modal view controller
    // - Move the Navigation controller on the top view, which is the MapViewController
    // - Prepare the MapViewController (stop Flyover, ...)
    private func navigateToMapViewControllerFromAnywhere(application: UIApplication) {
        if let mapController = MapViewController.instance {
            if let presentedVC = application.keyWindow?.rootViewController?.presentedViewController {
                presentedVC.dismissViewControllerAnimated(true, completion: nil)
            }
            
            ContainerViewController.sharedInstance.goToMap()
            
            mapController.prepareViewFromNavigation()
        }
    }
 }

