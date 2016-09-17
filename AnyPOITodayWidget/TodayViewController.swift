//
//  TodayViewController.swift
//  AnyPOITodayWidget
//
//  Created by Sébastien Brugalières on 17/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import CoreLocation
import MapKit

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDataSource, UITableViewDelegate, LocationUpdateDelegate {
    
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 50
                theTableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    var matchingPOI = [PointOfInterest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.sharedInstance.startLocationManager()
        LocationManager.sharedInstance.isLocationAuthorized()
        LocationManager.sharedInstance.delegate = self
        
        if let location = LocationManager.sharedInstance.locationManager?.location {
            matchingPOI = getPoisAround(location)
            resetTableViewSize()
        }
    }
    
    private func resetTableViewSize() {
        if matchingPOI.count > 0 {
            preferredContentSize = CGSizeMake(0.0, CGFloat(matchingPOI.count) * 50.0)
            theTableView.separatorStyle = .SingleLine
        } else {
            preferredContentSize = CGSizeMake(0.0, 50.0)
            theTableView.separatorStyle = .None
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        matchingPOI.removeAll()
    }
    
    func locationUpdated(locations: [CLLocation]) {
        if let location = locations.last {
            let pois = getPoisAround(location)
            if !isSamePOIs(pois) {
                matchingPOI = pois
                theTableView.reloadData()
            }
        }
    }
    
    
    private func isSamePOIs(pois:[PointOfInterest]) -> Bool {
        if matchingPOI.count == pois.count {
            for i in 0...(matchingPOI.count - 1) {
                if matchingPOI[i].objectID != pois[i].objectID {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
    
    private func getPoisAround(location:CLLocation) -> [PointOfInterest]{
        return PoiBoundingBox.getPoiAroundCurrentLocation(location, radius: 10, maxResult: 5)
    }
    
    // MARK: NCWidgetProviding
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        if let location = LocationManager.sharedInstance.locationManager?.location {
            let pois = getPoisAround(location)
            if isSamePOIs(pois) {
                completionHandler(NCUpdateResult.NoData)
            } else {
                matchingPOI = pois
                resetTableViewSize()
                theTableView.reloadData()
                
                completionHandler(NCUpdateResult.NewData)
            }
        } else {
            completionHandler(NCUpdateResult.NoData)
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsetsZero
    }
    
    // MARK: TableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingPOI.count > 0 ? matchingPOI.count : 1
    }
    
    struct CellIndentifier {
        static let CellPoiAroundPositionId = "TodayViewCellId"
        static let CellEmptyCellId = "TodayViewEmptyCellId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if matchingPOI.count > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIndentifier.CellPoiAroundPositionId, forIndexPath: indexPath) as! TodayViewCell
            cell.initWith(matchingPOI[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIndentifier.CellEmptyCellId, forIndexPath: indexPath)
            cell.textLabel?.text = "No point of interest near your position"
            return cell
        }
    }
    
    // MARK: TableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if matchingPOI.count > 0 {
            
            if let url = NavigationURL.showPoiOnMapURL(matchingPOI[indexPath.row]) {
                extensionContext?.openURL(url, completionHandler: nil)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.theTableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
}
