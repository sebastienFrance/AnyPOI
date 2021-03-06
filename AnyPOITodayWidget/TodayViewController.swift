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
    
    fileprivate var matchingPOI = [PointOfInterest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start Location Manager and add delegate to get update
        LocationManager.sharedInstance.startLocationManager()
        _ = LocationManager.sharedInstance.isLocationAuthorized()
        LocationManager.sharedInstance.delegate = self
        
        // get the list of POIs around the current position
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
        
        if let extensionContext = self.extensionContext {
            if #available(iOSApplicationExtension 10.0, *) {
                switch extensionContext.widgetActiveDisplayMode {
                case .compact:
                    self.preferredContentSize = CGSize(width: 0.0, height: 200.0)
                case .expanded:
                    self.preferredContentSize = CGSize(width: 0.0, height: 250.0) //theTableView.contentSize
                }
            } else {
                self.preferredContentSize = CGSize(width: 0.0, height: 200.0)
            }
        }
        
        theTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        matchingPOI.removeAll()
    }
    
    // Returns True when the POI array is identical to the current Array
    fileprivate func isSamePOIs(_ pois:[PointOfInterest]) -> Bool {
        return matchingPOI.elementsEqual(pois) { return $0.objectID == $1.objectID }
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
        
        switch activeDisplayMode {
        case .compact:
            self.preferredContentSize = CGSize(width: 0.0, height: 200.0)
        case .expanded:
            self.preferredContentSize = CGSize(width: 0.0, height: 300.0) //theTableView.contentSize
        }
        
        theTableView.reloadData()
    }
}

extension TodayViewController: LocationUpdateDelegate {
    
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
        if let extensionContext = self.extensionContext {
            if #available(iOSApplicationExtension 10.0, *) {
                if extensionContext.widgetActiveDisplayMode == .compact {
                    return matchingPOI.count > 0 ? min(matchingPOI.count, 2) : 1
                }
            } else {
                // Fallback on earlier versions
            }
        }
        return matchingPOI.count > 0 ? matchingPOI.count : 1
    }
    
    private struct CellIndentifier {
        static let CellPoiAroundPositionId = "TodayViewCellId"
        static let CellEmptyCellId = "TodayViewEmptyCellId"
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if matchingPOI.count > 0 {
            let theCell = cell as! TodayViewCell
            theCell.initMarker(poi: matchingPOI[indexPath.row])
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if matchingPOI.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIndentifier.CellPoiAroundPositionId, for: indexPath) as! TodayViewCell
            cell.initWith(matchingPOI[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIndentifier.CellEmptyCellId, for: indexPath)
            cell.textLabel?.text = NSLocalizedString("No POI near position", comment: "")
            
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
            
            if let url = NavigationURL.showPoiOnMapURL(matchingPOI[indexPath.row]) {
                extensionContext?.open(url, completionHandler: nil)
            }
            
            DispatchQueue.main.async {
                self.theTableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
}
