//
//  GPXImportTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 30/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXImportTableViewCell: UITableViewCell {

    @IBOutlet weak var poiDisplayName: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var poiImageCategory: UIImageView!
    @IBOutlet weak var poiImportMode: UILabel!
    
    func initWith(poi:GPXPoi, isPOINew:Bool) {
        let actionString = isPOINew ? NSLocalizedString("GPXImportNewItem", comment: "") : NSLocalizedString("GPXImportUpdateItem", comment: "")
        let actionColor = isPOINew ? UIColor.red : UIColor.green
        
        poiDisplayName.attributedText = NSMutableAttributedString(string: "\(poi.poiName) ")
        poiDescription.text = poi.poiDescription
        poiImageCategory.image = poi.poiCategory.icon
        poiImportMode.attributedText = NSAttributedString(string: actionString, attributes: [NSAttributedStringKey.foregroundColor : actionColor,
                                                                                             NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: poiDisplayName.font.pointSize)])
    }
}
