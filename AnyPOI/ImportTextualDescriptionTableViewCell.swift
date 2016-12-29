//
//  ImportTextualDescriptionTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class ImportTextualDescriptionTableViewCell: UITableViewCell {

    @IBOutlet weak var texttualDescriptionLabel: UILabel!
    
    func initWith(importOptions:GPXImportOptions, isRouteEnabled:Bool) {
        let descriptionString = NSMutableAttributedString()
        
        if isRouteEnabled {
            descriptionString.append(NSAttributedString(string: NSLocalizedString("Routes", comment: ""), attributes: [NSForegroundColorAttributeName : UIColor.blue]))
            descriptionString.append(NSAttributedString(string:": ", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
            descriptionString.append(importOptions.routeTextualDescription)
            descriptionString.append(NSAttributedString(string:"\n"))
        }
        
        descriptionString.append(NSAttributedString(string: NSLocalizedString("Points of interests", comment: ""), attributes: [NSForegroundColorAttributeName : UIColor.blue]))
        descriptionString.append(NSAttributedString(string:": ", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
        descriptionString.append(importOptions.poiTextualDescription)
        
        texttualDescriptionLabel?.attributedText = descriptionString
    }
}
