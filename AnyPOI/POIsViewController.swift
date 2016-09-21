//
//  POIsViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class POIsViewController: UIViewController  {
    
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 114
                theTableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
            }
        }
    }
    
    @IBOutlet weak var moveButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    enum DisplayMode {
        case simpleGroup, monitoredPois, cityPois, countryPois
    }
    
    private var displayMode = DisplayMode.simpleGroup
    private var displayModeFilter = ""
    private var areaName = ""
    private var POIGroup:GroupOfInterest!
    
    // Cache for images
    private var images = [Int:UIImage]()
    
    
    // Search
    private var searchController:UISearchController!
    private var searchFilter = "" // Use to perform filtering on list of groups
    
    // Datasource
    private var pois:[PointOfInterest]? = nil
    private var poisWithFilters:[PointOfInterest]? = nil

    // Map image
    private var snapshotter:MKMapSnapshotter?
    private var snapshotImage:UIImage?
    
    private struct Cste {
        static let MapViewHeight = CGFloat(170.0)
        static let POISizeInMapView = CGFloat(10.0)
    }

    //MARK: VC Initialization
    func showCityPoi(cityName: String) {
        displayMode = .cityPois
        displayModeFilter = cityName
        areaName = cityName
    }
    
    func showCountryPoi(countryName: String, name:String) {
        displayMode = .countryPois
        displayModeFilter = countryName
        areaName = name
    }
    
    func showMonitoredPois() {
        displayMode = .monitoredPois
        areaName = "Monitored POIs"
    }
    
    func showGroup(group:GroupOfInterest) {
        POIGroup = group
        displayMode = .simpleGroup
        areaName = group.groupDisplayName!
    }
    
    private func getPoiForIndexPath(indexPath:NSIndexPath) -> PointOfInterest {
        return getPois(true)[indexPath.row]
    }
    
    
    //MARK: Initialization
     override func viewDidLoad() {
        super.viewDidLoad()
        getMapSnapshot()
        resetStateOfEditButtons()
        
        initSearchController()
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POIsViewController.contextDidSaveNotification(_:)), name: NSManagedObjectContextDidSaveNotification, object: managedContext)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POIsViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POIsViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
   }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove the search controller when moving to another view controller
        if searchController.active {
            searchController.dismissViewControllerAnimated(false, completion: nil)
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: notification
    func contextDidSaveNotification(notification : NSNotification) {
        PoiNotificationUserInfo.dumpUserInfo("POIsViewController", userInfo: notification.userInfo)
        
        pois = nil // Reset the data
        poisWithFilters = nil
        
        // If the table is editing it means we are deleting the Poi directly from
        // this controller
        // If it's not editing it means the PoiGroup has been changed from another controller
        if !theTableView.editing {
            theTableView.reloadData()
        }

        resetStateOfEditButtons()
        
        getMapSnapshot()
    }

    
    //MARK: Utils
    private func getPois(withFilter:Bool) -> [PointOfInterest] {
        if !withFilter {
            if pois == nil {
                pois = extractPOIsFromDatabase(false)
            }
            return pois!
        } else {
            if poisWithFilters == nil {
                poisWithFilters = extractPOIsFromDatabase(true)
            }
            return poisWithFilters!
        }
    }
    
    private func extractPOIsFromDatabase(withFilter:Bool) -> [PointOfInterest] {
        let filter = withFilter ? searchFilter : ""
        switch displayMode {
        case .monitoredPois:
            return POIDataManager.sharedInstance.getAllMonitoredPOI(filter)
        case .simpleGroup:
            return POIDataManager.sharedInstance.getPOIsFromGroup(POIGroup, searchFilter: filter)
        case .cityPois:
            return POIDataManager.sharedInstance.getAllPOIFromCity(displayModeFilter, searchFilter: filter)
        case .countryPois:
            return POIDataManager.sharedInstance.getAllPOIFromCountry(displayModeFilter, searchFilter: filter)
        }
    }
    
    
    private func resetStateOfEditButtons() {
        if getPois(true).count == 0 {
            selectButton.enabled = false
            moveButton.enabled = false
            
            // search button must be disabled only if there's nothing even
            // when the filter is not set
            if getPois(false).count == 0 {
                searchButton.enabled = false
            }
        } else {
            selectButton.enabled = true
            moveButton.enabled = true
            searchButton.enabled = true
        }
    }
    
    private func startEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = true
        theTableView.setEditing(true, animated: true)
        moveButton.title = "Move"
        moveButton.enabled = false
        selectButton.title = "Done"
    }
    
    private func stopEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = false
        theTableView.setEditing(false, animated: true)
        moveButton.title = "Move all"
        moveButton.enabled = true
        selectButton.title = "Select"
    }

    // Display all POIs without any filter in the Map
    private func getMapSnapshot() {
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MapUtils.boundingBoxForAnnotations(getPois(false))
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .Standard ? .Standard : .Satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSizeMake(view.bounds.width, Cste.MapViewHeight)
        snapshotOptions.scale = 2.0
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter!.startWithCompletionHandler() { mapSnapshot, error in
            if let error = error {
                print("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                
                if let mapImage = mapSnapshot?.image {
                    
                    UIGraphicsBeginImageContextWithOptions(mapImage.size, true, mapImage.scale)
                    // Put the Map in the Graphic Context
                    mapImage.drawAtPoint(CGPointMake(0, 0))
                    
                    for currentPoi in self.getPois(false) {
                        
                        // Draw the Pin image in the graphic context
                        let background = CAShapeLayer()
                        let rect = CGRectMake(mapSnapshot!.pointForCoordinate(currentPoi.coordinate).x,
                            mapSnapshot!.pointForCoordinate(currentPoi.coordinate).y,
                            Cste.POISizeInMapView,Cste.POISizeInMapView)
                        let path = UIBezierPath(ovalInRect: rect)
                        background.path = path.CGPath
                        background.fillColor = currentPoi.parentGroup!.color.CGColor
                        background.strokeColor = UIColor.blackColor().CGColor
                        background.lineWidth = 1
                        background.setNeedsDisplay()
                        background.renderInContext(UIGraphicsGetCurrentContext()!)
                    }
                    
                    // Get the final image from the Grapic context
                    self.snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    // Update the section 0 that display the Map as background
                    self.theTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                }
            }
        }
    }
    

    // MARK: Action buttons
    @IBAction func searchButtonPushed(sender: UIBarButtonItem) {
        presentViewController(searchController, animated: true, completion: nil)
    }

    @IBAction func showPOIOnMap(sender: UIButton) {
        let selectedPoi = getPoiForIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0))
        NSNotificationCenter.defaultCenter().postNotificationName(MapViewController.MapNotifications.showPOI, object: nil, userInfo: [MapViewController.MapNotifications.showPOI_Parameter_POI: selectedPoi])
        
        ContainerViewController.sharedInstance.goToMap()
    }
    
    @IBAction func selectButtonPushed(sender: UIBarButtonItem) {
        // Start or end the editing mode
        theTableView.editing ? stopEditingMode() : startEditingMode()
    }
    
    
    @IBAction func movePOIs(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showMovePOISId", sender: nil)
    }

    //MARK: Keyboard Mgt
    var contentInsetBeforeDisplayedKeyboard = UIEdgeInsetsZero
    
    func keyboardWillShow(notification:NSNotification) {
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var contentInsets:UIEdgeInsets
            if UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            } else {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.width, 0.0)
            }
            
            contentInsetBeforeDisplayedKeyboard = theTableView.contentInset
            theTableView.contentInset = contentInsets
            theTableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    
    func keyboardWillHide(notification:NSNotification) {
        theTableView.contentInset = contentInsetBeforeDisplayedKeyboard
        theTableView.scrollIndicatorInsets = contentInsetBeforeDisplayedKeyboard
    }
    
    
    // MARK: Segue
    private struct storyboard {
        static let showPOIDetails = "ShowPOIDetailsIdFromPoisList"
        static let showMovePOISId = "showMovePOISId"
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == storyboard.showPOIDetails {
            let poiController = segue.destinationViewController as! POIDetailsViewController
            let currentPOI = getPoiForIndexPath(sender as! NSIndexPath)
            poiController.poi = currentPOI
        } else if segue.identifier == storyboard.showMovePOISId {
            let movePOIsController = segue.destinationViewController as! MovePOIsViewController
            if theTableView.editing, let indexPaths = theTableView.indexPathsForSelectedRows {
                var selectedPois = [PointOfInterest]()
                for currentIndex in indexPaths {
                    selectedPois.append(getPoiForIndexPath(currentIndex))
                }
                movePOIsController.pois = selectedPois
                stopEditingMode()
            } else {
                movePOIsController.pois = getPois(true)
            }
        }
    }
}

extension POIsViewController : UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    //MARK: Search Controller
    private func initSearchController() {
        // Open the search controller on itself
        searchController = UISearchController(searchResultsController: nil)
        
        // Configure the UISearchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "POI name"
        searchController.obscuresBackgroundDuringPresentation = false // Mandatory when opening the search controller on itself
        // Don't hide the navigation bar, it will be just covered by the SearchController (it will avoid the tableview to slide below
        // the searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
    }

    //MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        // To be completed
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(searchController: UISearchController) {
        // Nothing to do because we keep the filter!
    }
    
    
    //MARK: UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        resetStateOfEditButtons()
        poisWithFilters = nil
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.text = searchFilter
    }
}
extension POIsViewController : UITableViewDataSource, UITableViewDelegate {
    
    struct Sections {
        static let MapView = 0
        static let POIs = 1
    }

    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.POIs {
            let poisCount = getPois(true).count
            return poisCount == 0 ? 1 : poisCount
        } else {
            return 1
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    private struct cellIdentifier {
        static let descriptionCellId = "POISimpleCellId"
        static let cellForEmptyGroupId = "cellForEmptyGroupId"
        static let cellPoisMapAreaId = "cellPoisMapAreaId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Sections.MapView {
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.cellPoisMapAreaId, forIndexPath: indexPath) as! PoisMapAreaTableViewCell
            if let theSnapshotter = snapshotter where !theSnapshotter.loading {
                let imageView = UIImageView(image: snapshotImage)
                imageView.contentMode = .ScaleAspectFill
                imageView.clipsToBounds = true
                imageView.alpha = UserPreferences.sharedInstance.mapMode == .Standard ? 0.3 : 0.6
                theCell.backgroundView = imageView
            }
            
            theCell.groupLabel?.text = areaName
            return theCell
        } else {
            if getPois(true).count > 0 {
                let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.descriptionCellId, forIndexPath: indexPath) as! POISimpleViewCell
                let currentPOI = getPoiForIndexPath(indexPath)
                
                if let image = images[indexPath.row] {
                    theCell.initializeWith(currentPOI, index: indexPath.row, image:image)
                } else {
                    theCell.initializeWith(currentPOI, index: indexPath.row)
                }
                return theCell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.cellForEmptyGroupId, forIndexPath: indexPath)
                if getPois(false).count > 0 {
                    cell.textLabel?.text = "No POIs matching \(searchFilter)"
                    cell.textLabel?.textColor = UIColor.greenColor()
                } else {
                    cell.textLabel?.text = "No POIs in this group"
                    cell.textLabel?.textColor = UIColor.redColor()
                }
                return cell
            }
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Sections.MapView {
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Sections.MapView {
            if let theSnapshotter = snapshotter where !theSnapshotter.loading {
                return Cste.MapViewHeight
            } else {
                return 0
            }
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Sections.POIs {
            switch editingStyle {
            case .Delete:
                
                theTableView.beginUpdates()
                let thePoiToDelete = getPoiForIndexPath(indexPath)
                POIDataManager.sharedInstance.deletePOI(POI: thePoiToDelete)
                POIDataManager.sharedInstance.commitDatabase()
                theTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                if getPois(true).count == 0 {
                    theTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
                theTableView.endUpdates()
            default: break
                // just ignore, manage only deletion
                
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == Sections.MapView {
            return false
        } else if indexPath.section == Sections.POIs && getPois(true).count == 0 {
            return false
        } else {
            return true
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Sections.POIs {
            if getPois(true).count > 0 && !theTableView.editing {
                performSegueWithIdentifier(storyboard.showPOIDetails, sender: indexPath)
            } else if theTableView.editing {
                moveButton.enabled = true
            }
        } else if indexPath.section == Sections.MapView {
            let pois = getPois(false)
            NSNotificationCenter.defaultCenter().postNotificationName(MapViewController.MapNotifications.showPOIs, object: nil, userInfo: [MapViewController.MapNotifications.showPOIs_Parameter_POIs: pois])
            
            ContainerViewController.sharedInstance.goToMap()
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Sections.POIs {
            if theTableView.editing && theTableView.indexPathsForSelectedRows == nil {
                moveButton.enabled = false
            }
        }
    }
}
