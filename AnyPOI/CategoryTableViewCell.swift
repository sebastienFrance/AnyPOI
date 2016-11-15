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
    
    
    func initWith(category:CategoryUtils.Category) {
        categoryLabel?.text = category.localizedString
        categoryImage.image = category.icon
    }

}
