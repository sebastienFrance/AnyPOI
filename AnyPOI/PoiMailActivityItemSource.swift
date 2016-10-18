//
//  MailActivityItemSource.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 03/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


class PoiMailActivityItemSource: NSObject, UIActivityItemSource {
    
    
    let poi:PointOfInterest
    
    init(poi:PointOfInterest) {
        self.poi = poi
    }
    
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return ""
    }
    
     func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
     func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if activityType == UIActivityType.mail  {
            return HTMLAnyPoi.appendCSSAndSignature(html: poi.toHTML())
        } else {
            return nil
        }
    }
}
