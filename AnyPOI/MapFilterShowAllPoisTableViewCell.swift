//
//  MaFilterShowAllPoisTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 29/01/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilterShowAllPoisTableViewCell: UITableViewCell {

    @IBOutlet weak var theTitle: UILabel! {
        didSet {
            theTitle.text = NSLocalizedString("MapFilterShowAllPoisTitle", comment: "")
        }
    }
    @IBOutlet weak var theDescription: UILabel! {
        didSet {
            theDescription.text = NSLocalizedString("MapFilterShowAllPoisDescription", comment: "")
        }
    }

    var isFiltered:Bool {
        get {
            return accessoryType == .none
        }
        set {
            accessoryType = newValue ? .none : .checkmark
            theTitle.textColor = newValue ? UIColor.red : UIColor.black
        }
    }
    
    func initWith(showPOIsNotInRoute:Bool) {
        isFiltered = !showPOIsNotInRoute
    }


}
