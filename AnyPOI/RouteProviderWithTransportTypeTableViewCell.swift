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
    
    
    func initForAppleMaps(id:Int) {
        titleLabel.text = "Apple Maps"
        navigationButton.setImage(UIImage(named: "Apple Maps"), forState: .Normal)
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.hidden = false
        if transportTypeSegment.numberOfSegments == 4 {
            transportTypeSegment.removeSegmentAtIndex(3, animated: false)
        }
    }
    
    func initForGoogleMaps(id:Int) {
        titleLabel.text = "Google Maps"
        navigationButton.setImage(UIImage(named: "Google_Maps"), forState: .Normal)
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.hidden = false
        if transportTypeSegment.numberOfSegments == 3 {
            transportTypeSegment.insertSegmentWithImage(UIImage(named: "Bicycle-40"), atIndex: 4, animated: false)
        }
  }
    
    func initForWaze(id:Int) {
        titleLabel.text = "Waze"
        navigationButton.setImage(UIImage(named: "Waze"), forState: .Normal)
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.hidden = true
   }
    
    func initForCityMapper(id:Int) {
        titleLabel.text = "City Mapper"
        navigationButton.setImage(UIImage(named: "CityMapper"), forState: .Normal)
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.hidden = true
   }
    
    func initForUber(id:Int) {
        titleLabel.text = "Uber"
        navigationButton.setImage(UIImage(named: "Google_Maps"), forState: .Normal)
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.hidden = true
  }
    

}
