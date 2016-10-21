//
//  LeftMenuPOIsTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 21/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class LeftMenuPOIsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var menuTitle: UILabel!
    @IBOutlet weak var pinView: MKPinAnnotationView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
        // Configure the view for the selected state
    }
    
}
