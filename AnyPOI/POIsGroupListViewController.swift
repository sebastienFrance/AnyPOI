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


class POIsGroupListViewController: UIViewController, DismissModalViewController, ContainerViewControllerDelegate {

    
    @IBOutlet fileprivate weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.dataSource = self
                tableView.delegate = self
                tableView.estimatedRowHeight = 110
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    

    private var searchController:UISearchController!
    private var searchFilter = "" // Use to perform filtering on list of groups
    private var filteredGroups = [GroupOfInterest]()

    
    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }
    
    // MARK: ContainerViewControllerDelegate protocol
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?

    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            theTableView.isUserInteractionEnabled = enable
        }
    }

    
    //MARK: Initializations
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(POIsGroupListViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsGroupListViewController.contextDidSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: DatabaseAccess.sharedInstance.managedObjectContext)
        
        
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
        
        registerKeyboardNotifications()
     }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // When this view controller has disappear we must be sure the
        // searchController is no more displayed (for example when Navigating to the Map and the SearchController is displayed
        // or when selecting a POIs to distplay its details and the SearchController is also displayed
        searchController.isActive = false
        unregisterKeyboardNotifications()
    }
    
    
    //MARK: Notifications
    @objc func contextDidSaveNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        
        // A Group has been added or changed, we must reload the table content
        // A POI has been added/deleted/updated we must reload the table content (one use case is to add create a new POI with monitored atttributes 
        // and it's the first one with it => we must add "Monitored POIs" as section in the table
        if notifContent.insertedGroupOfInterest.count > 0 ||
            notifContent.updatedGroupOfInterest.count > 0 ||
            notifContent.deletedPois.count > 0 ||
            notifContent.updatedPois.count > 0 ||
            notifContent.insertedPois.count > 0 {
            filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
            theTableView.reloadData()
        }
    }
    
    //MARK: Keyboard Mgt
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsGroupListViewController.keyboardWillShow(_:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIsGroupListViewController.keyboardWillHide(_:)),
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

    //MARK: Action buttons
    
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

    //MARK: Segues
    private struct storyboard {
        static let showPOIList = "showPOIList"
        static let updateGroupOfInterest = "updateGroupOfInterest"
        static let showMonitoredPois = "showMonitoredPois"
        static let showPOIsWithoutAddress = "showPOIsWithoutAddress"
        static let showCityPois = "showCityPois"
        static let openGroupConfiguratorId = "openGroupConfiguratorId"
    }
  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case storyboard.showPOIList:
            let poiController = segue.destination as! POIsViewController
            poiController.datasource = POIsGroupDataSource(group: filteredGroups[theTableView.indexPathForSelectedRow!.row])
        case storyboard.showMonitoredPois:
            let poiController = segue.destination as! POIsViewController
            poiController.datasource = POIsMonitoredDataSource()
        case storyboard.showPOIsWithoutAddress:
            let poiController = segue.destination as! POIsViewController
            poiController.datasource = POIsNoAddressDataSource()
        case storyboard.showCityPois:
            if let indexPath = theTableView.indexPathForSelectedRow {
                let poiController = segue.destination as! POIsViewController
                showCountriesOrCitiesFor(indexPath:indexPath, viewController: poiController)
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
            NSLog("\(#function) Error, unknown identifier")
        }
    }
    

    
    /// Initialize the POIsViewController with either the Country or the City that has been selected
    /// The Country is always the first row (index == 0) of a table section else it's a city
    ///
    /// - Parameters:
    ///   - indexPath: indexPath of the selected row
    ///   - viewController: POIs viewController to initialize
    private func showCountriesOrCitiesFor(indexPath:IndexPath, viewController: POIsViewController) {
        if let country = getCountryFrom(section: indexPath.section) {
            if indexPath.row == 0 && searchFilter.isEmpty {
                viewController.datasource = POIsCountryDataSource(country: country)
            } else {
                viewController.datasource = POIsCityDataSource(cityName: getCityNameFrom(country: country, row: indexPath.row), country: country)
            }
        } else {
            NSLog("\(#function) Warning, invalid index to look for a Country \(indexPath.row)")
        }
    }
}

extension POIsGroupListViewController : UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    //MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // Nothing to do
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(_ searchController: UISearchController) {
        clearFilter()
    }
    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        theTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearFilter()
    }
    
    fileprivate func clearFilter() {
        if !searchFilter.isEmpty {
            searchFilter = ""
            searchController.searchBar.text = ""
            filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
            theTableView.reloadData()
        }
    }
}

extension POIsGroupListViewController : UITableViewDataSource, UITableViewDelegate  {
    // Fix sections, next there's one dynamic section per country
    private struct SectionIndex {
        static let groupOfInterest = 0
        static let monitoredPOIsAndGPXNoAddress = 1 // This section contains the Monitored POIs and GPX without address
        static let fixedSectionsCount = 2
    }

    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        // 3 fix sections (POI Groups + Monitored POIs + POIs without address) + dynamic sections per Country
        return SectionIndex.fixedSectionsCount + countriesWithCitiesMatching(filter: searchFilter).count
    }
    
    // Get all Countries that have at least one city matching the Filter
    private func countriesWithCitiesMatching(filter:String) -> [CountryDescription] {
        return POIDataManager.sharedInstance.getCountriesWithCitiesMatching(filter: searchFilter)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionIndex.groupOfInterest {
            return filteredGroups.count
        } else if section == SectionIndex.monitoredPOIsAndGPXNoAddress {
            if searchFilter.isEmpty {
                var numberOfRows = POIDataManager.sharedInstance.getAllMonitoredPOI().count > 0 ? 1 : 0
                numberOfRows += POIDataManager.sharedInstance.getPoisWithoutPlacemark().count > 0 ? 1 : 0
                return numberOfRows
            } else {
                return 0
            }
        } else {
            // Get again the list of countries where at least one city match the filter
            let sectionIndex = getCountrySectionIndexFrom(section)
            let countries = countriesWithCitiesMatching(filter: searchFilter)
            if sectionIndex < countries.count {
                // For the country matching the filter we get all its cities, it will gives the number of row in the section
                let citiesForSection = countries[sectionIndex].getAllCities(filter: searchFilter)
                return searchFilter.isEmpty ? citiesForSection.count + 1  : citiesForSection.count
            } else {
                NSLog("\(#function) Warning, cannot find cities for index \(section)")
                return 0
            }
        }
    }
    
    // Index of Country is the number of section minus the number of fix sections
    private func getCountrySectionIndexFrom(_ section:Int) -> Int {
        return section - SectionIndex.fixedSectionsCount
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // If the section has no data, we don't display at all
        if self.tableView(theTableView, numberOfRowsInSection: section) == 0 {
            return nil
        }
        
        switch (section) {
        case SectionIndex.groupOfInterest:
            return NSLocalizedString("UserGroupSectionHeader", comment: "")
        case SectionIndex.monitoredPOIsAndGPXNoAddress:
            return NSLocalizedString("OthersSectionHeader", comment: "")
        default:
            return getCountryNameFrom(section: section)
        }
    }
    
    private func getCountryFrom(section:Int) -> CountryDescription? {
        let countryIndex = getCountrySectionIndexFrom(section)
        let countries = countriesWithCitiesMatching(filter: searchFilter)
        if countryIndex < countries.count {
            return countries[countryIndex]
        } else {
            return nil
        }
    }
    
    private func getCityNameFrom(country:CountryDescription, row:Int) -> String {
        let cities = country.getAllCities(filter: searchFilter)
        if (row - 1) < cities.count {
            return searchFilter.isEmpty ? cities[row - 1] : cities[row]
        } else {
            return NSLocalizedString("UnknownCity", comment: "")
        }
    }
    
    private func getCityNameForIndex(_ indexPath:IndexPath) -> String {
        if let country = getCountryFrom(section: indexPath.section) {
            return getCityNameFrom(country:country, row: indexPath.row)
        } else {
            return NSLocalizedString("UnknownCountry", comment: "")
        }
    }
    
    
    private func getCountryNameFrom(section:Int) -> String {
        if let country = getCountryFrom(section: section) {
            return "\(country.countryFlag) \(country.countryName)"
        } else {
            return NSLocalizedString("UnknownCountry", comment: "")
        }
    }
    
    private struct cellIdentifier {
        static let POIGroupListCellId = "POIGroupListCellId"
        static let MonitoredPoisGroupCellId = "MonitoredPoisGroupCellId"
        static let GPXPoisTableViewCellId = "GPXPoisTableViewCellId"
        static let CityGroupCell = "CityGroupCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case SectionIndex.groupOfInterest:
            // First section is used only to display Groups
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.POIGroupListCellId, for: indexPath) as! POIGroupCell
            
            // build and array with the GroupOdPointOfInterest and extract the value at the index
            theCell.initWithGroup(filteredGroups[indexPath.row], index:indexPath.row)
            
            return theCell
        case SectionIndex.monitoredPOIsAndGPXNoAddress:
            // This section may contain one row for MonitoredPOIs and one row for GPXPois without address
            if indexPath.row == 0 {
                if POIDataManager.sharedInstance.getAllMonitoredPOI().count > 0 {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.MonitoredPoisGroupCellId, for: indexPath) as! MonitoredPoisGroupCell
                    return theCell
                }
            }
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.GPXPoisTableViewCellId, for: indexPath) as! GPXPoisTableViewCell
            return theCell
        default:
            // Others sections are for Countries
            return getCountryOrCityTableViewCell(tableView, indexPath: indexPath)
        }
    }
    
    private func getCountryOrCityTableViewCell(_ tableView: UITableView, indexPath:IndexPath) -> UITableViewCell {
        let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.CityGroupCell, for: indexPath) as! CityGroupCell
        
        // When the search filter is not empty the Country row is not displayed
        var cityOrCountryName:String
        if indexPath.row == 0 && searchFilter.isEmpty {
            if let country = getCountryFrom(section: indexPath.section) {
                cityOrCountryName = country.countryName
            } else {
                cityOrCountryName = NSLocalizedString("UnknownCountry", comment: "")
            }
        } else {
            cityOrCountryName =  getCityNameForIndex(indexPath)
        }
        
        theCell.cityNameLabel.text = cityOrCountryName
        return theCell
    }
    
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == SectionIndex.groupOfInterest {
            return !POIDataManager.sharedInstance.isMandatoryGroup(filteredGroups[indexPath.row])
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            deleteRow(index: indexPath)
        default:
            break
        }
    }
    
    private enum SectionId {
        case group, monitoredPois, GPXPois, CountryAndCities
    }
    
    private static func sectionIdFrom(index: IndexPath) -> SectionId {
        switch index.section {
        case SectionIndex.groupOfInterest:
            return .group
        case SectionIndex.monitoredPOIsAndGPXNoAddress:
            if index.row == 0, POIDataManager.sharedInstance.getAllMonitoredPOI().count > 0 {
                return .monitoredPois
            } else {
                return .GPXPois
            }
        default:
            return .CountryAndCities
        }
    }
    
    private func deleteRow(index:IndexPath) {
        
        let sectionToUpdate = POIsGroupListViewController.sectionIdFrom(index: index)
        
        // Keep in mind the list of Counties / Cities before we started to delete POIs
        let countries = countriesWithCitiesMatching(filter: searchFilter)
        var citiesPerCountry = [String:[String]]()
        for currentCountry in countries {
            citiesPerCountry[currentCountry.ISOCountryCode] = currentCountry.getAllCities(filter: searchFilter)
        }
        
        // Keep in mind if the Monitored POIs and GPX POIs rows are displayed
        var hasMonitoredPOIsRow = false
        var hasGPXPois = false
        if searchFilter.isEmpty {
            hasMonitoredPOIsRow = POIDataManager.sharedInstance.getAllMonitoredPOI().count > 0 ? true : false
            hasGPXPois = POIDataManager.sharedInstance.getPoisWithoutPlacemark().count > 0 ? true : false
        }
        
        
        theTableView.beginUpdates()
        var (deletedSections, deletedRows) = cleanupDeleteRowsAndSections(index: index, sectionToUpdate: sectionToUpdate)

        
        // When user has deleted a row that is not a country or city then we get the list of Cities / Countries that must be removed because of the deleted row
        if sectionToUpdate != .CountryAndCities {
            let (deletedCountrySections, deletedCitiesRows) = computeDeletedSectionsAndRowsDueToGroupDeletion(initialCountries: countries, initialCitiesPerCountry: citiesPerCountry)
            deletedSections.formUnion(deletedCountrySections)
            deletedRows.append(contentsOf: deletedCitiesRows)
        }
        
        if deletedSections.count > 0 {
            theTableView.deleteSections(deletedSections, with: .fade)
        }
        
        // Check if the Monitored POIs must be removed from the list
        if hasMonitoredPOIsRow && sectionToUpdate != .monitoredPois {
            if POIDataManager.sharedInstance.getAllMonitoredPOI().count == 0 {
                deletedRows.append(IndexPath(row: 0, section: SectionIndex.monitoredPOIsAndGPXNoAddress))
            }
        }
        
        // Check ifthe GPX POIs must be removed
        if hasGPXPois && sectionToUpdate != .GPXPois {
            if POIDataManager.sharedInstance.getPoisWithoutPlacemark().count == 0 {
                if hasMonitoredPOIsRow {
                    deletedRows.append(IndexPath(row: 0, section: SectionIndex.monitoredPOIsAndGPXNoAddress))
                } else {
                    deletedRows.append(IndexPath(row: 1, section: SectionIndex.monitoredPOIsAndGPXNoAddress))
                }
            }
        }
        
        deletedRows.append(index)
        theTableView.deleteRows(at: deletedRows, with: .fade)
        theTableView.endUpdates()
    }
    
    
    /// Remove from the database the GroupOfInterest and POIs from a section (Monitored POIs...) or from a section
    /// and at a given index path (Group, City, Country...)
    ///
    /// This methods returns alos the list of sections and list of rows that must be removed from the table view
    /// because it may have consequence on List of Countries, Cities, Monitored POIs...
    ///
    /// - Parameters:
    ///   - index: index of the deleted row
    ///   - fromSection: section
    /// - Returns: List of index for Rows and Section that must be removed from the table view. These list maybe empty if no cleanup is needed
    private func cleanupDeleteRowsAndSections(index:IndexPath, sectionToUpdate:SectionId) -> (deletedSections:IndexSet, deletedRows:[IndexPath]){
        var deletedSections = IndexSet()
        var deletedRows = [IndexPath]()
        
        // Remove from the database the data related to the deleted row
        switch sectionToUpdate {
        case .group:
            POIDataManager.sharedInstance.deleteGroup(group:filteredGroups[index.row])
            POIDataManager.sharedInstance.commitDatabase()
            filteredGroups = POIDataManager.sharedInstance.getGroups(searchFilter)
        case .monitoredPois:
            POIDataManager.sharedInstance.deleteMonitoredPOIs()
            POIDataManager.sharedInstance.commitDatabase()
        case .GPXPois:
            POIDataManager.sharedInstance.deletePOIsWithoutPlacemark()
            POIDataManager.sharedInstance.commitDatabase()
        case .CountryAndCities:
            // When we delete a City, it can delete a whole section if it's the latest City from the country
            // if it's not the latest we just delete the row
            // When we delete a Country, we delete the whole section
            if let country = getCountryFrom(section: index.section) {
                let isoCountryCode = country.ISOCountryCode
                // Delete row all
                if index.row == 0 && searchFilter.isEmpty {
                    POIDataManager.sharedInstance.deleteCountryPOIs(isoCountryCode)
                    POIDataManager.sharedInstance.commitDatabase()
                    deletedSections.insert(index.section)
                } else {
                    let cities = country.getAllCities(filter: searchFilter)
                    if (index.row - 1) < cities.count {
                        POIDataManager.sharedInstance.deleteCityPOIs(searchFilter.isEmpty ? cities[index.row - 1] : cities[index.row],
                                                                     fromISOCountryCode:isoCountryCode)
                        POIDataManager.sharedInstance.commitDatabase()
                        // we have deleted the last one so we delete the section
                        if cities.count == 1 {
                            deletedSections.insert(index.section)
                        } else {
                            deletedRows.append(index)
                        }
                    } else {
                        NSLog("\(#function) Warning, invalid index to look for a City : \(index.row - 1)")
                    }
                }
            } else {
                NSLog("\(#function) Warning, invalid index to look for a Country \(index.section)")
            }
        }

        return (deletedSections, deletedRows)
    }
    
    /// Compute the list of sections and rows that must be deleted from the table in section Countries & Cities due to a group deletion
    ///
    /// - Parameters:
    ///   - initialCountries: List of Countries before the group has been deleted
    ///   - initialCitiesPerCountry: List of Cities per Country before the group has been deleted
    /// - Returns: List of sections and rows to be removed from the table
    private func computeDeletedSectionsAndRowsDueToGroupDeletion(initialCountries:[CountryDescription],
                                                                 initialCitiesPerCountry:[String:[String]])
        -> (deletedSections:IndexSet, deletedRows:[IndexPath]) {
        
        let countries = countriesWithCitiesMatching(filter: searchFilter)
        var citiesPerCountry = [String:[String]]()
        for currentCountry in countries {
            citiesPerCountry[currentCountry.ISOCountryCode] = currentCountry.getAllCities(filter: searchFilter)
        }
            
        var rowsToDelete = [IndexPath]()
        // look for removed section
        var deletedSection = IndexSet()
        for i in 0..<initialCountries.count {
            let currentCountry = initialCountries[i]
            if countries.contains(currentCountry) {
                if let oldCities = initialCitiesPerCountry[currentCountry.ISOCountryCode],
                    let newCities = citiesPerCountry[currentCountry.ISOCountryCode],
                    oldCities.count != newCities.count {
                    
                    // Look for missing cities
                    for j in 0..<oldCities.count {
                        let currentCity = oldCities[j]
                        if !newCities.contains(currentCity) {
                            rowsToDelete.append(IndexPath(row: searchFilter.isEmpty ? j + 1 : j, section: i + 2))
                        }
                    }
                }
            } else {
                deletedSection.insert(i + SectionIndex.fixedSectionsCount)
            }
        }
        return (deletedSection, rowsToDelete)
    }
    
 }
