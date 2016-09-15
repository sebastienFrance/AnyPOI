//
//  RoutesTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 26/06/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class RoutesTableViewCell: UITableViewCell {

    @IBOutlet weak var routeName: UILabel!
    @IBOutlet weak var fromTo: UILabel!
    @IBOutlet weak var distanceAndDuration: UILabel!

    @IBOutlet weak var editButton: UIButton!
    
    func initWith(theRoute:Route, index:Int) {
        routeName.text = theRoute.routeName
        fromTo.text = theRoute.routeDescription
        if theRoute.wayPoints.count == 0 {
            fromTo.textColor = UIColor.redColor()
            distanceAndDuration.text = nil
        } else {
            fromTo.textColor = UIColor.blackColor()
            distanceAndDuration.text = theRoute.latestFullRouteDistanceAndTime + " with \(theRoute.wayPoints.count) steps"
        }
        editButton.tag = index
    }

}
