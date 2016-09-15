//
//  POIsGroupList.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import CoreLocation
import PKHUD


class POIsGroupListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DismissModalViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, ContainerViewControllerDelegate {

    
    @IBOutlet private weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 110
                theTableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?
    // Fix sections, next there's one dynamic section per country
    private struct SectionIndex {
        static let poiGroups = 0
        static let monitoredPois = 1
        static let count = 2
    }

    private var searchController:UISearchController!
    private var searchFilter = "" // Use to perform filtering on list of groups
    private var filteredGroups:[GroupOfInterest]!

    
    @objc private func menuButtonPushed(button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }
    
    //MARK: Initializations
    override func viewDidLoad() {
        super.viewDidLoad()

        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .Plain, target: self, action: #selector(POIsGroupListViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.contextDidSaveNotification(_:)),
                                                         name: NSManagedObjectContextDidSaveNotification,
                                                         object: managedContext)

        // Subscribe Keyboard notifications because when the keyboard is displayed we need to change the tableview insets
        // to make sure all rows of the table view can be correctly displayed (if not, then the latests rows are not visible)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.keyboardWillShow(_:)),
                                                         name: UIKeyboardWillShowNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.keyboardWillHide(_:)),
                                                         name: UIKeyboardWillHideNotification,
                                                         object: nil)

       initSearchController()
    }

    // Add a searchBar on top of the Navigation bar
    private func initSearchController() {
        // Open the search controller on itself
        searchController = UISearchController(searchResultsController: nil)
        
        // Configure the UISearchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Group name"
        searchController.obscuresBackgroundDuringPresentation = false // Mandatory when opening the search controller on itself
        // Don't hide the navigation bar, it will be just covered by the SearchController (it will avoid the tableview to slide below
        // the searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true

        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        if isMovingFromParentViewController() {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
     }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove the search controller when moving to another view controller
        if searchController.active {
            searchController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    //MARK: Notifications
    func contextDidSaveNotification(notification : NSNotification) {
        let notifContent = PoiNotificationUserInfo(userInfo: notification.userInfo)
        
        // A Group has been added or changed, we must reload the table content
        // A POI has been added/deleted/updated we must reload the table content (one use case is to add create a new POI with monitored atttributes 
        // and it's the first one with it => we must add "Monitored POIs" as section in the table
        if notifContent.insertedGroupOfInterest.count > 0 || notifContent.updatedGroupOfInterest.count > 0 ||
            notifContent.deletedPois.count > 0 || notifContent.updatedPois.count > 0 || notifContent.insertedPois.count > 0 {
            filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
            theTableView.reloadData()
        }
    }

    //MARK: Keyboard Mgt
    var contentInsetBeforeDisplayedKeyboard = UIEdgeInsetsZero

    // when the keyboard is displayed, we change the insets values of the tableView to take into account the size of 
    // the keyboard (width or height depending on orientation)
    func keyboardWillShow(notification:NSNotification) {
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var contentInsets:UIEdgeInsets
            if UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            } else {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top + 15, 0.0, keyboardSize.height, 0.0)
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
    
    //MARK: Action buttons
    @IBAction func groupSwitchPushed(sender: UISwitch) {
        let POIGroup = filteredGroups[sender.tag]
        POIGroup.isGroupDisplayed = sender.on
        
        // It will add/remove annotations from the Map, it can takes some times... so to no block
        // user we do it asynchronously
        dispatch_async(dispatch_get_main_queue()) {
            POIDataManager.sharedInstance.updatePOIGroup(POIGroup)
            POIDataManager.sharedInstance.commitDatabase()
        }
    }
    
    @IBAction func groupModifyPushed(sender: UIButton) {
        performSegueWithIdentifier(storyboard.updateGroupOfInterest, sender: filteredGroups[sender.tag])
    }
    
    @IBAction func searchButtonPushed(sender: UIBarButtonItem) {
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    //MARK: DismissModalViewController
    func didDismiss() {
        stopDim()
    }

    //MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        // To be completed
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(searchController: UISearchController) {
        // to be completed -> nothing to do if we keep the filter!
        theTableView.reloadData()
    }
    
    
    //MARK: UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.text = searchFilter
    }
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 2 fix sections (POI Groups + Monitored POIs) + dynamic sections per Country
        return SectionIndex.count + POIDataManager.sharedInstance.getAllCountriesOrderedByName().count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionIndex.poiGroups {
            return filteredGroups.count
        } else if section == SectionIndex.monitoredPois {
            if searchFilter.isEmpty {
                return POIDataManager.sharedInstance.getAllMonitoredPOI().count > 0 ? 1 : 0
            } else {
                return 0
            }
        } else {
            let sectionIndex = getCountrySectionIndexFrom(section)
            let countries = POIDataManager.sharedInstance.getAllCountriesOrderedByName()
            if sectionIndex < countries.count {
                let citiesForSection = POIDataManager.sharedInstance.getAllCitiesFromCountry(countries[sectionIndex].ISOCountryCode, filter: searchFilter)
                if searchFilter.isEmpty {
                    return citiesForSection.count > 0 ? citiesForSection.count + 1 : 0
                } else {
                    return citiesForSection.count > 0 ? citiesForSection.count : 0                    
                }
            } else {
                print("\(#function) Warning, cannot find cities for index \(section)")
                return 0
            }
        }
     }
    
    // Index of Country is the number of section minus the number of fix sections
    private func getCountrySectionIndexFrom(section:Int) -> Int {
        return section - SectionIndex.count
    }
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // If the section has no data, we don't display at all
        if self.tableView(theTableView, numberOfRowsInSection: section) == 0 {
            return nil
        }
        
        switch (section) {
        case SectionIndex.poiGroups:
            return "User group"
        case SectionIndex.monitoredPois:
            return "Monitored"
        default:
            return getCountryName(section)
        }
    }
    
    private func getCountryForIndex(section:Int) -> POIDataManager.CountryDescription? {
        let countryIndex = getCountrySectionIndexFrom(section)
        let countries = POIDataManager.sharedInstance.getAllCountriesOrderedByName()
        if countryIndex < countries.count {
            return countries[countryIndex]
        } else {
            return nil
        }
    }
    
    private func getCityNameFromCountry(country:POIDataManager.CountryDescription, row:Int) -> String {
        let cities = POIDataManager.sharedInstance.getAllCitiesFromCountry(country.ISOCountryCode, filter: searchFilter)
        if (row - 1) < cities.count {
            return searchFilter.isEmpty ? cities[row - 1] : cities[row]
        } else {
            return "unknown city"
        }
    }

    private func getCityNameForIndex(indexPath:NSIndexPath) -> String {
        if let country = getCountryForIndex(indexPath.section) {
            return getCityNameFromCountry(country, row: indexPath.row)
        } else {
            return "unknown country"
        }
    }
    
    
    private func getCountryName(section:Int) -> String {
        return getCountryForIndex(section)?.countryName ?? "Unknown country"
    }
    
    private struct cellIdentifier {
        static let POIGroupListCellId = "POIGroupListCellId"
        static let MonitoredPoisGroupCellId = "MonitoredPoisGroupCellId"
        static let CityGroupCell = "CityGroupCellId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch (indexPath.section) {
        case SectionIndex.poiGroups:
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.POIGroupListCellId, forIndexPath: indexPath) as! POIGroupCell
            
            // build and array with the GroupOdPointOfInterest and extract the value at the index
            theCell.initWithGroup(filteredGroups[indexPath.row], index:indexPath.row)
            
            return theCell
        case SectionIndex.monitoredPois:
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.MonitoredPoisGroupCellId, forIndexPath: indexPath) as! MonitoredPoisGroupCell
            return theCell
        default:
            return getCountryOrCityTableViewCell(tableView, indexPath: indexPath)
        }
    }
    
    private func getCountryOrCityTableViewCell(tableView: UITableView, indexPath:NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 && searchFilter.isEmpty {
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.CityGroupCell, forIndexPath: indexPath) as! CityGroupCell
            theCell.cityNameLabel.text  = "All"
            return theCell
        } else {
            let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.CityGroupCell, forIndexPath: indexPath) as! CityGroupCell
            theCell.cityNameLabel.text = getCityNameForIndex(indexPath)
            return theCell
        }
    }

    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == SectionIndex.poiGroups {
            return !POIDataManager.sharedInstance.isMandatoryGroup(filteredGroups[indexPath.row])
        } else {
            return true
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            switch indexPath.section {
            case SectionIndex.poiGroups:
                deletePoiGroup(indexPath)
            case SectionIndex.monitoredPois:
                deleteMonitoredPois(indexPath)
            default:
                deleteRowFromCountriesAndCities(indexPath)
            }
        default:
            break
        }
    }
    
    private func deletePoiGroup(indexPath:NSIndexPath) {
        theTableView.beginUpdates()
        POIDataManager.sharedInstance.deleteGroup(group:filteredGroups[indexPath.row])
        POIDataManager.sharedInstance.commitDatabase()
        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        theTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        theTableView.endUpdates()
    }
    
    private func deleteMonitoredPois(indexPath:NSIndexPath) {
        theTableView.beginUpdates()
        POIDataManager.sharedInstance.deleteMonitoredPOIs()
        POIDataManager.sharedInstance.commitDatabase()
        theTableView.deleteSections(NSIndexSet(index:indexPath.section), withRowAnimation: .Fade)
        theTableView.endUpdates()
    }
    
    private func deleteRowFromCountriesAndCities(indexPath:NSIndexPath) {
        if let country = getCountryForIndex(indexPath.section) {
         let isoCountryCode = country.ISOCountryCode
            if indexPath.row == 0 && searchFilter.isEmpty {
                theTableView.beginUpdates()
                POIDataManager.sharedInstance.deleteCountryPOIs(isoCountryCode)
                POIDataManager.sharedInstance.commitDatabase()
                
                theTableView.deleteSections(NSIndexSet(index:indexPath.section), withRowAnimation: .Fade)
                theTableView.endUpdates()
            } else {
                let cities = POIDataManager.sharedInstance.getAllCitiesFromCountry(isoCountryCode, filter: searchFilter)
                if (indexPath.row - 1) < cities.count {
                    theTableView.beginUpdates()
                    POIDataManager.sharedInstance.deleteCityPOIs(searchFilter.isEmpty ? cities[indexPath.row - 1] : cities[indexPath.row], fromISOCountryCode:isoCountryCode)
                    POIDataManager.sharedInstance.commitDatabase()
                    if (cities.count == 1 && searchFilter.isEmpty) || (cities.count == 0 && !searchFilter.isEmpty) {
                        theTableView.deleteSections(NSIndexSet(index:indexPath.section), withRowAnimation: .Fade)
                    } else {
                        theTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                    
                    theTableView.endUpdates()
                } else {
                    print("\(#function) Warning, invalid index to look for a City : \(indexPath.row - 1)")
                }
            }
        } else {
            print("\(#function) Warning, invalid index to look for a Country \(indexPath.section)")
        }
    }
    
    //MARK: Segues
    private struct storyboard {
        static let showPOIList = "showPOIList"
        static let updateGroupOfInterest = "updateGroupOfInterest"
        static let showMonitoredPois = "showMonitoredPois"
        static let showCityPois = "showCityPois"
        static let openGroupConfiguratorId = "openGroupConfiguratorId"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case storyboard.showPOIList:
            let poiController = segue.destinationViewController as! POIsViewController
            let group = filteredGroups[theTableView.indexPathForSelectedRow!.row]
            poiController.showGroup(group)
        case storyboard.showMonitoredPois:
            let poiController = segue.destinationViewController as! POIsViewController
            poiController.showMonitoredPois()
        case storyboard.showCityPois:
            if let indexPath = theTableView.indexPathForSelectedRow {
                let poiController = segue.destinationViewController as! POIsViewController
                showCountriesOrCitiesFor(indexPath, viewController: poiController)
            }
        case storyboard.updateGroupOfInterest:
            startDim()
            let viewController = segue.destinationViewController as! GroupConfiguratorViewController
            viewController.delegate = self
            viewController.group = sender as? GroupOfInterest
        case storyboard.openGroupConfiguratorId:
            startDim()
            let viewController = segue.destinationViewController as! GroupConfiguratorViewController
            viewController.delegate = self
        default:
            print("\(#function) Error, unknown identifier")
        }
    }
    
    
    
    private func showCountriesOrCitiesFor(indexPath:NSIndexPath, viewController: POIsViewController) {
        if let country = getCountryForIndex(indexPath.section) {
            if indexPath.row == 0 && searchFilter.isEmpty {
                viewController.showCountryPoi(country.ISOCountryCode, name:country.countryName)
            } else {
                viewController.showCityPoi(getCityNameFromCountry(country, row: indexPath.row))
            }
        } else {
            print("\(#function) Warning, invalid index to look for a Country \(indexPath.row)")
        }
    }
}
