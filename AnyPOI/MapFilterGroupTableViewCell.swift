//
//  MapFilterGroupTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 20/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilterGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var groupDisplayName: UILabel!
    @IBOutlet weak var groupDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    func initWith(group:GroupOfInterest) {
        groupDisplayName.text = group.groupDisplayName
        groupDescription.text = group.groupDescription
        groupImage.image = group.iconImage
        
        if group.isGroupDisplayed {
            accessoryType = .checkmark
            groupDisplayName.textColor = UIColor.black
        } else {
            accessoryType = .none
            groupDisplayName.textColor = UIColor.red
        }
    }
}
