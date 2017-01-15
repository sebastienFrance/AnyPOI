//
//  GPXImportRouteTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 20/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXImportRouteTableViewCell: UITableViewCell {

    @IBOutlet weak var routeName: UILabel!
    @IBOutlet weak var routeFromTo: UILabel!
    @IBOutlet weak var routeDistanceAndDuration: UILabel!
    @IBOutlet weak var routeImportMode: UILabel!
    
    func initWith(route:GPXRoute, isRouteNew:Bool) {
       
        let actionColor = isRouteNew ? UIColor.red : UIColor.green
        let actionString = isRouteNew ? NSLocalizedString("GPXImportNewItem", comment: "") : NSLocalizedString("GPXImportUpdateItem", comment: "")
        
        routeName.attributedText = NSMutableAttributedString(string: route.routeName)
        routeFromTo.text = route.routeFromToDescription
        routeDistanceAndDuration.text = route.routeDistanceAndDuration
        routeImportMode.attributedText = NSAttributedString(string: actionString,
                                                           attributes:[NSForegroundColorAttributeName : actionColor,
                                                                       NSFontAttributeName : UIFont.boldSystemFont(ofSize: routeFromTo.font.pointSize)])
    }
}
