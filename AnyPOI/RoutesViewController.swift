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
    
    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }

    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            theTableView.isUserInteractionEnabled = enable
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .plain, target: self, action: #selector(RoutesViewController.menuButtonPushed(_:)))
            navigationItem.leftBarButtonItem = menuButton
        }
        
        
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


    func ManagedObjectContextObjectsDidChangeNotification(_ notification : Notification) {
        print("==========> DidChangeNotification")
        PoiNotificationUserInfo.dumpUserInfo("RouteViewController", userInfo:(notification as NSNotification).userInfo)
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
        return POIDataManager.sharedInstance.getAllRoutes().count
    }
    
    fileprivate struct cellIdentifier {
        static let routesCellId = "routesCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.routesCellId, for: indexPath) as! RoutesTableViewCell
        
        let theRoute = POIDataManager.sharedInstance.getAllRoutes()[(indexPath as NSIndexPath).row]
        theCell.initWith(theRoute, index: (indexPath as NSIndexPath).row)
        
        return theCell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let theRoute = POIDataManager.sharedInstance.getAllRoutes()[(indexPath as NSIndexPath).row]
            POIDataManager.sharedInstance.deleteRoute(theRoute)
            POIDataManager.sharedInstance.commitDatabase()
            theTableView.deleteRows(at: [indexPath], with: .automatic)
        default: break
            // just ignore, manage only deletion
            
        }
    }

}
