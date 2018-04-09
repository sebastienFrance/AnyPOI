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
    
     var datasource:POIsDataSource!
    
    // Search
    fileprivate var searchController:UISearchController!

    // Map image
    fileprivate var snapshotter:MKMapSnapshotter?
    fileprivate var snapshotImage:UIImage?
    
    fileprivate struct Cste {
        static let MapViewHeight = CGFloat(170.0)
        static let POISizeInMapView = CGFloat(10.0)
    }

    
    
    //MARK: Initialization
     override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForPreviewing(with: self, sourceView: theTableView)
        
        getMapSnapshot()
        resetStateOfEditButtons()
        
        initSearchController()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsViewController.refreshDisplay(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: DatabaseAccess.sharedInstance.managedObjectContext)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsViewController.refreshDisplay(_:)),
                                               name: Notification.Name(rawValue: ContactsSynchronization.Notifications.synchronizationDone),
                                               object: ContactsSynchronization.sharedInstance)
   }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if let theSnapshotter = snapshotter, theSnapshotter.isLoading {
            theSnapshotter.cancel()
        }
        
        snapshotter = nil
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // When this view controller has disappear we must be sure the
        // searchController is no more displayed (for example when Navigating to the Map and the SearchController is displayed
        // or when selecting a POIs to distplay its details and the SearchController is also displayed
        searchController.isActive = false
        unregisterKeyboardNotifications()
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: notification

    
    /// Refresh the content of the view when the contacts synchronization is completed or when
    /// something has been changed in the database
    ///
    /// It refreshes:
    ///  - content of the table view
    ///  - reset the datasource (to update it with the new content of the database)
    ///  - status of the toolbar buttons
    ///  - update the map snapshot to reflect the new content of the database
    ///
    /// - Parameter notification: notification
    @objc private func refreshDisplay(_ notification : Notification) {
        if ContactsSynchronization.sharedInstance.isSynchronizing {
            return // ignore the notification while Contacts are synchronizing
        }
        
        datasource.reset()
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
    
    
    /// Get a Filtered POI at the given indexPath
    ///
    /// - Parameter indexPath: index of the POI
    /// - Returns: PointOfInterest at the given index
    fileprivate func getFilteredPOI(_ indexPath:IndexPath) -> PointOfInterest {
        return datasource.filteredPOIs[indexPath.row]
    }

    /// Reconfigure the status of all buttons from the ViewController
    /// - When the Contacts are synchronizing, all buttons (search, filter...) are disabled
    
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
        if datasource.filteredPOIsCount == 0 {
            actionButton.isEnabled = false
            selectButton.isEnabled = false
            moveButton.isEnabled = false
            
            // search button must be disabled only if there's nothing even
            // when the filter is not set
            if datasource.allPOIsCount == 0 {
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
    
    
    /// Set the TableView in editing mode
    fileprivate func startEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = true
        theTableView.setEditing(true, animated: true)
        moveButton.isEnabled = false
        selectButton.title = NSLocalizedString("MoveDoneButtonTitle", comment: "")
        moveButton.title = NSLocalizedString("MoveSelectedPOIsButtonTitle", comment: "")
        resetStateOfEditButtons()
    }
    
    
    /// Stop the TableView editing mode
    fileprivate func stopEditingMode() {
        theTableView.allowsMultipleSelectionDuringEditing = false
        theTableView.setEditing(false, animated: true)
        moveButton.title = NSLocalizedString("MoveAllPOIsButtonTitle", comment: "")
        selectButton.title = NSLocalizedString("MoveSelectButtonTitle", comment: "")
        resetStateOfEditButtons()
    }

    /// Show all POIs without filter in the Map
    fileprivate func getMapSnapshot() {
        if let theSnapshotter = snapshotter, theSnapshotter.isLoading {
            theSnapshotter.cancel()
        }
        
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MapUtils.boundingBoxForAnnotations(datasource.allPOIs)
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
                // Get the image and update the cell displaying the map
                if let theMapSnapshot = mapSnapshot {
                    self.snapshotImage = MapUtils.configureMapImageFor(pois:self.datasource.allPOIs,
                                                                       mapSnapshot:theMapSnapshot,
                                                                       poiSizeInMap:Cste.POISizeInMapView)
                    self.theTableView.reloadSections(IndexSet(integer: 0), with: .fade)
                }
            }
        })
    }
    

    // MARK: Action buttons
    @IBAction func actionButtonPushed(_ sender: UIBarButtonItem) {
        var activityItems = [UIActivityItemSource]()
        let mailActivity = PoisMailActivityItemSource(pois:datasource.filteredPOIs, mailTitle:datasource.poisDescription)
        activityItems.append(mailActivity)
        
        activityItems.append(GPXActivityItemSource(pois: datasource.filteredPOIs))
        
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
            // It happens when the searchController was already opened and the user has
            // clicked on the "Search" button of the Keyboard.
            // The searchController in that case is still displayed but just hidden
            // so we must just update the searchBar to display and to show the keyboard again
            // when the user has touched again on the search button
            searchController.searchBar.isHidden = false
            searchController.searchBar.becomeFirstResponder()
        } else {
            present(searchController, animated: true, completion: nil)
        }
    }

    
    /// Button used to enter/exit the mode to select POIs that must be moved
    /// to another Group
    ///
    /// - Parameter sender: bar button
    @IBAction func selectButtonPushed(_ sender: UIBarButtonItem) {
        // Start or end the editing mode
        theTableView.isEditing ? stopEditingMode() : startEditingMode()
    }
    
    
    @IBAction func movePOIs(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showMovePOISId", sender: nil)
    }

    //MARK: Keyboard Mgt
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsViewController.keyboardWillShow(_:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsViewController.keyboardWillHide(_:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }

    @objc func keyboardWillShow(_ notification:Notification) {
        // Extract the Keyboard size
        
        let info = notification.userInfo! as NSDictionary
        let valueHeight = info.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardForHeight = valueHeight.cgRectValue.size
        
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardForHeight.height, 0.0)
        theTableView.contentInset = contentInsets
        theTableView.scrollIndicatorInsets = contentInsets
    }
    
    
    @objc func keyboardWillHide(_ notification:Notification) {
        theTableView.contentInset = .zero
        theTableView.scrollIndicatorInsets = .zero
   }
    
    
    // MARK: Segue
    fileprivate struct storyboard {
        static let showPOIDetails = "ShowPOIDetailsIdFromPoisList"
        static let showMovePOISId = "showMovePOISId"
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier {
            switch segueId {
            case POIsViewController.storyboard.showPOIDetails:
                let poiController = segue.destination as! POIDetailsViewController
                poiController.poi = getFilteredPOI(sender as! IndexPath)
            case POIsViewController.storyboard.showMovePOISId :
                let movePOIsController = segue.destination as! MovePOIsViewController
                if theTableView.isEditing, let indexPaths = theTableView.indexPathsForSelectedRows {
                    movePOIsController.pois = indexPaths.map() {
                        return getFilteredPOI($0)
                    }
                    stopEditingMode()
                } else {
                    movePOIsController.pois = datasource.filteredPOIs
                }
            default:
                break
            }
        }
    }
}

// Add preview of POI details on 3D Touch
extension POIsViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.show(viewControllerToCommit, sender: nil)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if let indexPath = theTableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = theTableView.rectForRow(at: indexPath)
            let viewController = UIStoryboard.init(name: "POIManager", bundle: nil).instantiateViewController(withIdentifier: "POIDetails") as! POIDetailsViewController
            viewController.poi = getFilteredPOI(indexPath)
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
        datasource.update(filter:searchText)
        resetStateOfEditButtons()
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.text = datasource.searchFilter
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearFilter()
    }
    
    
    /// When the user has touched the "Search" button of the Keyboard
    /// we just hide the searchController but it's not closed !
    ///
    /// - Parameter searchBar: search bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchButton.tintColor = UIColor.red
        searchBar.isHidden = true
    }

    fileprivate func clearFilter() {
        searchButton.tintColor = actionButton.tintColor
        if !datasource.searchFilter.isEmpty {
            datasource.update(filter:"")
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
            let poisCount = datasource.filteredPOIsCount
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs, datasource.filteredPOIsCount > 0 {
            let theCell = cell as! POISimpleViewCell
            theCell.configureMarker(poi:getFilteredPOI(indexPath))
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.MapView:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellPoisMapAreaId, for: indexPath) as! PoisMapAreaTableViewCell
            if let theSnapshotter = snapshotter , !theSnapshotter.isLoading {
                let imageView = UIImageView(image: snapshotImage)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.6
                theCell.backgroundView = imageView
            }
            
            theCell.groupLabel?.text = datasource.poisDescription
            return theCell
        case Sections.POIs:
            if datasource.filteredPOIsCount > 0 {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.descriptionCellId, for: indexPath) as! POISimpleViewCell
                let currentPOI = getFilteredPOI(indexPath)
                theCell.initializeWith(currentPOI, index:indexPath.row)
                return theCell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellForEmptyGroupId, for: indexPath)
                if datasource.allPOIsCount > 0 {
                    cell.textLabel?.text = "\(NSLocalizedString("POIsNoPOIsMatchingSearch", comment: "")) \(datasource.searchFilter)"
                    cell.textLabel?.textColor = UIColor.green
                } else {
                    cell.textLabel?.text = NSLocalizedString("POIsNoPOIsInGoup", comment: "")
                    cell.textLabel?.textColor = UIColor.red
                }
                return cell
            }
        default:
            return UITableViewCell()
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
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            switch editingStyle {
            case .delete:
                
                theTableView.beginUpdates()
                let thePoiToDelete = getFilteredPOI(indexPath)
                POIDataManager.sharedInstance.deletePOI(POI: thePoiToDelete)
                POIDataManager.sharedInstance.commitDatabase()
                theTableView.deleteRows(at: [indexPath], with: .automatic)
                if datasource.filteredPOIsCount == 0 {
                    theTableView.insertRows(at: [indexPath], with: .automatic)
                }
                theTableView.endUpdates()
            default: break
                // just ignore, manage only deletion
                
            }
        }
    }
    
    
    /// When the editing mode end we must make sure all buttons are refreshed correctly
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index of row
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if indexPath?.section == Sections.POIs {
            resetStateOfEditButtons()
        }
    }
    
    
    /// Rows cannot be deleted while the Contact synchronization in on going
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index of the row
    /// - Returns: true when the row can be deleted
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if ContactsSynchronization.sharedInstance.isSynchronizing {
            return false
        }

        if indexPath.section == Sections.MapView {
            return false
        } else if indexPath.section == Sections.POIs && datasource.filteredPOIsCount == 0 {
            return false
        } else {
            return true
        }
    }
    
    
    /// When the Map has been selected we display the MapView with the list of POIs
    /// When a POIs has been selected we show the ViewController to display the POI details
    /// When we are in editing mode and a POI has been selected the Move Button is enabled
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            if datasource.filteredPOIsCount > 0 && !theTableView.isEditing {
                performSegue(withIdentifier: POIsViewController.storyboard.showPOIDetails, sender: indexPath)
            } else if theTableView.isEditing {
                moveButton.isEnabled = true
            }
        } else if indexPath.section == Sections.MapView {
            let pois = datasource.allPOIs
            NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showPOIs),
                                            object: nil,
                                            userInfo: [MapViewController.MapNotifications.showPOIs_Parameter_POIs: pois])
            
            MainTabBarViewController.instance?.showMap()
        }
    }
    
    
    /// When a row is deselected and we are in editing mode and there're no more selected rows
    /// then we disabled the Move button
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.POIs {
            if theTableView.isEditing && theTableView.indexPathsForSelectedRows == nil {
                moveButton.isEnabled = false
            }
        }
    }
}
