//
//  PoisMailActivityItemSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
class PoisMailActivityItemSource: NSObject, UIActivityItemSource {
    
    
    let pois:[PointOfInterest]
    
    init(pois:[PointOfInterest]) {
        self.pois = pois
    }
    
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return ""
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if activityType == UIActivityType.mail  {
            return HTMLAnyPoi.appendCSSAndSignature(html:PointOfInterest.toHTML(pois:pois))
        } else {
            return nil
        }
    }
}
