//
//  PickerCategoryView.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class PickerCategoryView: UIView {

    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!

    func initWith(category:CategoryUtils.Category) {
        categoryImage.image = category.icon
        categoryLabel.text = category.localizedString
    }
}
