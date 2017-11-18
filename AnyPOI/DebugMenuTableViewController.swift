//
//  DebugMenuTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit

class DebugMenuTableViewController: UITableViewController, ContainerViewControllerDelegate {

    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?
    
    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }
    
    struct Segues {
        static let RegionMonitoringId = "RegionMonitoringId"
        static let LocationUpdateId = "LocationUpdateId"
    }
    
    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            tableView.isUserInteractionEnabled = enable
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .plain, target: self, action: #selector(DebugMenuTableViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let debugController = segue.destination as! DebugLocationUpdateTableViewController
        
        switch segue.identifier! {
        case Segues.LocationUpdateId:
            debugController.datasource = .LocationUpdate
        case Segues.RegionMonitoringId:
            debugController.datasource = .RegionMonitoring
        default:
            break
        }
    }
    
}
