//
//  DebugMenuTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit

class DebugMenuTableViewController: UITableViewController {

    
    struct Segues {
        static let RegionMonitoringId = "RegionMonitoringId"
        static let LocationUpdateId = "LocationUpdateId"
        static let showDailyTravelId = "showDailyTravelId"
        static let showNotificationHistory = "showNotificationHistory"
    }
    
    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            tableView.isUserInteractionEnabled = enable
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Make the height takes into account the safe area (especially for iPhone X)
        view.frame.size = CGSize(width: view.frame.width, height: view.frame.height - view.safeAreaInsets.bottom)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        

        switch segue.identifier! {
        case Segues.LocationUpdateId:
            let debugController = segue.destination as! DebugLocationUpdateTableViewController
            debugController.datasource = .LocationUpdate
        case Segues.RegionMonitoringId:
            let debugController = segue.destination as! DebugLocationUpdateTableViewController
            debugController.datasource = .RegionMonitoring
        case Segues.showNotificationHistory:
            let debugController = segue.destination as! DebugLocationUpdateTableViewController
            debugController.datasource = .NotificationHistory
        case Segues.showDailyTravelId:
            break
        default:
            break
        }
    }
    
}
