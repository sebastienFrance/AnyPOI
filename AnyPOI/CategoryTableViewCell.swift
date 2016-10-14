//
//  CategoryTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 24/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {
    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryImageStackView: UIStackView!
    
    func initWithCategory(_ newCategory:Int) {
        if CategoryUtils.isEmptyCategory(newCategory) {
            categoryLabel?.text = NSLocalizedString("NoCategoryCategoryTableViewCell", comment: "")
            categoryImageStackView.isHidden = true
        } else {
            categoryLabel?.text = "\(CategoryUtils.getLabelCategoryForIndex(newCategory))"
            categoryImageStackView.isHidden = false
            categoryImage.image = CategoryUtils.getIconCategoryForIndex(newCategory)
            
        }
    }
}
