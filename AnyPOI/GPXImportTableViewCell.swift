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
    
    func initWith(poi:GPXPoi, updatedPoi:Bool) {
        let attributedText = NSMutableAttributedString(string: "\(poi.poiName) ")
        var actionString = "(update)"
        var actionColor = UIColor.green
        if !updatedPoi {
            actionColor = UIColor.red
            actionString = "(new)"
        }
        
        attributedText.append(NSAttributedString(string: actionString,
                                                 attributes:[NSForegroundColorAttributeName : actionColor,
                                                             NSFontAttributeName : UIFont.boldSystemFont(ofSize: poiDisplayName.font.pointSize)]))

        poiDisplayName.attributedText = attributedText
        poiDescription.text = poi.poiDescription
        poiImageCategory.image = poi.poiCategory.icon
    }
}
