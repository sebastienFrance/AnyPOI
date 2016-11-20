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
        static let categoryParameter = "category"
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
        static let categories = 0
        static let groups = 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.categories {
            return "Categories"
        } else {
            return "Groups"
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == Sections.categories ? CategoryUtils.localSearchCategories.count : groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.categories {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.categoryCellId, for: indexPath) as! MapFilterCategoryTableViewCell
            
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            cell.initWith(category:category, isFiltered:filter.isFiletered(category: category))
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId.mapGroupFilterCellId, for: indexPath) as! MapFilterGroupTableViewCell

            cell.initWith(group:groups[indexPath.row])
            
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.categories {
            let cell = theTableView.cellForRow(at: indexPath) as! MapFilterCategoryTableViewCell
            
            let category = CategoryUtils.localSearchCategories[indexPath.row]
            if filter.isFiletered(category: category) {
                filter.remove(category: category)
                cell.isFiltered = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.removeCategoryFromFilter), object: self, userInfo:[Notifications.categoryParameter: category])
            } else {
                filter.add(category: category)
                cell.isFiltered = true
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.addCategoryToFilter), object: self, userInfo:[Notifications.categoryParameter: category])
            }
        } else {
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

        }
    }
}
