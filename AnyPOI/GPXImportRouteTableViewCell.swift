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
    
    func initWith(route:GPXRoute) {
        if route.isRouteAlreadyExist {
           routeName.text = "\(route.routeName) (update)"
        } else {
            routeName.text = "\(route.routeName) (new)"
        }
        
        routeFromTo.text = route.routeFromToDescription
        routeDistanceAndDuration.text = route.routeDistanceAndDuration
    }
}
