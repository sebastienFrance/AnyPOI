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
    @IBOutlet weak var addWikipediaPOI: UIButton!
    @IBOutlet weak var extract: UILabel!
    
    
    func initWith(wikipedia:Wikipedia, poi:PointOfInterest, index:Int) {
        title.text = wikipedia.title
        distance.text = "\(round(wikipedia.distance)) m"
        goToWikipedia.tag = index
        addWikipediaPOI.tag = index
        
        let poiOfWiki = POIDataManager.sharedInstance.findPOIWith(wikipedia)
        
        var isWikipediaPOI = false
        if let theWikipediaPOI = poiOfWiki {
            addWikipediaPOI.enabled = false
            if theWikipediaPOI == poi {
                isWikipediaPOI = true
            }
        } else {
            addWikipediaPOI.enabled = true
        }
        
        
        title.textColor = isWikipediaPOI ? UIColor.greenColor() : UIColor.blackColor()
        extract.text = wikipedia.extract
    }
    
 }
