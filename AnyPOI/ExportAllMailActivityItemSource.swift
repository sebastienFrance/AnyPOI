//
//  ExportAllMailActivityItemSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 19/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class ExportAllMailActivityItemSource: NSObject, UIActivityItemSource {
    
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return NSLocalizedString("ExportAllTitle", comment: "")
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        if let theActivityType = activityType {
            if theActivityType == UIActivityType.mail {
                return HTMLAnyPoi.appendCSSAndSignature(html: "<p>\(NSLocalizedString("ExportAllMsgDescription", comment: ""))</p>")
            } else if theActivityType.rawValue == HTMLAnyPoi.readdleSparkActivity  {
                return HTMLAnyPoi.appendCSSAndSignatureForReaddleSpark(html: "<p>\(NSLocalizedString("ExportAllMsgDescription", comment: ""))</p>")
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
