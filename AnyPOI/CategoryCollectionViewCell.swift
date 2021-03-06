//
//  CategoryCollectionViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    
    func initWith(category:CategoryUtils.Category) {
        iconImageView.image = category.icon
        iconLabel.text = category.localizedString
    }
    
    func highlight(isOn:Bool) {
        if isOn {
            layer.borderWidth = 2.0
            layer.borderColor = UIColor.blue.cgColor
        } else {
            layer.borderWidth = 0.0
        }
    }
}
