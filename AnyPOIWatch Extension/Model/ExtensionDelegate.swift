//
//  ExtensionDelegate.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 30/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import UserNotifications

class ExtensionDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching() {
        NSLog("\(#function)")
        
        
        // Perform any final initialization of your application.
        UNUserNotificationCenter.current().delegate = self
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
//            if let theError = error {
//                NSLog("\(#function) error when request localNotification \(theError.localizedDescription)")
//            } else {
//                if !granted {
//                    NSLog("\(#function) Warning local notification not granted")
//                }
//            }
//
//        })

//        var actions = [UNNotificationAction]()
//        actions.append(UNNotificationAction(identifier: "CallId", title: "Call", options:[UNNotificationActionOptions.authenticationRequired] ))
//        actions.append(UNNotificationAction(identifier: "CallId2", title: "Go To", options:[UNNotificationActionOptions.authenticationRequired] ))
//
//        let notificationCategory = UNNotificationCategory(identifier: "MonitoringRegionCategory", actions: actions, intentIdentifiers: [],  options: [])
//        let categories: Set = [notificationCategory]
//        UNUserNotificationCenter.current().setNotificationCategories(categories)

        
        WatchSessionManager.sharedInstance.startSession()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("\(#function)")
        InterfaceController.sharedInstance?.refreshTable()
   }

    func applicationWillResignActive() {
        NSLog("\(#function)")
       // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func applicationWillEnterForeground() {
        NSLog("\(#function)")
    }
    
    func applicationDidEnterBackground() {
        NSLog("\(#function)")
    }
    
    func deviceOrientationDidChange() {
        NSLog("\(#function)")
    }
    

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        
        NSLog("\(#function) \(Debug.showAll())")
        
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                NSLog("\(#function) WKApplicationRefreshBackgroundTask")
               backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                NSLog("\(#function) WKSnapshotRefreshBackgroundTask")
                
                switch snapshotTask.reasonForSnapshot {
                case .appBackgrounded:
                    NSLog("\(#function) appBackgrounded")
                case .appScheduled:
                    NSLog("\(#function) appScheduled")
                case .complicationUpdate:
                    NSLog("\(#function) complicationUpdate")
                case .prelaunch:
                    NSLog("\(#function) prelaunch")
                case .returnToDefaultState:
                    NSLog("\(#function) returnToDefaultState")
                }
                
                
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                NSLog("\(#function) WKWatchConnectivityRefreshBackgroundTask")
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                NSLog("\(#function) WKURLSessionRefreshBackgroundTask")
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                NSLog("\(#function) default")
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("\(#function)")
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("\(#function)")
        completionHandler(.alert)
    }

}
