//
//  MapFilterCategoryTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 12/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilterCategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!

    var isFiltered:Bool {
        get {
            return accessoryType == .none
        }
        set {
            accessoryType = newValue ? .none : .checkmark
        }
    }
    
    
    func initWith(category:CategoryUtils.Category, isFiltered:Bool) {
        categoryImage.image = category.icon
        categoryLabel.text = category.localizedString
        
        self.isFiltered = isFiltered
    }
    
}
