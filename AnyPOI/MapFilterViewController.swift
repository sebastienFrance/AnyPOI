//
//  MapFilterViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 12/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilterViewController: UIViewController {

    struct Notifications {
        static let addCategoryToFilter = "addCategoryToFilter"
        static let removeCategoryFromFilter = "removeCategoryFromFilter"
        struct categoryParameter {
            static let categoryName = "category"
        }
        static let hidePOIsNotInRoute = "hidePOIsNotInRoute"
        static let showPOIsNotInRoute = "showPOIsNotInRoute"
    }
    
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 80
                theTableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    var isRouteModeOn = false
    var showPOIsNotInRoute = false
    var filter:MapCategoryFilter!
    let groups = POIDataManager.sharedInstance.getGroups()

    // Actions displayed when 3D Touch is used to navigate to Map Filter
    // Button is only add when something is filtered
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            if resetButton.isEnabled {
                let actionClearFitler = UIPreviewAction(title: NSLocalizedString("ClearFilterMapFilterVC", comment: ""), style: .destructive) { (action, viewController) in
                    self.resetFilter()
                }
                return [actionClearFitler]
            } else {
                return []
            }
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateResetButtonState()
    }
    
    
    /// Enable the Reset button only when at least something is filtered
    /// - a Category
    /// - Hide POIs not in Route when Route mode is on
    /// - at least one group is not displayed
    func updateResetButtonState() {
        resetButton.isEnabled = false
       if !filter.filter.isEmpty {
            resetButton.isEnabled = true
        } else {
            if isRouteModeOn && !showPOIsNotInRoute {
                resetButton.isEnabled = true
            } else {
                for currentGroup in groups {
                    if !currentGroup.isGroupDisplayed {
                        resetButton.isEnabled = true
                        return
                    }
                }
            }
        }
    }
    
    @IBAction func resetButtonPushed(_ sender: UIBarButtonItem) {
        resetFilter()
    }
    
    
    /// Filter all Categories from the map
    /// - All categories are added in the Filter and for each of them a notification is send to update the Map
    /// - Update the Tableview to show all Categories are filtered
    /// - Update the Reset button, which must be enabled
    ///
    /// - Parameter sender: button
    @IBAction func hideAllCategoriesButtonPushed(_ sender: UIBarButtonItem) {
        for category in CategoryUtils.localSearchCategories {
            filter.add(category: category)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.addCategoryToFilter),
                                            object: self,
                                            userInfo:[Notifications.categoryParameter.categoryName: category])
        }
        
        let sectionToUpdate = NSMutableIndexSet()
        sectionToUpdate.add(Sections.categories)
        theTableView.reloadSections(sectionToUpdate as IndexSet, with: .none)
        updateResetButtonState()
    }
    
    
    /// Reset the filter configured by the user, it means:
    /// - Show POIs not in Route when the route mode is on
    /// - Show all categories that were filtered
    /// - Show all groups that were filetered
    /// For each changes a notification is sent to update the Map with the new filter
    /// Each impacted sections in the tableview is reloaded
    fileprivate func resetFilter() {
        let sectionToUpdate = NSMutableIndexSet()
        
        if !showPOIsNotInRoute {
            showPOIsNotInRoute = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.showPOIsNotInRoute), object: self)
            sectionToUpdate.add(Sections.routeMode)
        }
        
        if !filter.filter.isEmpty {
            for currentCategory in filter.filter {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.removeCategoryFromFilter), object: self, userInfo:[Notifications.categoryParameter.categoryName: currentCategory])
            }
            filter.reset()
            sectionToUpdate.add(Sections.categories)
        }
        
        for currentGroup in groups {
            if !currentGroup.isGroupDisplayed {
                sectionToUpdate.add(Sections.groups)
                currentGroup.isGroupDisplayed = true
                // It will add/remove annotations from the Map, it can takes some times... so to no block
                // user we do it asynchronously
                DispatchQueue.main.async {
                    POIDataManager.sharedInstance.updatePOIGroup(currentGroup)
                    POIDataManager.sharedInstance.commitDatabase()
                }
            }
        }
        
        theTableView.reloadSections(sectionToUpdate as IndexSet, with: .automatic)
    }
}

extension MapFilterViewController : UITableViewDelegate, UITableViewDataSource {

    struct cellId {
        static let categoryCellId = "MapFilterCategoryCellId"
        static let mapGroupFilterCellId = "mapGroupFilterCellId"
        static let mapFilterShowAllPoisId = "mapFilterShowAllPoisId"
    }
    
    struct Sections {
        static let routeMode = 0
        static let categories = 1
        static let groups = 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.categories:
            return NSLocalizedString("CategoriesSectionMapFilterVC", comment: "")
        case Sections.groups:
            return NSLocalizedString("GroupsSectionMapFilterVC", comment: "")
        case Sections.routeMode:
            return isRouteModeOn ? NSLocalizedString("RouteSectionMapFilterVC", comment: "") : nil
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.categories:
            return CategoryUtils.localSearchCategories.count
        case Sections.groups:
            return groups.count
        case Sections.routeMode:
            return isRouteModeOn ? 1 : 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.categoryCellId, for: indexPath) as! MapFilterCategoryTableViewCell
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            cell.initWith(category:category, isFiltered:filter.isFiletered(category: category))
            return cell
        case Sections.groups:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.mapGroupFilterCellId, for: indexPath) as! MapFilterGroupTableViewCell
            cell.initWith(group:groups[indexPath.row])
            return cell
        case Sections.routeMode:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.mapFilterShowAllPoisId, for: indexPath) as! MapFilterShowAllPoisTableViewCell
            cell.initWith(showPOIsNotInRoute: showPOIsNotInRoute)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Sections.categories:
            let cell = theTableView.cellForRow(at: indexPath) as! MapFilterCategoryTableViewCell
            
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            if filter.isFiletered(category: category) {
                // when the Category is already filtered we remove it from the filter and we send a notification to update the map
                filter.remove(category: category)
                cell.isFiltered = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.removeCategoryFromFilter),
                                                object: self,
                                                userInfo:[Notifications.categoryParameter.categoryName: category])
            } else {
                // When the Category is not yet filtered we add it in the filter and we send a notification to update the map
                filter.add(category: category)
                cell.isFiltered = true
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.addCategoryToFilter),
                                                object: self,
                                                userInfo:[Notifications.categoryParameter.categoryName: category])
            }
        case Sections.groups:
            let POIGroup = groups[indexPath.row]
            
            // Default group cannot be filtered
            if POIDataManager.sharedInstance.getDefaultGroup() != POIGroup {
                
                POIGroup.isGroupDisplayed = !POIGroup.isGroupDisplayed
                let cell = theTableView.cellForRow(at: indexPath) as! MapFilterGroupTableViewCell
                cell.initWith(group:groups[indexPath.row])
                
                // It will add/remove annotations from the Map, it can takes some times... so to no block
                // user we do it asynchronously
                DispatchQueue.main.async {
                    // Map will be automatically updated when the database will send a notification about the changes
                    POIDataManager.sharedInstance.updatePOIGroup(POIGroup)
                    POIDataManager.sharedInstance.commitDatabase()
                }
            }
        case Sections.routeMode:
            showPOIsNotInRoute = !showPOIsNotInRoute
            let cell = theTableView.cellForRow(at: indexPath) as! MapFilterShowAllPoisTableViewCell
            cell.initWith(showPOIsNotInRoute: showPOIsNotInRoute)
            let notificationType = showPOIsNotInRoute ? Notifications.showPOIsNotInRoute : Notifications.hidePOIsNotInRoute
            
            // Send a notification to hide or show POIs not in route in the map
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationType), object: self)

        default:
            return
        }
        updateResetButtonState()
    }
}
