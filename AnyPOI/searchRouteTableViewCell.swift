//
//  searchRouteTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 21/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class searchRouteTableViewCell: UITableViewCell {

    @IBOutlet weak var routeName: UILabel!
    @IBOutlet weak var fromTo: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func initWith(route:Route) {
        routeName.text = route.routeName
        if let startDisplayName = route.startWayPoint?.wayPointPoi?.poiDisplayName,
            endDisplayName = route.endWayPoint?.wayPointPoi?.poiDisplayName {
            fromTo.text = startDisplayName + " to " + endDisplayName
        } else {
            fromTo.text = "No waypoints"
        }
    }
}
