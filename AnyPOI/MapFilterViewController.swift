//
//  MapFilterViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 12/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilterViewController: UIViewController {

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
    
    let filter = MapFilter()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension MapFilterViewController : UITableViewDelegate, UITableViewDataSource {

    struct storyboard {
        static let categoryCellId = "MapFilterCategoryCellId"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CategoryUtils.localSearchCategories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: storyboard.categoryCellId, for: indexPath) as! MapFilterCategoryTableViewCell
        let category = CategoryUtils.localSearchCategories[indexPath.row]
        cell.categoryImage.image = category.icon
        cell.categoryLabel.text = category.localizedString
        
        if filter.isFiletered(category: Int16(indexPath.row)) {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = theTableView.cellForRow(at: indexPath)
        if filter.isFiletered(category: Int16(indexPath.row)) {
            filter.remove(category: Int16(indexPath.row))
            cell?.accessoryType = .checkmark
        } else {
            filter.add(category: Int16(indexPath.row))
            cell?.accessoryType = .none
        }
    }
}
