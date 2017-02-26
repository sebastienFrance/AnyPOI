//
//  WikipediaCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 24/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class WikipediaCell: UITableViewCell {

    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var title: UILabel!

    @IBOutlet weak var goToWikipedia: UIButton!
    @IBOutlet weak var extract: UILabel!
    
    
    func initWith(_ wikipedia:Wikipedia, poi:PointOfInterest, index:Int) {
        title.text = wikipedia.title
        distance.text = "\(round(wikipedia.distance)) m"
        goToWikipedia.tag = index
        
        let poiOfWiki = POIDataManager.sharedInstance.findPOIWith(wikipedia)
        let isWikipediaPOI = poiOfWiki === poi ? true : false
        
        title.textColor = isWikipediaPOI ? UIColor.red : UIColor.black
        extract.text = wikipedia.extract
    }
    
 }
