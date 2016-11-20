//
//  POIGroupCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit

class POIGroupCell: UITableViewCell {

    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var groupDescription: UILabel!
 
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var groupImage: UIImageView!
    
    func initWithGroup(_ group:GroupOfInterest, index:Int) {
        groupName.text = group.groupDisplayName
        groupDescription.text = group.groupDescription
        editButton.tag = index
        groupImage.image = group.iconImage
    }
}
