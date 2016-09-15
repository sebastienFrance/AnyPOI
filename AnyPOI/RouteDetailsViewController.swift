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
                tableView.estimatedRowHeight = 112
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
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RouteDetailsViewController.directionForWayPointUpdated(_:)),
                                                         name: Route.Notifications.directionForWayPointUpdated,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RouteDetailsViewController.directionDone(_:)),
                                                         name: Route.Notifications.directionsDone,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(RouteDetailsViewController.directionStarting(_:)),
                                                         name: Route.Notifications.directionStarting,
                                                         object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Actions
    @IBAction func doneButtonPushed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Update the transport type of a WayPoint and compute the new route to this WayPoint
    @IBAction func transportTypeChangeForWayPoint(sender: UISegmentedControl) {
        let transportType = MapUtils.segmentIndexToTransportType(sender)
        
        wayPointsDelegate.routeDatasource?.setTransportTypeForWayPointAtIndex(sender.tag, transportType: transportType)

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
    func directionStarting(notification : NSNotification) {
    }

    func directionForWayPointUpdated(notification : NSNotification) {
       // nothing to do because directionDone is always called at the end
    }

    func directionDone(notification : NSNotification) {
        theTableView.reloadData()
        enableView()
    }
    
    // MARK: Utilities
    // This function is used to compute the route between all waypoints
    // 1- Disable all actions from the view while loading the route
    // 2- load each piece of the route
    private func loadRoute() {
        disableView()
        wayPointsDelegate.routeDatasource?.theRoute.reloadDirections()
    }

    // MARK: Enable/Disable view

    // Disable the view controller while the route is loading
    private func disableView() {
        theTableView.allowsSelection = false
    }

    // Enable the View controller when the route has completed the loading
    private func enableView() {
        theTableView.allowsSelection = true
    }
}

extension RouteDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    private enum Sections:Int {
        case Summary = 0, WayPoints = 1
    }

    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .Summary:
            return 1
        case .WayPoints:
            return wayPointsDelegate.routeDatasource!.wayPoints.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .Summary:
            return nil
        case .WayPoints:
            return "Directions"
        }
    }
    
    private struct cellIdentifier {
        static let routeDetailsCellId = "routeDetailsCellId"
        static let routeSummaryId = "routeSummaryId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .Summary:
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.routeSummaryId,forIndexPath: indexPath) as! RouteSummaryTableViewCell
            
            if wayPointsDelegate.routeDatasource!.theRoute.wayPoints.count <= 1 {
                theCell.initWith(wayPointsDelegate.routeDatasource!.theRoute)
            } else {
                theCell.initWith(wayPointsDelegate.routeDatasource!.allRouteName, distanceAndDuration: wayPointsDelegate.routeDatasource!.allRouteDistanceAndTime)
            }
            return theCell
        case .WayPoints:
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.routeDetailsCellId, forIndexPath: indexPath) as! RouteDetailsViewCell
            theCell.initializePOI(wayPointsDelegate.routeDatasource!.wayPoints[indexPath.row].wayPointPoi!)
            
            // If it's not the last, then we must also display the transport type, distance...
            if indexPath.row != (wayPointsDelegate.routeDatasource!.wayPoints.count - 1) {
                theCell.initializeWayPoint(wayPointsDelegate.routeDatasource!.wayPoints[indexPath.row], index:indexPath.row)
            }
            
            theCell.editing = true
            return theCell
        }
    }
    
    // Authorize only deletion for WayPoints section
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch Sections(rawValue: indexPath.section)! {
        case .Summary:
            return .None
        case .WayPoints:
            return .Delete
        }
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return Sections(rawValue: indexPath.section)! == Sections.Summary ? false : true
    }
    
    // Manage WayPoint deletion
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if let realSection = Sections(rawValue: indexPath.section) {
            if realSection == .WayPoints {
                switch editingStyle {
                case .Delete:
                    theTableView.beginUpdates() // Must be done before performing deletion in model
                    wayPointsDelegate.deleteWayPointAt(indexPath.row)
                    theTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    theTableView.endUpdates() // After model update to delete the rows
                default: break
                    // just ignore, manage only deletion
                    
                }
            }
        }
    }
    
    // Only rows of Section that contains the WayPoints can be moved
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch Sections(rawValue: indexPath.section)! {
        case .Summary:
            return false
        case .WayPoints:
            return true
        }
    }
    
    // WayPoints can be moved only in its own Table section
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        let sourceSection = Sections(rawValue: sourceIndexPath.section)!
        let destinationSourceSection = Sections(rawValue: proposedDestinationIndexPath.section)!
        
        // Waypoint cannot be moved to the Summary section -> If the user tries, we force to go to the WayPoint section
        if sourceSection == .WayPoints && destinationSourceSection == .Summary {
            return NSIndexPath(forRow: 0, inSection: Sections.WayPoints.rawValue)
        }
        
        return proposedDestinationIndexPath
    }
    
    
    // When a row is moved we update the ordering of the wayPoint in the database
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // update indexes
        if let sourceCell = tableView.cellForRowAtIndexPath(sourceIndexPath) as? RouteDetailsViewCell {
            sourceCell.updateIndex(destinationIndexPath.row)
        }
        
        if let destinationCell = tableView.cellForRowAtIndexPath(destinationIndexPath) as? RouteDetailsViewCell {
            destinationCell.updateIndex(sourceIndexPath.row)
        }
        
        wayPointsDelegate.moveWayPoint(sourceIndexPath.row, destinationIndex:destinationIndexPath.row)
    }

}
