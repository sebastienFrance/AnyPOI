//
//  WikipediaLocalSearchTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 31/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class WikipediaLocalSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var goToWikipedia: UIButton!
    @IBOutlet weak var extract: UILabel!

    func initWith(wikipedia:Wikipedia, index:Int) {
        title.text = wikipedia.title
        distance.text = "\(round(wikipedia.distance)) m"
        goToWikipedia.tag = index
        extract.text = wikipedia.extract
    }

}
