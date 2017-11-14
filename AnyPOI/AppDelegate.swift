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
import PKHUD
import UserNotifications
import AudioToolbox
import StoreKit
import WatchConnectivity

//import UberRides

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    fileprivate var userAuthentication:UserAuthentication!
    
    fileprivate var poiToShowOnMap:PointOfInterest?
    fileprivate var routeToShowOnMap:Route?
    
    fileprivate var shortcutMarkCurrentLocation = false
    fileprivate var shortcutSearchPOIs = false
    
    fileprivate var importURL:URL?
    
    fileprivate struct ShortcutAction {
        static let markCurrentLocation = "com.sebastien.AnyPOI.POICurrentLocation"
        static let searchPOIs = "com.sebastien.AnyPOI.SearchPOI"
    }
    
    struct LocalNotificationId {
        static let monitoringRegionId = "MonitoringRegion"
        static let monitoringRegionPOI = "POI"
    }
    
    struct Notifications {
        // This notification is sent only when the product has been successfully purchased
        static let purchasedProduct = "purchasedProduct"
    }
    
    // This method is called only when the App start from scratch. 
    // We must:
    // 1- Initialize the User Authentication
    // 2- Start the payment queue
    // 3- Register for local notifications
    // 4- Register notification for end of contact synchronization
    // 5- Start user location
    // 6- Start Watch Connectivity session
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
       
        if let theLaunchOptions = launchOptions, let _ = theLaunchOptions[UIApplicationLaunchOptionsKey.location] {
            NSLog("\(#function) Application started due to location update")
        } else {
            NSLog("\(#function) Normal launch app")
        }
        
        
        if userAuthentication == nil {
            userAuthentication = UserAuthentication(delegate: self)
        }
        
        SKPaymentQueue.default().add(self)
        
        // Register local notification (alert & sound)
        // They are used to notify the user when entering/exiting a monitored region
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
            if let theError = error {
                NSLog("\(#function) error when request localNotification \(theError.localizedDescription)")
            } else {
                if !granted {
                    NSLog("\(#function) Warning local notification not granted")
                }
            }
            
         })
        
        let notificationCategory = UNNotificationCategory(identifier: CommonNotificationUtils.category, actions: [], intentIdentifiers: [],  options: [])
        let categories: Set = [notificationCategory]
        UNUserNotificationCenter.current().setNotificationCategories(categories)

        
        // Register notification to raise an alert when all contacts have been synchronized
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notifyContactsSynchronizationDone(_:)),
                                               name: NSNotification.Name(rawValue:ContactsSynchronization.Notifications.synchronizationDone),
                                               object: ContactsSynchronization.sharedInstance)
        
 
        // Start the location Manager only if it's not the first startup
        // On the first startup the location manager is started only when the map is displayed (to ask user to authorize the App to monitor user location)
        if !UserPreferences.sharedInstance.isFirstStartup {
            LocationManager.sharedInstance.startLocationManager()
        }

        // Start the Watch Connectivity session (if supported)
        WatchSessionManager.sharedInstance.startSession()

        //SEB: Swift3 put in comment UBER
        // If true, all requests will hit the sandbox, useful for testing
//        Configuration.setSandboxEnabled(true)
//        // If true, Native login will try and fallback to using Authorization Code Grant login (for privileged scopes). Otherwise will redirect to App store
//        Configuration.setFallbackEnabled(false)
         
        return true
    }
    
    @objc func notifyContactsSynchronizationDone(_ notification:NSNotification) {
        if let vc = Utilities.getCurrentViewController() {
            
            var theMessage:String
            if let userInfo = notification.userInfo,
                let isSuccess = userInfo[ContactsSynchronization.Notifications.Parameter.isSuccess] as? Bool,
                let synchronizedContacts = userInfo[ContactsSynchronization.Notifications.Parameter.synchronizedContactsNumber] as? Int,
                let totalContacts = userInfo[ContactsSynchronization.Notifications.Parameter.totalContactsNumber] as? Int {
                if isSuccess {
                    theMessage = String(format: NSLocalizedString("ContactsSynchronizationDone %d", comment: ""), totalContacts)
                } else {
                    theMessage = NSLocalizedString("ContactsSynchronizationNotCompleted", comment: "")
                    theMessage += "\n"
                    theMessage += String(format:NSLocalizedString("Contacts synchronized: %d total: %d", comment: ""), synchronizedContacts, totalContacts)
                }
            } else {
                theMessage = "ContactsSynchronizationUnknownError"
            }
            
            Utilities.showAlertMessage(vc, title: NSLocalizedString("Information", comment: ""), message:theMessage)
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
        
        if let poiId = NavigationURL(openURL: url).getPoi(), let poi = POIDataManager.sharedInstance.getPOIWithURI(URL(string: poiId)!) {
            poiToShowOnMap = poi
            return true
        } else {
            poiToShowOnMap = nil
            
            importURL = url
            return true
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
        
        SKPaymentQueue.default().remove(self)
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
                    if MapViewController.isAddPoiAuthorized() {
                        let addedPOI = mapController.addPoiOnOnMapLocation(userCoordinate)
                        mapController.selectPoiOnMap(addedPOI)
                    } else {
                        Utilities.showAlertMaxPOI(viewController:mapController)
                    }
                } else {
                    Utilities.showAlertMessage(mapController, title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("UserLocationNotAvailableAppDelegate", comment: ""))
                }
            } else if shortcutSearchPOIs {
                shortcutSearchPOIs = false
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                mapController.showSearchController()
            } else if let importGPXFile = importURL {
                navigateToMapViewControllerFromAnywhere(UIApplication.shared)
                importURL = nil
                mapController.disableRouteMode()
                mapController.importFile(gpx:importGPXFile)
            } else {
                NSLog("\(#function) unknown action")
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

extension AppDelegate : UserAuthenticationDelegate {
    //MARK: UserAuthenticationDelegate
    func authenticationDone() {
        performNavigation()
    }
    
    func authenticationFailure() {
        NSLog("\(#function) Warning, we should never enter in this code")
    }
    
    func performActionOnStartup() {
        performNavigation()
    }
}

extension AppDelegate {
    //MARK: Utilities
    
    /// To notify user when he's entering or exiting the region around a POI
    ///  1- Send a notification to the Notification Center
    ///  2- Update the Badge with Notification Number -> Always 1 !!!!
    ///  3- Vibrate the device
    ///
    /// - parameter poi:     POI near the current location
    /// - parameter message: Message to be displayed
    static func notifyRegionUpdate(poi:PointOfInterest, isEntering:Bool) {
        let content = UNMutableNotificationContent()
        content.title = poi.poiDisplayName ?? "Error"
        content.subtitle = poi.address.replacingOccurrences(of: "\n", with: " ")
        
        var message:String
        if isEntering {
            message = String(format: NSLocalizedString("POI less than %d meters", comment: ""), Int(poi.poiRegionRadius))
        } else {
            message = String(format: NSLocalizedString("POI more than %d meters", comment: ""), Int(poi.poiRegionRadius))
        }
        
        content.body = message
        content.badge = 1
        content.sound = UNNotificationSound.default()
        content.userInfo[AppDelegate.LocalNotificationId.monitoringRegionPOI] = poi.objectID.uriRepresentation().absoluteString
        content.userInfo[CommonProps.singlePOI] = poi.props
        content.userInfo[CommonProps.regionRadius] = poi.poiRegionRadius
        content.categoryIdentifier = CommonNotificationUtils.category
        let request = UNNotificationRequest(identifier: AppDelegate.LocalNotificationId.monitoringRegionId, content:content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let theError = error {
                NSLog("\(#function) Error with notification add \(theError.localizedDescription)")
            }
        })
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

}

extension AppDelegate: SKPaymentTransactionObserver {
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        
        NSLog("received restored transactions: \(queue.transactions.count)")
        for transaction in queue.transactions {
            if transaction.transactionState == .restored {
                //called when the user successfully restores a purchase
                NSLog("\(#function) Transaction state -> Restored")

                UserPreferences.sharedInstance.isAnyPoiUnlimited = true
                SKPaymentQueue.default().finishTransaction(transaction)
                
                if let vc = Utilities.getCurrentViewController() {
                    Utilities.showAlertMessage(vc, title: NSLocalizedString("Warning", comment: ""), message:  NSLocalizedString("PurchaseRestored", comment: ""))
                }
                
                break;
            }
        }
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing: NSLog("\(#function) Transaction state -> Purchasing")
            //called when the user is in the process of purchasing, do not add any of your own code here.
            case .purchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                UserPreferences.sharedInstance.isAnyPoiUnlimited = true
                SKPaymentQueue.default().finishTransaction(transaction)
                NSLog("\(#function) Transaction state -> Purchased")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.purchasedProduct), object: self)
            case .restored:
                NSLog("\(#function) Transaction state -> Restored")
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                UserPreferences.sharedInstance.isAnyPoiUnlimited = true
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.purchasedProduct), object: self)
            case .failed:
                if let error = transaction.error {
                    NSLog("\(#function) transaction has failed with \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred:
                // The transaction is in the queue, but its final status is pending external action.
                NSLog("\(#function) Transaction state -> Deferred")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
            response.notification.request.content.categoryIdentifier == CommonNotificationUtils.category {
            if let poiAbsoluteString = response.notification.request.content.userInfo[LocalNotificationId.monitoringRegionPOI] as? String,
                let urlPOI = URL(string: poiAbsoluteString), let poi = POIDataManager.sharedInstance.getPOIWithURI(urlPOI) {
                poiToShowOnMap = poi
                if UserAuthentication.isUserAuthenticated {
                    DispatchQueue.main.async {
                        self.performNavigation()
                    }
                }
            }
        }
        completionHandler()
    }
}



