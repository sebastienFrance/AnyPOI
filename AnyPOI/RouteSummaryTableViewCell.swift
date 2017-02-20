//
//  RouteSummaryTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 21/03/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class RouteSummaryTableViewCell: UITableViewCell {

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var totalDistanceAndDurationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func initWith(route:Route) {
        if route.wayPoints.count <= 1 {
            fromLabel.text = NSLocalizedString("RouteSummaryTableRouteIsEmpty", comment: "")
            totalDistanceAndDurationLabel.text = ""
        } else {
            fromLabel.text = route.localizedFromTo
            totalDistanceAndDurationLabel.text = route.localizedDistanceAndTime
        }
    }
}
