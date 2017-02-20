//
//  RouteDetailsViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 02/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class RouteDetailsViewController: UIViewController {
   
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                tableView.estimatedRowHeight = 163
                tableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var navigationItems: UINavigationItem!
    
    weak var wayPointsDelegate:MapViewController!
    
    // MARK: Initializations
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe Route notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RouteDetailsViewController.directionForWayPointUpdated(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionForWayPointUpdated),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RouteDetailsViewController.directionDone(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionsDone),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RouteDetailsViewController.directionStarting(_:)),
                                               name: NSNotification.Name(rawValue: Route.Notifications.directionStarting),
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Actions
    @IBAction func doneButtonPushed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // Update the transport type of a WayPoint and compute the new route to this WayPoint
    @IBAction func transportTypeChangeForWayPoint(_ sender: UISegmentedControl) {
        let transportType = MapUtils.segmentIndexToTransportType(sender)
        
        wayPointsDelegate.routeDatasource?.setTransportTypeForWayPoint(index:sender.tag, transportType: transportType)

        loadRoute()// Route has been changed -> reload direction!
    }


    func getSelectedWayPointIndex() -> Int {
        if let indexPath = theTableView.indexPathForSelectedRow {
            return indexPath.row
        } else {
            return 0
        }
    }
    
    //MARK: Route notifications
    
    // Nothing to do because HUD will be displayed by the
    // WayPointDetailsViewController when it will get the same notification
    func directionStarting(_ notification : Notification) {
    }

    func directionForWayPointUpdated(_ notification : Notification) {
       // nothing to do because directionDone is always called at the end
    }

    func directionDone(_ notification : Notification) {
        theTableView.reloadData()
        enableView()
    }
    
    // MARK: Utilities
    // This function is used to compute the route between all waypoints
    // 1- Disable all actions from the view while loading the route
    // 2- load each piece of the route
    fileprivate func loadRoute() {
        disableView()
        wayPointsDelegate.routeDatasource?.theRoute.reloadDirections()
    }

    // MARK: Enable/Disable view

    // Disable the view controller while the route is loading
    fileprivate func disableView() {
        theTableView.allowsSelection = false
    }

    // Enable the View controller when the route has completed the loading
    fileprivate func enableView() {
        theTableView.allowsSelection = true
    }
}

extension RouteDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    fileprivate enum Sections:Int {
        case summary = 0, wayPoints = 1
    }

    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .summary:
            return 1
        case .wayPoints:
            return wayPointsDelegate.routeDatasource!.wayPoints.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .summary:
            return nil
        case .wayPoints:
            return "Directions"
        }
    }
    
    fileprivate struct cellIdentifier {
        static let routeDetailsCellId = "routeDetailsCellId"
        static let routeSummaryId = "routeSummaryId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .summary:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.routeSummaryId,for: indexPath) as! RouteSummaryTableViewCell
            theCell.initWith(route:wayPointsDelegate.routeDatasource!.theRoute)
            return theCell
        case .wayPoints:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.routeDetailsCellId, for: indexPath) as! RouteDetailsViewCell
            theCell.initializePOI(wayPointsDelegate.routeDatasource!.wayPoints[indexPath.row].wayPointPoi!)
            
            // If it's not the last, then we must also display the transport type, distance...
            if indexPath.row != (wayPointsDelegate.routeDatasource!.wayPoints.count - 1) {
                theCell.initializeWayPoint(wayPointsDelegate.routeDatasource!.wayPoints[indexPath.row], index:indexPath.row)
            }
            
            theCell.isEditing = true
            return theCell
        }
    }
    
    // Authorize only deletion for WayPoints section
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        switch Sections(rawValue: indexPath.section)! {
        case .summary:
            return .none
        case .wayPoints:
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return Sections(rawValue: indexPath.section)! == Sections.summary ? false : true
    }
    
    // Manage WayPoint deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if let realSection = Sections(rawValue: indexPath.section) {
            if realSection == .wayPoints {
                switch editingStyle {
                case .delete:
                    theTableView.beginUpdates() // Must be done before performing deletion in model
                    wayPointsDelegate.deleteWayPointAt(indexPath.row)
                    theTableView.deleteRows(at: [indexPath], with: .automatic)
                    theTableView.endUpdates() // After model update to delete the rows
                default: break
                    // just ignore, manage only deletion
                    
                }
            }
        }
    }
    
    // Only rows of Section that contains the WayPoints can be moved
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        switch Sections(rawValue:indexPath.section)! {
        case .summary:
            return false
        case .wayPoints:
            return true
        }
    }
    
    // WayPoints can be moved only in its own Table section
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let sourceSection = Sections(rawValue: sourceIndexPath.section)!
        let destinationSourceSection = Sections(rawValue: proposedDestinationIndexPath.section)!
        
        // Waypoint cannot be moved to the Summary section -> If the user tries, we force to go to the WayPoint section
        if sourceSection == .wayPoints && destinationSourceSection == .summary {
            return IndexPath(row: 0, section: Sections.wayPoints.rawValue)
        }
        
        return proposedDestinationIndexPath
    }
    
    
    // When a row is moved we update the ordering of the wayPoint in the database
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // update indexes
        if let sourceCell = tableView.cellForRow(at: sourceIndexPath) as? RouteDetailsViewCell {
            sourceCell.updateIndex(destinationIndexPath.row)
        }
        
        if let destinationCell = tableView.cellForRow(at: destinationIndexPath) as? RouteDetailsViewCell {
            destinationCell.updateIndex(sourceIndexPath.row)
        }
        
        wayPointsDelegate.moveWayPoint(sourceIndex:sourceIndexPath.row, destinationIndex:destinationIndexPath.row)
    }

}
