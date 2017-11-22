//
//  DebugLocationUpdateTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit

class DebugLocationUpdateTableViewController: UIViewController {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.dataSource = self
                tableView.delegate = self
                tableView.estimatedRowHeight = 110
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    enum DebugDataSource {
        case LocationUpdate, RegionMonitoring, NotificationHistory
    }
    
    var datasource = DebugDataSource.LocationUpdate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private struct storyboard {
         static let debugLocationUpdateCellId = "debugLocationUpdateCellId"
    }

}

extension DebugLocationUpdateTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch datasource {
        case .LocationUpdate:
            return LocationManager.sharedInstance.debugLocationUpdates.count > 0 ? LocationManager.sharedInstance.debugLocationUpdates.count : 1
        case .RegionMonitoring:
            return 1
        case .NotificationHistory:
            return AppDelegate.DebugInfo.Notification.notificationHistory.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theCell = theTableView.dequeueReusableCell(withIdentifier: storyboard.debugLocationUpdateCellId, for: indexPath) as! LetMenuDebugLocationUpdateTableViewCell
        
        switch datasource {
        case .LocationUpdate:
            if LocationManager.sharedInstance.debugLocationUpdates.count == 0 {
                theCell.watchReachableState.text = "No location update events!"
            } else {
                theCell.watchReachableState.text = LocationManager.sharedInstance.debugLocationUpdates[indexPath.row].debugTrace
            }
        case .RegionMonitoring:
            if let monitoredRegions = LocationManager.sharedInstance.locationManager?.monitoredRegions {
                if monitoredRegions.count > 0 {
                    theCell.watchReachableState.text = "\(monitoredRegions.count) regions are monitored"
                } else {
                    theCell.watchReachableState.text = "No monitored regions"
                }
            } else {
                theCell.watchReachableState.text = "No monitored regions & Location Manager is null!"
            }

        case .NotificationHistory:
            theCell.watchReachableState.text = "\(AppDelegate.DebugInfo.Notification.notificationHistory[indexPath.row].debug)"
        }
        
        
        return theCell
    }
    
        
}

extension DebugLocationUpdateTableViewController: UITableViewDelegate {
}
