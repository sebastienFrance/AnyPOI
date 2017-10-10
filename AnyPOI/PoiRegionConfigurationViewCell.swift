//
//  PoiRegionConfigurationViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 26/03/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class PoiRegionConfigurationViewCell: UITableViewCell {

    @IBOutlet weak var switchEnterRegion: UISwitch!
    @IBOutlet weak var switchExitRegion: UISwitch!

    @IBOutlet weak var slideRadius: UISlider!
    @IBOutlet weak var radiusLabel: UILabel!
    
    @IBOutlet weak var regionMonitoringDisabledLabel: UILabel!
    func initWith(_ enterRegion:Bool, exitRegion:Bool, radius:Double) {
        switchEnterRegion.isOn = enterRegion
        switchExitRegion.isOn = exitRegion


        if !switchExitRegion.isOn && !switchEnterRegion.isOn {
            slideRadius.isEnabled = false
        } else {
            slideRadius.isEnabled = true
        }

        radiusLabel.text = "\(NSLocalizedString("Radius", comment: "")) \(Int(radius)) m"
        slideRadius.setValue(Float(radius), animated: false)
        slideRadius.isContinuous = true
        
        regionMonitoringDisabledLabel.text = NSLocalizedString("POISettingEnableAlways", comment:"")
        
        if !LocationManager.sharedInstance.isRegionMonitoringAuthorized() {
            regionMonitoringDisabledLabel.isHidden = false
        } else {
            regionMonitoringDisabledLabel.isHidden = true
        }
        
    }
}
