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

    
    @IBOutlet fileprivate weak var theTableView: UITableView! {
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
    fileprivate struct SectionIndex {
        static let poiGroups = 0
        static let monitoredPois = 1
        static let count = 2
    }

    fileprivate var searchController:UISearchController!
    fileprivate var searchFilter = "" // Use to perform filtering on list of groups
    fileprivate var filteredGroups:[GroupOfInterest]!

    
    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }
    
    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            theTableView.isUserInteractionEnabled = enable
        }
    }

    
    //MARK: Initializations
    override func viewDidLoad() {
        super.viewDidLoad()

        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .plain, target: self, action: #selector(POIsGroupListViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.contextDidSaveNotification(_:)),
                                                         name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                         object: managedContext)

        // Subscribe Keyboard notifications because when the keyboard is displayed we need to change the tableview insets
        // to make sure all rows of the table view can be correctly displayed (if not, then the latests rows are not visible)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.keyboardWillShow(_:)),
                                                         name: NSNotification.Name.UIKeyboardWillShow,
                                                         object: nil)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(POIsGroupListViewController.keyboardWillHide(_:)),
                                                         name: NSNotification.Name.UIKeyboardWillHide,
                                                         object: nil)

       initSearchController()
    }

    // Add a searchBar on top of the Navigation bar
    fileprivate func initSearchController() {
        // Open the search controller on itself
        searchController = UISearchController(searchResultsController: nil)
        
        // Configure the UISearchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("GroupNamePlaceHolderSearchBar", comment: "")
        searchController.obscuresBackgroundDuringPresentation = false // Mandatory when opening the search controller on itself
        // Don't hide the navigation bar, it will be just covered by the SearchController (it will avoid the tableview to slide below
        // the searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true

        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        if isMovingFromParentViewController {
            NotificationCenter.default.removeObserver(self)
        }
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove the search controller when moving to another view controller
        if searchController.isActive {
            searchController.dismiss(animated: false, completion: nil)
        }
    }
    
    //MARK: Notifications
    func contextDidSaveNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        
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
    var contentInsetBeforeDisplayedKeyboard = UIEdgeInsets.zero

    // when the keyboard is displayed, we change the insets values of the tableView to take into account the size of 
    // the keyboard (width or height depending on orientation)
    func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            var contentInsets:UIEdgeInsets
            if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            } else {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top + 15, 0.0, keyboardSize.height, 0.0)
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
    
    //MARK: Action buttons
    @IBAction func groupSwitchPushed(_ sender: UISwitch) {
        let POIGroup = filteredGroups[sender.tag]
        POIGroup.isGroupDisplayed = sender.isOn
        
        // It will add/remove annotations from the Map, it can takes some times... so to no block
        // user we do it asynchronously
        DispatchQueue.main.async {
            POIDataManager.sharedInstance.updatePOIGroup(POIGroup)
            POIDataManager.sharedInstance.commitDatabase()
        }
    }
    
    @IBAction func groupModifyPushed(_ sender: UIButton) {
        performSegue(withIdentifier: storyboard.updateGroupOfInterest, sender: filteredGroups[sender.tag])
    }
    
    @IBAction func searchButtonPushed(_ sender: UIBarButtonItem) {
        present(searchController, animated: true, completion: nil)
    }
    
    //MARK: DismissModalViewController
    func didDismiss() {
        stopDim()
    }

    //MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // To be completed
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(_ searchController: UISearchController) {
        // to be completed -> nothing to do if we keep the filter!
        theTableView.reloadData()
    }
    
    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.text = searchFilter
    }
    
    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        // 2 fix sections (POI Groups + Monitored POIs) + dynamic sections per Country
        return SectionIndex.count + POIDataManager.sharedInstance.getAllCountriesOrderedByName().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    fileprivate func getCountrySectionIndexFrom(_ section:Int) -> Int {
        return section - SectionIndex.count
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // If the section has no data, we don't display at all
        if self.tableView(theTableView, numberOfRowsInSection: section) == 0 {
            return nil
        }
        
        switch (section) {
        case SectionIndex.poiGroups:
            return NSLocalizedString("UserGroupSectionHeader", comment: "")
        case SectionIndex.monitoredPois:
            return NSLocalizedString("MonitoredSectionHeader", comment: "")
        default:
            return getCountryName(section)
        }
    }
    
    fileprivate func getCountryForIndex(_ section:Int) -> POIDataManager.CountryDescription? {
        let countryIndex = getCountrySectionIndexFrom(section)
        let countries = POIDataManager.sharedInstance.getAllCountriesOrderedByName()
        if countryIndex < countries.count {
            return countries[countryIndex]
        } else {
            return nil
        }
    }
    
    fileprivate func getCityNameFromCountry(_ country:POIDataManager.CountryDescription, row:Int) -> String {
        let cities = POIDataManager.sharedInstance.getAllCitiesFromCountry(country.ISOCountryCode, filter: searchFilter)
        if (row - 1) < cities.count {
            return searchFilter.isEmpty ? cities[row - 1] : cities[row]
        } else {
            return NSLocalizedString("UnknownCity", comment: "")
        }
    }

    fileprivate func getCityNameForIndex(_ indexPath:IndexPath) -> String {
        if let country = getCountryForIndex(indexPath.section) {
            return getCityNameFromCountry(country, row: indexPath.row)
        } else {
            return NSLocalizedString("UnknownCountry", comment: "")
        }
    }
    
    
    fileprivate func getCountryName(_ section:Int) -> String {
        return getCountryForIndex(section)?.countryName ?? NSLocalizedString("UnknownCountry", comment: "")
    }
    
    fileprivate struct cellIdentifier {
        static let POIGroupListCellId = "POIGroupListCellId"
        static let MonitoredPoisGroupCellId = "MonitoredPoisGroupCellId"
        static let CityGroupCell = "CityGroupCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case SectionIndex.poiGroups:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.POIGroupListCellId, for: indexPath) as! POIGroupCell
            
            // build and array with the GroupOdPointOfInterest and extract the value at the index
            theCell.initWithGroup(filteredGroups[indexPath.row], index:indexPath.row)
            
            return theCell
        case SectionIndex.monitoredPois:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.MonitoredPoisGroupCellId, for: indexPath) as! MonitoredPoisGroupCell
            return theCell
        default:
            return getCountryOrCityTableViewCell(tableView, indexPath: indexPath)
        }
    }
    
    fileprivate func getCountryOrCityTableViewCell(_ tableView: UITableView, indexPath:IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && searchFilter.isEmpty {
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.CityGroupCell, for: indexPath) as! CityGroupCell
            theCell.cityNameLabel.text  = NSLocalizedString("AllFomCountry", comment: "")
            return theCell
        } else {
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.CityGroupCell, for: indexPath) as! CityGroupCell
            theCell.cityNameLabel.text = getCityNameForIndex(indexPath)
            return theCell
        }
    }

    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == SectionIndex.poiGroups {
            return !POIDataManager.sharedInstance.isMandatoryGroup(filteredGroups[indexPath.row])
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
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
    
    fileprivate func deletePoiGroup(_ indexPath:IndexPath) {
        theTableView.beginUpdates()
        POIDataManager.sharedInstance.deleteGroup(group:filteredGroups[indexPath.row])
        POIDataManager.sharedInstance.commitDatabase()
        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        theTableView.deleteRows(at: [indexPath], with: .fade)
        theTableView.endUpdates()
    }
    
    fileprivate func deleteMonitoredPois(_ indexPath:IndexPath) {
        theTableView.beginUpdates()
        POIDataManager.sharedInstance.deleteMonitoredPOIs()
        POIDataManager.sharedInstance.commitDatabase()
        theTableView.deleteSections(IndexSet(integer:indexPath.section), with: .fade)
        theTableView.endUpdates()
    }
    
    fileprivate func deleteRowFromCountriesAndCities(_ indexPath:IndexPath) {
        if let country = getCountryForIndex(indexPath.section) {
         let isoCountryCode = country.ISOCountryCode
            if indexPath.row == 0 && searchFilter.isEmpty {
                theTableView.beginUpdates()
                POIDataManager.sharedInstance.deleteCountryPOIs(isoCountryCode)
                POIDataManager.sharedInstance.commitDatabase()
                
                theTableView.deleteSections(IndexSet(integer:indexPath.section), with: .fade)
                theTableView.endUpdates()
            } else {
                let cities = POIDataManager.sharedInstance.getAllCitiesFromCountry(isoCountryCode, filter: searchFilter)
                if (indexPath.row - 1) < cities.count {
                    theTableView.beginUpdates()
                    POIDataManager.sharedInstance.deleteCityPOIs(searchFilter.isEmpty ? cities[indexPath.row - 1] : cities[indexPath.row], fromISOCountryCode:isoCountryCode)
                    POIDataManager.sharedInstance.commitDatabase()
                    if (cities.count == 1 && searchFilter.isEmpty) || (cities.count == 0 && !searchFilter.isEmpty) {
                        theTableView.deleteSections(IndexSet(integer:indexPath.section), with: .fade)
                    } else {
                        theTableView.deleteRows(at: [indexPath], with: .fade)
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
    fileprivate struct storyboard {
        static let showPOIList = "showPOIList"
        static let updateGroupOfInterest = "updateGroupOfInterest"
        static let showMonitoredPois = "showMonitoredPois"
        static let showCityPois = "showCityPois"
        static let openGroupConfiguratorId = "openGroupConfiguratorId"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case storyboard.showPOIList:
            let poiController = segue.destination as! POIsViewController
            let group = filteredGroups[theTableView.indexPathForSelectedRow!.row]
            poiController.showGroup(group)
        case storyboard.showMonitoredPois:
            let poiController = segue.destination as! POIsViewController
            poiController.showMonitoredPois()
        case storyboard.showCityPois:
            if let indexPath = theTableView.indexPathForSelectedRow {
                let poiController = segue.destination as! POIsViewController
                showCountriesOrCitiesFor(indexPath, viewController: poiController)
            }
        case storyboard.updateGroupOfInterest:
            startDim()
            let viewController = segue.destination as! GroupConfiguratorViewController
            viewController.delegate = self
            viewController.group = sender as? GroupOfInterest
        case storyboard.openGroupConfiguratorId:
            startDim()
            let viewController = segue.destination as! GroupConfiguratorViewController
            viewController.delegate = self
        default:
            print("\(#function) Error, unknown identifier")
        }
    }
    
    
    
    fileprivate func showCountriesOrCitiesFor(_ indexPath:IndexPath, viewController: POIsViewController) {
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
