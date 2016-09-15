//
//  searchGroupViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 11/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class searchGroupViewCell: UITableViewCell {

    @IBOutlet weak var groupTitle: UILabel!
    @IBOutlet weak var groupDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    @IBOutlet weak var showGroupContentButton: UIButton!
    @IBOutlet weak var editGroupButton: UIButton!

    func initWith(group:GroupOfInterest, index:Int) {
        groupTitle.text = group.groupDisplayName
        groupDescription.text = group.groupDescription
        showGroupContentButton.tag = index
        editGroupButton.tag = index
        groupImage.image = group.iconImage
    }
}
