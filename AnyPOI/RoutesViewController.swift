//
//  RoutesViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 02/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData

class RoutesViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RoutesViewController.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: managedContext)
   }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }


    @objc func ManagedObjectContextObjectsDidChangeNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        
        if !notifContent.insertedRoutes.isEmpty || !notifContent.updatedRoutes.isEmpty {
            theTableView.reloadData()
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func addRouteButtonPushed(_ sender: UIBarButtonItem) {
        let routeEditor = RouteEditorController()
        routeEditor.createRouteWith(self, delegate: self)
    }
    
    @IBAction func editRouteName(_ sender: UIButton) {
        let theRoute = POIDataManager.sharedInstance.getAllRoutes()[sender.tag]
        let routeEditor = RouteEditorController()
        routeEditor.modifyRoute(self, delegate: self, route: theRoute)
    }
 
    func getSelectedRoute() -> Route? {
        if let index = theTableView.indexPathForSelectedRow {
           return POIDataManager.sharedInstance.getAllRoutes()[(index as NSIndexPath).row]
        } else {
            return nil
        }
    }
}

extension RoutesViewController: RouteEditorDelegate {
    //MARK: RouteEditorDelegate
    func routeCreated(_ route:Route) {
        // Nothing to do
    }
    
    func routeEditorCancelled() {
        // Nothing to do
    }
    
    func routeUpdated(_ route:Route) {
        // Nothing to do
    }
}

extension RoutesViewController: UITableViewDataSource, UITableViewDelegate {
 
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if POIDataManager.sharedInstance.getAllRoutes().count == 0 {
            return 1
        } else {
            return POIDataManager.sharedInstance.getAllRoutes().count
        }
    }
    
    fileprivate struct cellIdentifier {
        static let routesCellId = "routesCellId"
        static let routeCellWhenEmptyId = "RouteCellWhenEmptyId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if POIDataManager.sharedInstance.getAllRoutes().count != 0 {
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.routesCellId, for: indexPath) as! RoutesTableViewCell
            
            let theRoute = POIDataManager.sharedInstance.getAllRoutes()[indexPath.row]
            theCell.initWith(theRoute, index: indexPath.row)
            
            return theCell
        } else {
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.routeCellWhenEmptyId, for: indexPath)
            return theCell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return POIDataManager.sharedInstance.getAllRoutes().count != 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let theRoute = POIDataManager.sharedInstance.getAllRoutes()[indexPath.row]
            MapViewController.instance!.cleanup(withRoute:theRoute)
            POIDataManager.sharedInstance.deleteRoute(theRoute)
            POIDataManager.sharedInstance.commitDatabase()
            
            theTableView.beginUpdates()
            theTableView.deleteRows(at: [indexPath], with: .automatic)
            if POIDataManager.sharedInstance.getAllRoutes().count == 0 {
                theTableView.insertRows(at: [indexPath], with: .automatic)
            }
            theTableView.endUpdates()
        default: break
            // just ignore, manage only deletion
            
        }
    }

}
