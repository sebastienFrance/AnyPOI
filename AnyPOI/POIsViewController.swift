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
                theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var moveButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    enum DisplayMode {
        case simpleGroup, monitoredPois, cityPois, countryPois, poisWithoutAddress
    }
    
    fileprivate var displayMode = DisplayMode.simpleGroup
    fileprivate var displayModeFilter = ""
    fileprivate var areaName = ""
    fileprivate var POIGroup:GroupOfInterest!
    
    // Cache for images
    fileprivate var images = [Int:UIImage]()
    
    
    // Search
    fileprivate var searchController:UISearchController!
    fileprivate var searchFilter = "" // Use to perform filtering on list of groups
    
    // Datasource
    fileprivate var pois:[PointOfInterest]? = nil
    fileprivate var poisWithFilters:[PointOfInterest]? = nil

    // Map image
    fileprivate var snapshotter:MKMapSnapshotter?
    fileprivate var snapshotImage:UIImage?
    
    fileprivate struct Cste {
        static let MapViewHeight = CGFloat(170.0)
        static let POISizeInMapView = CGFloat(10.0)
    }

    //MARK: VC Initialization
    func showCityPoi(_ cityName: String) {
        displayMode = .cityPois
        displayModeFilter = cityName
        areaName = cityName
    }
    
    func showCountryPoi(country:CountryDescription) {
        displayMode = .countryPois
        displayModeFilter = country.ISOCountryCode
        areaName = "\(country.countryFlag) \(country.countryName)"
    }
    
    func showMonitoredPois() {
        displayMode = .monitoredPois
        areaName = NSLocalizedString("MonitoredPOIs", comment: "")
    }
    
    func showPoisWithoutAddress() {
        displayMode = .poisWithoutAddress
        areaName = "POIs without address"
    }
    
    func showGroup(_ group:GroupOfInterest) {
        POIGroup = group
        displayMode = .simpleGroup
        areaName = group.groupDisplayName!
    }
    
    fileprivate func getPoiForIndexPath(_ indexPath:IndexPath) -> PointOfInterest {
        return getPois(withFilter: true)[indexPath.row]
    }
    
    
    //MARK: Initialization
     override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForPreviewing(with: self, sourceView: theTableView)
        
        getMapSnapshot()
        resetStateOfEditButtons()
        
        initSearchController()
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NotificationCenter.default.addObserver(self, selector: #selector(POIsViewController.contextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(POIsViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(POIsViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(POIsViewController.synchronizationContactsDone(_:)), name: Notification.Name(rawValue: ContactsSynchronization.Notifications.synchronizationDone), object: ContactsSynchronization.sharedInstance)
   }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: notification
    func synchronizationContactsDone(_ notification : Notification) {
        pois = nil // Reset the data
        poisWithFilters = nil
        theTableView.reloadData()
        resetStateOfEditButtons()
    }
    
    func contextDidSaveNotification(_ notification : Notification) {
        
        if ContactsSynchronization.sharedInstance.isSynchronizing {
            return // ignore the notification while Contacts are synchronizing
        }

        pois = nil // Reset the data
        poisWithFilters = nil
        // If the table is editing it means we are deleting the Poi directly from
        // this controller
        // If it's not editing it means the PoiGroup has been changed from another controller
        if !theTableView.isEditing {
            theTableView.reloadData()
        }
        
        resetStateOfEditButtons()
        
        getMapSnapshot()
    }

    
    //MARK: Utils
    fileprivate func getPois(withFilter:Bool) -> [PointOfInterest] {
        if !withFilter {
            if pois == nil {
                pois = extractPOIsFromDatabase(withFilter:false)
            }
            return pois!
        } else {
            if poisWithFilters == nil {
                poisWithFilters = extractPOIsFromDatabase(withFilter:true)
            }
            return poisWithFilters!
        }
    }
    
    fileprivate func extractPOIsFromDatabase(withFilter:Bool) -> [PointOfInterest] {
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
        case .poisWithoutAddress:
            return POIDataManager.sharedInstance.getPoisWithoutPlacemark(searchFilter: filter)
        }
    }
    
    
    /// Enable or disable buttons from toolbars based on list of POIs
    fileprivate func resetStateOfEditButtons() {
        if ContactsSynchronization.sharedInstance.isSynchronizing {
            actionButton.isEnabled = false
            moveButton.isEnabled = false
            searchButton.isEnabled = false
            selectButton.isEnabled = false
            return
        }
        // set all button to enable by default
        actionButton.isEnabled = true
        selectButton.isEnabled = true
        moveButton.isEnabled = true
        searchButton.isEnabled = true

        // disable all except the search if there're POI when the filter is empty
        if getPois(withFilter:true).count == 0 {
            actionButton.isEnabled = false
            selectButton.isEnabled = false
            moveButton.isEnabled = false
            
            // search button must be disabled only if there's nothing even
            // when the filter is not set
            if getPois(withFilter:false).count == 0 {
                searchButton.isEnabled = false
            }
        } else {
            // When the table is in editing mode all buttons must be 
            // enabled except the action and the move when no rows have been
            // selected
            if theTableView.isEditing {
                searchButton.isEnabled = false
                actionButton.isEnabled = false
                if theTableView.indexPathForSelectedRow == nil {
                    moveButton.isEnabled = false
                }
            }
        }
    }
    
    fileprivate func startEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = true
        theTableView.setEditing(true, animated: true)
        moveButton.isEnabled = false
        selectButton.title = NSLocalizedString("MoveDoneButtonTitle", comment: "")
        moveButton.title = NSLocalizedString("MoveSelectedPOIsButtonTitle", comment: "")
        resetStateOfEditButtons()
    }
    
    fileprivate func stopEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = false
        theTableView.setEditing(false, animated: true)
        moveButton.title = NSLocalizedString("MoveAllPOIsButtonTitle", comment: "")
        selectButton.title = NSLocalizedString("MoveSelectButtonTitle", comment: "")
        resetStateOfEditButtons()
    }

    // Display all POIs without any filter in the Map
    fileprivate func getMapSnapshot() {
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MapUtils.boundingBoxForAnnotations(getPois(withFilter:false))
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .standard ? .standard : .satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSize(width: view.bounds.width, height: Cste.MapViewHeight)
        snapshotOptions.scale = 2.0
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter!.start(completionHandler: { mapSnapshot, error in
            if let error = error {
                NSLog("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                if let theMapSnapshot = mapSnapshot {
                    self.snapshotImage = MapUtils.configureMapImageFor(pois:self.getPois(withFilter:false),
                                                                       mapSnapshot:theMapSnapshot,
                                                                       poiSizeInMap:Cste.POISizeInMapView)
                    self.theTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                }
            }
        })
    }
    

    // MARK: Action buttons
    @IBAction func actionButtonPushed(_ sender: UIBarButtonItem) {
        var activityItems = [UIActivityItemSource]()
        let mailActivity = PoisMailActivityItemSource(pois:getPois(withFilter:true), mailTitle:areaName)
        activityItems.append(mailActivity)
        
        if UserPreferences.sharedInstance.isAnyPoiUnlimited {
            activityItems.append(GPXActivityItemSource(pois: getPois(withFilter:true)))
        }
        
        if let snapshot = snapshotter, !snapshot.isLoading {
            let imageActivity = ImageAcvitityItemSource(image: snapshotImage!)
            activityItems.append(imageActivity)
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                    UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                    UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                    UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo, UIActivityType.message]
        
        present(activityController, animated: true, completion: nil)
    }

    @IBAction func searchButtonPushed(_ sender: UIBarButtonItem) {
        if searchController.isActive {
            searchController.searchBar.isHidden = false
            searchController.searchBar.becomeFirstResponder()
        } else {
            present(searchController, animated: true, completion: nil)
        }
    }

    @IBAction func showPOIOnMap(_ sender: UIButton) {
        let selectedPoi = getPoiForIndexPath(IndexPath(row: sender.tag, section: 0))
        NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showPOI), object: nil, userInfo: [MapViewController.MapNotifications.showPOI_Parameter_POI: selectedPoi])
        
        ContainerViewController.sharedInstance.goToMap()
    }
    
    @IBAction func selectButtonPushed(_ sender: UIBarButtonItem) {
        // Start or end the editing mode
        theTableView.isEditing ? stopEditingMode() : startEditingMode()
    }
    
    
    @IBAction func movePOIs(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showMovePOISId", sender: nil)
    }

    //MARK: Keyboard Mgt
    var contentInsetBeforeDisplayedKeyboard = UIEdgeInsets.zero
    
    func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            var contentInsets:UIEdgeInsets
            if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            } else {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.width, 0.0)
            }
            
            contentInsetBeforeDisplayedKeyboard = theTableView.contentInset
            theTableView.contentInset = contentInsets
            theTableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    
    func keyboardWillHide(_ notification:Notification) {
        theTableView.contentInset = contentInsetBeforeDisplayedKeyboard
        theTableView.scrollIndicatorInsets = contentInsetBeforeDisplayedKeyboard
    }
    
    
    // MARK: Segue
    fileprivate struct storyboard {
        static let showPOIDetails = "ShowPOIDetailsIdFromPoisList"
        static let showMovePOISId = "showMovePOISId"
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // remove the search controller when moving to another view controller
        searchController.isActive = false

        if segue.identifier == storyboard.showPOIDetails {
            let poiController = segue.destination as! POIDetailsViewController
            let currentPOI = getPoiForIndexPath(sender as! IndexPath)
            poiController.poi = currentPOI
        } else if segue.identifier == storyboard.showMovePOISId {
            let movePOIsController = segue.destination as! MovePOIsViewController
            if theTableView.isEditing, let indexPaths = theTableView.indexPathsForSelectedRows {
                var selectedPois = [PointOfInterest]()
                for currentIndex in indexPaths {
                    selectedPois.append(getPoiForIndexPath(currentIndex))
                }
                movePOIsController.pois = selectedPois
                stopEditingMode()
            } else {
                movePOIsController.pois = getPois(withFilter:true)
            }
        }
    }
}

extension POIsViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.show(viewControllerToCommit, sender: nil)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if let indexPath = theTableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = theTableView.rectForRow(at: indexPath)
            let viewController = UIStoryboard.init(name: "POIManager", bundle: nil).instantiateViewController(withIdentifier: "POIDetails") as! POIDetailsViewController
            viewController.poi = getPoiForIndexPath(indexPath)
            return viewController
            
        } else {
            return nil
        }
    }
    
}

extension POIsViewController : UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    //MARK: Search Controller
    fileprivate func initSearchController() {
        // Open the search controller on itself
        searchController = UISearchController(searchResultsController: nil)
        
        // Configure the UISearchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("POIsSearchBarPlaceholder", comment: "")
        searchController.obscuresBackgroundDuringPresentation = false // Mandatory when opening the search controller on itself
        // Don't hide the navigation bar, it will be just covered by the SearchController (it will avoid the tableview to slide below
        // the searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
    }

    //MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // To be completed
    }
    
    //MARK: UISearchControllerDelegate
     func didDismissSearchController(_ searchController: UISearchController) {
        clearFilter()
    }

    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        poisWithFilters = nil
        resetStateOfEditButtons()
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.text = searchFilter
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearFilter()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchButton.tintColor = UIColor.red
        searchBar.isHidden = true
    }

    fileprivate func clearFilter() {
        searchButton.tintColor = actionButton.tintColor
        if !searchFilter.isEmpty {
            searchFilter = ""
            poisWithFilters = nil
            searchController.searchBar.text = ""
            resetStateOfEditButtons()
            theTableView.reloadData()
        }
    }

}
extension POIsViewController : UITableViewDataSource, UITableViewDelegate {
    
    struct Sections {
        static let MapView = 0
        static let POIs = 1
    }

    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.POIs {
            let poisCount = getPois(withFilter:true).count
            return poisCount == 0 ? 1 : poisCount
        } else {
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    fileprivate struct cellIdentifier {
        static let descriptionCellId = "POISimpleCellId"
        static let cellForEmptyGroupId = "cellForEmptyGroupId"
        static let cellPoisMapAreaId = "cellPoisMapAreaId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.MapView {
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellPoisMapAreaId, for: indexPath) as! PoisMapAreaTableViewCell
            if let theSnapshotter = snapshotter , !theSnapshotter.isLoading {
                let imageView = UIImageView(image: snapshotImage)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.6
                theCell.backgroundView = imageView
            }
            
            theCell.groupLabel?.text = areaName
            return theCell
        } else {
            if getPois(withFilter:true).count > 0 {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.descriptionCellId, for: indexPath) as! POISimpleViewCell
                let currentPOI = getPoiForIndexPath(indexPath)
                
                if let image = images[indexPath.row] {
                    theCell.initializeWith(currentPOI, index:indexPath.row, image:image)
                } else {
                    theCell.initializeWith(currentPOI, index:indexPath.row)
                }
                return theCell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellForEmptyGroupId, for: indexPath)
                if getPois(withFilter:false).count > 0 {
                    cell.textLabel?.text = "\(NSLocalizedString("POIsNoPOIsMatchingSearch", comment: "")) \(searchFilter)"
                    cell.textLabel?.textColor = UIColor.green
                } else {
                    cell.textLabel?.text = NSLocalizedString("POIsNoPOIsInGoup", comment: "")
                    cell.textLabel?.textColor = UIColor.red
                }
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Sections.MapView {
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Sections.MapView {
            if let theSnapshotter = snapshotter , !theSnapshotter.isLoading {
                return Cste.MapViewHeight
            } else {
                return 0
            }
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            switch editingStyle {
            case .delete:
                
                theTableView.beginUpdates()
                let thePoiToDelete = getPoiForIndexPath(indexPath)
                POIDataManager.sharedInstance.deletePOI(POI: thePoiToDelete)
                POIDataManager.sharedInstance.commitDatabase()
                theTableView.deleteRows(at: [indexPath], with: .automatic)
                if getPois(withFilter:true).count == 0 {
                    theTableView.insertRows(at: [indexPath], with: .automatic)
                }
                theTableView.endUpdates()
            default: break
                // just ignore, manage only deletion
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if ContactsSynchronization.sharedInstance.isSynchronizing {
            return false
        }

        if indexPath.section == Sections.MapView {
            return false
        } else if indexPath.section == Sections.POIs && getPois(withFilter:true).count == 0 {
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            if getPois(withFilter:true).count > 0 && !theTableView.isEditing {
                performSegue(withIdentifier: storyboard.showPOIDetails, sender: indexPath)
            } else if theTableView.isEditing {
                moveButton.isEnabled = true
            }
        } else if indexPath.section == Sections.MapView {
            let pois = getPois(withFilter:false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showPOIs), object: nil, userInfo: [MapViewController.MapNotifications.showPOIs_Parameter_POIs: pois])
            
            ContainerViewController.sharedInstance.goToMap()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            if theTableView.isEditing && theTableView.indexPathsForSelectedRows == nil {
                moveButton.isEnabled = false
            }
        }
    }
}
