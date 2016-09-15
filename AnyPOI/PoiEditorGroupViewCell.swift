//
//  PoiEditorGroupViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 28/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class PoiEditorGroupViewCell: UITableViewCell {

    @IBOutlet weak var groupTitle: UILabel!
    
    @IBOutlet weak var groupColor: UIView!
    
    func initWith(group:GroupOfInterest) {
        groupTitle.text = group.groupDisplayName
        DrawingUtils.insertCircleForGroup(groupColor, fillColor:group.color)
    }

}

