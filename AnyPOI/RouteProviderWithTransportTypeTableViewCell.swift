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
        navigationButton.setImage(#imageLiteral(resourceName: "Apple Maps"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = false
        
        transportTypeSegment.removeAllSegments()
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Sedan-30"), at: 1, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Walking-30"), at: 2, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "City Railway Station-30"), at: 3, animated: false)
        transportTypeSegment.selectedSegmentIndex = 0
    }
    
    func initForGoogleMaps(_ id:Int) {
        titleLabel.text = "Google Maps"
        navigationButton.setImage(#imageLiteral(resourceName: "Google_Maps"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = false
        
        transportTypeSegment.removeAllSegments()
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Sedan-30"), at: 1, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Walking-30"), at: 2, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "City Railway Station-30"), at: 3, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Bicycle-30"), at: 4, animated: false)
        transportTypeSegment.selectedSegmentIndex = 0
    }
    
    func initForHereMaps(_ id:Int) {
        titleLabel.text = "Here Maps"
        navigationButton.setImage(#imageLiteral(resourceName: "mapHere"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        
        transportTypeSegment.isHidden = false
        transportTypeSegment.removeAllSegments()
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Sedan-30"), at: 1, animated: false)
        transportTypeSegment.insertSegment(with: #imageLiteral(resourceName: "Walking-30"), at: 2, animated: false)
        transportTypeSegment.selectedSegmentIndex = 0
    }

    
    func initForWaze(_ id:Int) {
        titleLabel.text = "Waze"
        navigationButton.setImage(#imageLiteral(resourceName: "Waze"), for: UIControlState())
        transportTypeSegment.tag = id
        navigationButton.tag = id
        transportTypeSegment.isHidden = true
   }
    
    func initForCityMapper(_ id:Int) {
        titleLabel.text = "City Mapper"
        navigationButton.setImage(#imageLiteral(resourceName: "CityMapper"), for: UIControlState())
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
