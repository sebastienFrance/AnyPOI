//
//  SearchController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 09/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import SafariServices

class SearchController: UITableViewController {


    enum Actions {
        case none, editGroup, showGroupContent, showRoute, editPoi
    }
    
    enum ScopeFilter:Int {
        case all = 0, localSearch = 1, others = 2
    }
    
    fileprivate var currentFilter = ScopeFilter.all
    
    var selectedGroup:GroupOfInterest?
    fileprivate(set) var selectedPoi:PointOfInterest?
    fileprivate(set) var selectedRoute:Route?
    fileprivate(set) var selectedAction = Actions.none
    
    fileprivate var isOnMapDisplayedOnly:Bool {
        get {
            let searchString = theSearchController.searchBar.text ?? ""
            return searchString.isEmpty && selectedCategory == nil ? true : false
        }
    }
    
    var theSearchController:UISearchController!
    
    fileprivate enum SectionIndex:Int {
        case categories = 0, localSearch = 1, poi = 2, groups = 3, route = 4
    }
    
    weak var delegate:SearchControllerDelegate!
    
    fileprivate var selectedCellIndex = -1
    fileprivate var selectedCategory:CategoryUtils.Category?
    fileprivate var isWikipediaSelected:Bool {
        get {
            if let category = selectedCategory, category == CategoryUtils.wikipediaCategory {
                return true
            } else {
                return false
            }
        }
    }
    var currentRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(0, 0), span: MKCoordinateSpanMake(0, 0))

    fileprivate var storedOffsets = CGFloat(0.0)
    
    fileprivate var wikiRequest:WikipediaRequest! // Use to query wikipedia asynchronously
    fileprivate var wikipediaResults = [Wikipedia]() // Store the result of the wikipedia query
    
    fileprivate var pois = [PointOfInterest]()
    fileprivate var groups = [GroupOfInterest]()
    fileprivate var routes = [Route]()
    
    fileprivate var localSearchRequest:MKLocalSearch? // Request used to perform the local search
    fileprivate var localSearchMapItems = [MKMapItem]() // Contains the result of the local search (ordered by distance)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wikiRequest = WikipediaRequest(delegate:self)
        
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Mandatory to make sure the TableView is displayed when the search field is empty
        // when user touch it.
        view.isHidden = false
        
        // reset action
        selectedAction = .none
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Go on top of the table view
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        // Make the height takes into account the safe area (especially for iPhone X)
        view.frame.size = CGSize(width: view.frame.width, height: view.frame.height - view.safeAreaInsets.bottom)

    }
    
    deinit {
    }
    
    
    /// Used to trigger an update of search controller. When the search string is empty, it display by default
    /// the POIs that are currently displayed on the Map
    ///
    /// - Parameters:
    ///   - region: region in which the local search must be done
    func updateSearch() {

        let filter = ScopeFilter(rawValue:delegate.theSearchController!.searchBar.selectedScopeButtonIndex)!
        let searchString = theSearchController.searchBar.text ?? ""
        
        // Search with Wikipedia or with Local Search
        if filter == .all || filter == .localSearch {
            // Map Center may have changed, we need to re-order our data if we have some
            if isWikipediaSelected {
                localSearchMapItems = [MKMapItem]()
                wikiRequest.searchAround(currentRegion.center)
            } else {
                wikipediaResults = [Wikipedia]()
                makeLocalSearch(searchString:searchString, region:currentRegion)
            }
        }

        // Search in our database (POIs, route, groups)
        if filter == .all || filter == .others {
            
            // When the search String is empty then we display all groups and pois that
            // are displayed on the map
            if searchString.isEmpty {
                // Mandatory to force the TableView to be displayed even when the search field becomes empty
                view.isHidden = false
                
                
                // Get all Pois displayed on the Map and then extract all matching the category (if any)
                var displayedPois = [PointOfInterest]()
                
                let mapAnnotations = MapViewController.instance!.theMapView.annotations
                for currentAnnotation in mapAnnotations {
                    if currentAnnotation is PointOfInterest {
                        let currentPoi = currentAnnotation as! PointOfInterest
                        if let category = selectedCategory {
                            if category == currentPoi.category {
                                displayedPois.append(currentPoi)
                            }
                        } else {
                            displayedPois.append(currentPoi)
                        }
                    }
                }
                
                pois = displayedPois.sorted() {
                    MapUtils.distanceFromTo($0.coordinate, toCoordinate: currentRegion.center) <= MapUtils.distanceFromTo($1.coordinate, toCoordinate: currentRegion.center)
                }
                routes = [Route]()
            } else {
                // We search for the groups and pois that matches the string
                let notSortedPois = POIDataManager.sharedInstance.findPOI(searchString, category:selectedCategory)
                pois = notSortedPois.sorted() {
                    MapUtils.distanceFromTo($0.coordinate, toCoordinate: currentRegion.center) <= MapUtils.distanceFromTo($1.coordinate, toCoordinate: currentRegion.center)
                }
                groups = POIDataManager.sharedInstance.findGroups(searchString)
                routes = POIDataManager.sharedInstance.findRoute(searchString)
            }
        }
        
        tableView.reloadSections(IndexSet(integersIn:1...4), with: .automatic)
    }
    
    
    /// Build the search string that must be used for the local search
    ///
    /// - Parameter userFilter: string typed by the user
    /// - Returns: A string to use for the local search or nil if there's nothing to search
    fileprivate func buildSearchStringFrom(userFilter:String) -> String? {
        if userFilter.isEmpty {
            if let category = selectedCategory {
                if category == CategoryUtils.contactCategory || category == CategoryUtils.defaultGroupCategory {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        var fullSearchString = ""
        if let category = selectedCategory {
            fullSearchString = category.localizedString
            if !userFilter.isEmpty {
                fullSearchString += " \(userFilter)"
            }
        } else {
            fullSearchString = userFilter
        }
        return fullSearchString
    }
    
    var onGoingCancelRequest = false
    
    /// Trigger a local search using the selected category + the given search string.
    /// When the selectedCategory is empty the search is done only on the given string
    ///
    /// In case of succes the localSearchMapItems is updated with the result (list of MapItems
    /// ordered by distance)
    ///
    /// - Parameters:
    ///   - searchString: string that must be used to perform the local search
    ///   - region: area in which the local search must be done
    fileprivate func makeLocalSearch(searchString: String, region:MKCoordinateRegion) {
        
        // Stop an ongoing request
        if let theOngoingLocalSearch = localSearchRequest, theOngoingLocalSearch.isSearching {
            // Warning, cancel() seems async and then can still return true later... It's why we set the boolean canceled 
            // to true to make sure we are not displaying indefinitely a searching row in the table view
            theOngoingLocalSearch.cancel()
            onGoingCancelRequest = true
        }
        
        guard let fullSearchString = buildSearchStringFrom(userFilter: searchString) else {
            localSearchMapItems = [MKMapItem]()
            return
        }
        // Canceled must not be set to true before we are sure we will send a new request
        onGoingCancelRequest = false
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = fullSearchString
        request.region = region
        
        localSearchRequest = MKLocalSearch(request:request)
        localSearchRequest!.start { localSearchResponse, error in
            if let theError = error {
                NSLog("\(#function) error on request \(theError.localizedDescription)")
                self.localSearchMapItems = [MKMapItem]()
           } else {
                if let theLocalSearchResponse = localSearchResponse {
                    self.localSearchMapItems = theLocalSearchResponse.mapItems.sorted() {
                        MapUtils.distanceFromTo($0.placemark.coordinate, toCoordinate: self.currentRegion.center) <= MapUtils.distanceFromTo($1.placemark.coordinate, toCoordinate: self.currentRegion.center)
                    }
                } else {
                    self.localSearchMapItems = [MKMapItem]()
                }
            }
            
            self.tableView.reloadSections(IndexSet(integer: SectionIndex.localSearch.rawValue), with: .automatic)
            self.localSearchRequest = nil
        }
    }
    
    //MARK: Scope filter
    @IBAction func scopeFilterHasChanged(_ sender: UISegmentedControl) {
        currentFilter = ScopeFilter(rawValue:sender.selectedSegmentIndex)!
        updateSearch()
    }
    
    //MARK: Actions buttons
   @IBAction func editPoi(_ sender: UIButton) {
        selectedPoi = pois[sender.tag]
        selectedAction = .editPoi
        
        // Mandatory to force the UISearchController to dismiss
        theSearchController.isActive = false
    }

    @IBAction func showGroupContent(_ sender: UIButton) {
        selectedGroup = groups[sender.tag]
        selectedAction = .showGroupContent

        // Mandatory to force the UISearchController to dismiss
        theSearchController.isActive = false
   }
    
    @IBAction func editGroup(_ sender: UIButton) {
        selectedGroup = groups[sender.tag]
        selectedAction = .editGroup

        theSearchController.isActive = false
    }

    @IBAction func showWebsiteFromLocalSearch(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: localSearchMapItems[sender.tag].url, delegate: self)
    }
    
    @IBAction func showWikipediaWebsite(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: URL(string: wikipediaResults[sender.tag].url), delegate: self)
    }

    
    
    //MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch SectionIndex(rawValue:section)! {
        case .groups:
            if (currentFilter == .all || currentFilter == .others) && groups.count > 0 {
                return isOnMapDisplayedOnly ?  NSLocalizedString("GroupDisplayedOnMapSearchController", comment: "") : NSLocalizedString("GroupDisplayedSearchController", comment: "")
            } else {
                return nil
            }
        case .poi:
            if (currentFilter == .all || currentFilter == .others) && pois.count > 0 {
                return isOnMapDisplayedOnly ? NSLocalizedString("POIsDisplayedOnMapSearchController", comment: "") : NSLocalizedString("POIsDisplayedSearchController", comment: "")
            } else {
                return nil
            }
        case .localSearch:
            if isWikipediaSelected {
                if (currentFilter == .all || currentFilter == .localSearch) && wikipediaResults.count > 0 {
                    return NSLocalizedString("Wikipedia", comment: "")
                } else {
                    return nil
                }
            } else {
                if (currentFilter == .all || currentFilter == .localSearch) && localSearchMapItems.count > 0 {
                    return NSLocalizedString("LocalSearchSearchController", comment: "")
                } else {
                    return nil
                }
            }
        case .route:
            if (currentFilter == .all || currentFilter == .others) && routes.count > 0 {
                return NSLocalizedString("RoutesSearchController", comment: "")
            } else {
                return nil
            }
        case .categories:
            return nil
        }
        
    }
    
    //MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionIndex(rawValue:section)! {
        case .groups:
            if currentFilter == .all || currentFilter == .others {
                return groups.count
            }
        case .poi:
            if currentFilter == .all || currentFilter == .others {
                return pois.count
            }
        case .localSearch:
            if currentFilter == .all || currentFilter == .localSearch {
                if isWikipediaSelected {
                    if wikiRequest.isWikipediaLoading {
                        return 1
                    } else {
                        return wikipediaResults.count
                    }
                } else {
                    if let theOngoingLocalSearch = localSearchRequest, theOngoingLocalSearch.isSearching, !onGoingCancelRequest {
                        return 1
                    } else {
                        return localSearchMapItems.count
                    }
                }
            }
        case .route:
            if currentFilter == .all || currentFilter == .others {
                return routes.count
            }
        case .categories:
            return 1
        }
        return 0
    }
    
    struct cellIdentifier {
        static let poiDescriptionCellId = "poiDescriptionCellId"
        static let groupDescriptionCellId = "groupDescriptionCellId"
        static let localSearchCellId = "localSearchCellId"
        static let searchRouteCellId = "searchRouteCellId"
        static let CategoriesTableViewCellId = "CategoriesTableViewCellId"
        static let ScopeFilterCellId = "ScopeFilterCellId"
        static let WikipediaCellId = "WikipediaLocalSearchTableViewCellId"
        static let SearchLoadingTableViewCellId = "SearchLoadingTableViewCellId"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionIndex(rawValue:indexPath.section)! {
        case .groups:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.groupDescriptionCellId, for: indexPath) as! searchGroupViewCell
            theCell.initWith(groups[indexPath.row], index:indexPath.row)
            return theCell
        case .poi:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.poiDescriptionCellId, for: indexPath) as! searchPoiViewCell
            theCell.initWith(pois[indexPath.row], index:indexPath.row, region: currentRegion)
            return theCell
        case .localSearch:
            if isWikipediaSelected {
                if wikiRequest.isWikipediaLoading {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.SearchLoadingTableViewCellId, for: indexPath) as! SearchLoadingTableViewCell
                    theCell.activiyIndicator.startAnimating()
                    return theCell
                } else {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.WikipediaCellId, for: indexPath) as! WikipediaLocalSearchTableViewCell
                    theCell.initWith(wikipediaResults[indexPath.row], index: indexPath.row)
                    return theCell
                }
            } else {
                if let theOngoingLocalSearch = localSearchRequest, theOngoingLocalSearch.isSearching  {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.SearchLoadingTableViewCellId, for: indexPath) as! SearchLoadingTableViewCell
                    theCell.activiyIndicator.startAnimating()
                    return theCell
                } else {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.localSearchCellId, for: indexPath) as! LocalSearchTableViewCell
                    theCell.initWith(localSearchMapItems[indexPath.row], index:indexPath.row, region: currentRegion)
                    return theCell
                }
            }
        case .route:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.searchRouteCellId, for: indexPath) as! searchRouteTableViewCell
            theCell.initWith(routes[indexPath.row])
            return theCell
        case .categories:
            let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.CategoriesTableViewCellId, for: indexPath) as! CategoriesTableViewCell
            theCell.initWith(currentFilter)
            return theCell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let theCell = cell as? searchPoiViewCell {
            theCell.configureMarker(poi: pois[indexPath.row])
            return
        }

        guard let tableViewCell = cell as? CategoriesTableViewCell else {
            return
        }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets
        
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? CategoriesTableViewCell else { return }
        tableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        storedOffsets = tableViewCell.collectionViewOffset
    }
    
    
    // When a group or poi is selected, a notification is posted to display it on the map
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionIndex(rawValue:indexPath.section)! {
        case .groups:
            let currentGroup = groups[indexPath.row]
            delegate.showGroupOnMap(currentGroup)
        case .poi:
            let currentPOI = pois[indexPath.row]
            delegate.showPOIOnMap(currentPOI, isSelected:true)
        case .localSearch:
            var poi:PointOfInterest?
            if isWikipediaSelected, !wikiRequest.isWikipediaLoading {
                
                poi = POIDataManager.sharedInstance.findPOIWith(wikipediaResults[indexPath.row])
                if poi == nil {
                    poi = POIDataManager.sharedInstance.addPOI(wikipediaResults[indexPath.row], group:POIDataManager.sharedInstance.getDefaultGroup())
                }
            } else {
                if let theOngoingLocalSearch = localSearchRequest, theOngoingLocalSearch.isSearching {
                    return
                }
                let mapItem = localSearchMapItems[indexPath.row]
                let foundPois = POIDataManager.sharedInstance.findPOIWith(name: mapItem.name!, andCoordinates: mapItem.placemark.coordinate)
                if  foundPois.count > 0 {
                    poi = foundPois.first
                } else {
                    poi = POIDataManager.sharedInstance.addPOI(localSearchMapItems[indexPath.row], category: selectedCategory)
                }
            }
            
            if let poiToShow = poi {
                delegate.showPOIOnMap(poiToShow, isSelected:true)
            }
        case .route:
            selectedRoute = routes[indexPath.row]
            selectedAction = .showRoute
            
            // Mandatory to force the UISearchController to dismiss
            theSearchController.isActive = false
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        switch SectionIndex(rawValue:indexPath.section)! {
        case .groups, .poi, .route:
            return .delete
        default:
            return .none
        }
    }
    
    // Delete from database the deleted group or poi
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            switch SectionIndex(rawValue:indexPath.section)! {
            case .groups:
                POIDataManager.sharedInstance.deleteGroup(group: groups[indexPath.row])
                POIDataManager.sharedInstance.commitDatabase()
                groups.remove(at: indexPath.row)
            case .poi:
                POIDataManager.sharedInstance.deletePOI(POI: pois[indexPath.row])
                POIDataManager.sharedInstance.commitDatabase()
                pois.remove(at: indexPath.row)
            case .localSearch:
                return
            case .route:
                POIDataManager.sharedInstance.deleteRoute(routes[indexPath.row])
                POIDataManager.sharedInstance.commitDatabase()
                routes.remove(at: indexPath.row)
            case .categories:
                return
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default: break
            // just ignore, manage only deletion
            
        }
    }
    

}

extension SearchController : SFSafariViewControllerDelegate {
    //MARK: SFSafariViewControllerDelegate
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
    }

}

extension SearchController : WikipediaRequestDelegate {
    // MARK: WikiepdiaRequestDelegate
    func wikipediaLoadingDidFinished(_ wikipedias:[Wikipedia]) {
        wikipediaResults = wikipedias
        tableView.reloadSections(IndexSet(integer: SectionIndex.localSearch.rawValue), with: .automatic)
    }
    
    func wikipediaLoadingDidFailed() {
        wikipediaResults = [Wikipedia]()
    }
}

extension SearchController: UICollectionViewDelegate, UICollectionViewDataSource {
    //MARK: UICollectionViewDelegate, UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CategoryUtils.localSearchCategories.count
    }
    
    fileprivate struct CellId {
        static let categoryCellId = "Cell"
    }
    
    fileprivate static let WikipediaRowId = 0
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId.categoryCellId, for: indexPath) as! CategoryCollectionViewCell
        
        let category = CategoryUtils.localSearchCategories[indexPath.row]
        cell.initWith(category: category)
        if let theSelectedCategory = selectedCategory, category == theSelectedCategory {
            cell.highlight(isOn: true)
        } else {
            cell.highlight(isOn: false)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // unselect an older selection (if any)
        if selectedCellIndex != -1 {
            if let cell = collectionView.cellForItem(at: IndexPath(row: selectedCellIndex, section: 0)) as? CategoryCollectionViewCell {
                cell.highlight(isOn: false)
            }
        }
        
        let newSelectedCategory = CategoryUtils.localSearchCategories[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath) as? CategoryCollectionViewCell
        
        
        if let oldSelectedCategory = selectedCategory, newSelectedCategory == oldSelectedCategory {
            selectedCategory = nil
            selectedCellIndex = -1
        } else {
            selectedCellIndex = indexPath.row
            selectedCategory = newSelectedCategory
            cell?.highlight(isOn: true)
        }
        
        updateSearch()
    }

}
