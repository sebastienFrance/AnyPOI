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
    
    var isRouteModeOn = false
    var showPOIsNotInRoute = false
    var filter:MapFilter!
    let groups = POIDataManager.sharedInstance.getGroups()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MapFilterViewController : UITableViewDelegate, UITableViewDataSource {

    struct cellId {
        static let categoryCellId = "MapFilterCategoryCellId"
        static let mapGroupFilterCellId = "mapGroupFilterCellId"
    }
    
    struct Sections {
        static let routeMode = 0
        static let categories = 1
        static let groups = 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.categories {
            return NSLocalizedString("CategoriesSectionMapFilterVC", comment: "")
        } else if section == Sections.groups {
            return NSLocalizedString("GroupsSectionMapFilterVC", comment: "")
        } else if section == Sections.routeMode {
            return isRouteModeOn ? NSLocalizedString("RouteSectionMapFilterVC", comment: "") : nil
        } else {
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.categories {
            return CategoryUtils.localSearchCategories.count
        } else if section == Sections.groups {
            return groups.count
        } else if section == Sections.routeMode {
            return isRouteModeOn ? 1 : 0
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.categories {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.categoryCellId, for: indexPath) as! MapFilterCategoryTableViewCell
            
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            cell.initWith(category:category, isFiltered:filter.isFiletered(category: category))
            
            return cell
        } else if indexPath.section == Sections.groups {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.mapGroupFilterCellId, for: indexPath) as! MapFilterGroupTableViewCell

            cell.initWith(group:groups[indexPath.row])
            
            return cell
        } else if indexPath.section == Sections.routeMode {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.categoryCellId, for: indexPath) as! MapFilterCategoryTableViewCell
            cell.categoryImage.image = nil
            cell.categoryImage.isHidden = true
            cell.categoryLabel.text = NSLocalizedString("ShowPOIsNotUsedMapFilterVC", comment: "")
            cell.isFiltered = !showPOIsNotInRoute
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.categories {
            let cell = theTableView.cellForRow(at: indexPath) as! MapFilterCategoryTableViewCell
            
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            if filter.isFiletered(category: category) {
                filter.remove(category: category)
                cell.isFiltered = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.removeCategoryFromFilter), object: self, userInfo:[Notifications.categoryParameter.categoryName: category])
            } else {
                filter.add(category: category)
                cell.isFiltered = true
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.addCategoryToFilter), object: self, userInfo:[Notifications.categoryParameter.categoryName: category])
            }
        } else if indexPath.section == Sections.groups {
            let POIGroup = groups[indexPath.row]
            
            // Default group cannot be filtered
            if POIDataManager.sharedInstance.getDefaultGroup() != POIGroup {
                
                POIGroup.isGroupDisplayed = !POIGroup.isGroupDisplayed
                let cell = theTableView.cellForRow(at: indexPath) as! MapFilterGroupTableViewCell
                cell.initWith(group:groups[indexPath.row])
                
                // It will add/remove annotations from the Map, it can takes some times... so to no block
                // user we do it asynchronously
                DispatchQueue.main.async {
                    POIDataManager.sharedInstance.updatePOIGroup(POIGroup)
                    POIDataManager.sharedInstance.commitDatabase()
                }
            }
        } else if indexPath.section == Sections.routeMode {
            showPOIsNotInRoute = !showPOIsNotInRoute
            let cell = theTableView.cellForRow(at: indexPath) as! MapFilterCategoryTableViewCell
            cell.isFiltered = !showPOIsNotInRoute
            if showPOIsNotInRoute {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.showPOIsNotInRoute), object: self)
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.hidePOIsNotInRoute), object: self)
            }
        }
    }
}
