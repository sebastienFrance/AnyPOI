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
            self.extensionContext!.widgetLargestAvailableDisplayMode = .expanded
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetTableViewSize()
     
    }
    
    // Reload the tableView and update the Widget height
    fileprivate func resetTableViewSize() {
        theTableView.reloadData()
        if matchingPOI.count > 0 {
            //            preferredContentSize = CGSizeMake(0.0, CGFloat(matchingPOI.count) * 50.0)
            preferredContentSize = theTableView.contentSize
            theTableView.separatorStyle = .singleLine
        } else {
            preferredContentSize = theTableView.contentSize
           // preferredContentSize = CGSizeMake(0.0, 50.0)
            theTableView.separatorStyle = .none
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        matchingPOI.removeAll()
    }
    
    // Returns True when the POI array is identical to the current Array
    fileprivate func isSamePOIs(_ pois:[PointOfInterest]) -> Bool {
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
    
    fileprivate struct Cste {
        static let radiusInKm = 10.0
        static let maxRequestedResults = 5
    }
    
    fileprivate func getPoisAround(_ location:CLLocation) -> [PointOfInterest] {
        return PoiBoundingBox.getPoiAroundCurrentLocation(location, radius: Cste.radiusInKm, maxResult: Cste.maxRequestedResults)
    }
}

extension TodayViewController: NCWidgetProviding {
    // MARK: NCWidgetProviding
    
    // Update the Wiget content if the list of POIs has changed
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        if let location = LocationManager.sharedInstance.locationManager?.location {
            let pois = getPoisAround(location)
            if isSamePOIs(pois) {
                completionHandler(NCUpdateResult.noData)
            } else {
                matchingPOI = pois
                resetTableViewSize()
                completionHandler(NCUpdateResult.newData)
            }
        } else {
            completionHandler(NCUpdateResult.noData)
        }
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsets.zero
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == NCWidgetDisplayMode.compact {
            self.preferredContentSize = CGSize(width: 0.0, height: 200.0)
        }
        else if activeDisplayMode == NCWidgetDisplayMode.expanded {
            self.preferredContentSize = theTableView.contentSize
        }
        
    }
}

extension TodayViewController: LocationUpdateDelegate{
    
    // Update the list of POIs when the user location has changed
    func locationUpdated(_ locations: [CLLocation]) {
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingPOI.count > 0 ? matchingPOI.count : 1
    }
    
    fileprivate struct CellIndentifier {
        static let CellPoiAroundPositionId = "TodayViewCellId"
        static let CellEmptyCellId = "TodayViewEmptyCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if matchingPOI.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIndentifier.CellPoiAroundPositionId, for: indexPath) as! TodayViewCell
            cell.initWith(matchingPOI[(indexPath as NSIndexPath).row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIndentifier.CellEmptyCellId, for: indexPath)
            cell.textLabel?.text = "No point of interest near your position"
            
            if #available(iOSApplicationExtension 10.0, *) {
                cell.textLabel?.textColor = UIColor.black
            } else {
                cell.textLabel?.textColor = UIColor.lightGray
            }

            return cell
        }
    }
    
    // MARK: TableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if matchingPOI.count > 0 {
            
            // Open AnyPOI App with the selected POI
            
            if let url = NavigationURL.showPoiOnMapURL(matchingPOI[(indexPath as NSIndexPath).row]) {
                extensionContext?.open(url, completionHandler: nil)
            }
            
            DispatchQueue.main.async {
                self.theTableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
}
