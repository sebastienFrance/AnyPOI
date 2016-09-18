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

class TodayViewController: UIViewController {
    
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
        }
        
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext!.widgetLargestAvailableDisplayMode = .Expanded
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        resetTableViewSize()
     
    }
    
    // Reload the tableView and update the Widget height
    private func resetTableViewSize() {
        theTableView.reloadData()
        if matchingPOI.count > 0 {
            //            preferredContentSize = CGSizeMake(0.0, CGFloat(matchingPOI.count) * 50.0)
            preferredContentSize = theTableView.contentSize
            theTableView.separatorStyle = .SingleLine
        } else {
            preferredContentSize = theTableView.contentSize
           // preferredContentSize = CGSizeMake(0.0, 50.0)
            theTableView.separatorStyle = .None
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        matchingPOI.removeAll()
    }
    
    // Returns True when the POI array is identical to the current Array
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
    
    private struct Cste {
        static let radiusInKm = 10.0
        static let maxRequestedResults = 5
    }
    
    private func getPoisAround(location:CLLocation) -> [PointOfInterest] {
        return PoiBoundingBox.getPoiAroundCurrentLocation(location, radius: Cste.radiusInKm, maxResult: Cste.maxRequestedResults)
    }
}

extension TodayViewController: NCWidgetProviding {
    // MARK: NCWidgetProviding
    
    // Update the Wiget content if the list of POIs has changed
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        if let location = LocationManager.sharedInstance.locationManager?.location {
            let pois = getPoisAround(location)
            if isSamePOIs(pois) {
                completionHandler(NCUpdateResult.NoData)
            } else {
                matchingPOI = pois
                resetTableViewSize()
                completionHandler(NCUpdateResult.NewData)
            }
        } else {
            completionHandler(NCUpdateResult.NoData)
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsetsZero
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == NCWidgetDisplayMode.Compact {
            self.preferredContentSize = CGSizeMake(0.0, 200.0)
        }
        else if activeDisplayMode == NCWidgetDisplayMode.Expanded {
            self.preferredContentSize = theTableView.contentSize
        }
        
    }
}

extension TodayViewController: LocationUpdateDelegate{
    
    // Update the list of POIs when the user location has changed
    func locationUpdated(locations: [CLLocation]) {
        if let location = locations.last {
            let pois = getPoisAround(location)
            if !isSamePOIs(pois) {
                matchingPOI = pois
                theTableView.reloadData()
            }
        }
    }
}

extension TodayViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: TableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingPOI.count > 0 ? matchingPOI.count : 1
    }
    
    private struct CellIndentifier {
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
            
            if #available(iOSApplicationExtension 10.0, *) {
                cell.textLabel?.textColor = UIColor.blackColor()
            } else {
                cell.textLabel?.textColor = UIColor.lightGrayColor()
            }

            return cell
        }
    }
    
    // MARK: TableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if matchingPOI.count > 0 {
            
            // Open AnyPOI App with the selected POI
            
            if let url = NavigationURL.showPoiOnMapURL(matchingPOI[indexPath.row]) {
                extensionContext?.openURL(url, completionHandler: nil)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.theTableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
}
