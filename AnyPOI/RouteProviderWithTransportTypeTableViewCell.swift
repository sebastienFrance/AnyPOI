//
//  RouteProviderWithTransportTypeTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 02/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class RouteProviderWithTransportTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var navigationButton: UIButton!
    @IBOutlet weak var transportTypeSegment: UISegmentedControl!
    
    
    func initForAppleMaps(_ id:Int) {
        titleLabel.text = "Apple Maps"
        navigationButton.setImage(UIImage(named: "Apple Maps"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = false
        if transportTypeSegment.numberOfSegments == 4 {
            transportTypeSegment.removeSegment(at: 3, animated: false)
        }
    }
    
    func initForGoogleMaps(_ id:Int) {
        titleLabel.text = "Google Maps"
        navigationButton.setImage(UIImage(named: "Google_Maps"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = false
        if transportTypeSegment.numberOfSegments == 3 {
            transportTypeSegment.insertSegment(with: UIImage(named: "Bicycle-30"), at: 4, animated: false)
        }
  }
    
    func initForWaze(_ id:Int) {
        titleLabel.text = "Waze"
        navigationButton.setImage(UIImage(named: "Waze"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = true
   }
    
    func initForCityMapper(_ id:Int) {
        titleLabel.text = "City Mapper"
        navigationButton.setImage(UIImage(named: "CityMapper"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = true
   }
    
    func initForUber(_ id:Int) {
        titleLabel.text = "Uber"
        navigationButton.setImage(UIImage(named: "Google_Maps"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = true
  }
    

}
