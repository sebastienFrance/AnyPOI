//
//  MovePOIsTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 19/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MovePOIsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var groupDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    func initWithGroup(_ group:GroupOfInterest) {
        groupName.text = group.groupDisplayName
        groupDescription.text = group.groupDescription
        groupImage.image = group.iconImage
    }
}
