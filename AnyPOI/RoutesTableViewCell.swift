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
    
    func initWith(_ theRoute:Route, index:Int) {
        routeName.text = theRoute.routeName
        fromTo.text = theRoute.localizedFromTo
        if theRoute.wayPoints.count == 0 {
            fromTo.textColor = UIColor.red
            distanceAndDuration.text = nil
        } else {
            fromTo.textColor = UIColor.black
            distanceAndDuration.text = theRoute.localizedDistanceAndTime 
        }
        editButton.tag = index
    }

}
