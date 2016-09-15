//
//  RoutesViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 02/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData

class RoutesViewController: UIViewController, RouteEditorDelegate, ContainerViewControllerDelegate {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                theTableView.estimatedRowHeight = 103
                theTableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?
    
    @objc private func menuButtonPushed(button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .Plain, target: self, action: #selector(RoutesViewController.menuButtonPushed(_:)))
            navigationItem.leftBarButtonItem = menuButton
        }
        
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RoutesViewController.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                                         name: NSManagedObjectContextObjectsDidChangeNotification,
                                                         object: managedContext)
   }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true
    }


    func ManagedObjectContextObjectsDidChangeNotification(notification : NSNotification) {
        print("==========> DidChangeNotification")
        PoiNotificationUserInfo.dumpUserInfo("RouteViewController", userInfo:notification.userInfo)
        let notifContent = PoiNotificationUserInfo(userInfo: notification.userInfo)
        
        if !notifContent.insertedRoutes.isEmpty || !notifContent.updatedRoutes.isEmpty {
            theTableView.reloadData()
        }
        
    }
    
    deinit {
        print("RoutesViewController deallocated!")
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @IBAction func addRouteButtonPushed(sender: UIBarButtonItem) {
        let routeEditor = RouteEditorController()
        routeEditor.createRouteWith(self, delegate: self)
    }
    
    @IBAction func editRouteName(sender: UIButton) {
        let theRoute = POIDataManager.sharedInstance.getAllRoutes()[sender.tag]
        let routeEditor = RouteEditorController()
        routeEditor.modifyRoute(self, delegate: self, route: theRoute)
    }
 
    func getSelectedRoute() -> Route? {
        if let index = theTableView.indexPathForSelectedRow {
           return POIDataManager.sharedInstance.getAllRoutes()[index.row]
        } else {
            return nil
        }
    }
    
    //MARK: RouteEditorDelegate
    func routeCreated(route:Route) {
        // Nothing to do
    }
    
    func routeEditorCancelled() {
        // Nothing to do
    }
    
    func routeUpdated(route:Route) {
        // Nothing to do
    }
}

extension RoutesViewController: UITableViewDataSource, UITableViewDelegate {
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return POIDataManager.sharedInstance.getAllRoutes().count
    }
    
    private struct cellIdentifier {
        static let routesCellId = "routesCellId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.routesCellId, forIndexPath: indexPath) as! RoutesTableViewCell
        
        let theRoute = POIDataManager.sharedInstance.getAllRoutes()[indexPath.row]
        theCell.initWith(theRoute, index: indexPath.row)
        
        return theCell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            let theRoute = POIDataManager.sharedInstance.getAllRoutes()[indexPath.row]
            POIDataManager.sharedInstance.deleteRoute(theRoute)
            POIDataManager.sharedInstance.commitDatabase()
            theTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        default: break
            // just ignore, manage only deletion
            
        }
    }

}
