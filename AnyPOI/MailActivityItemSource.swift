//
//  MailActivityItemSource.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 03/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


class MailActivityItemSource: NSObject, UIActivityItemSource {
    
    let htmlMailContent:String
    
    init(mailContent:String) {
        htmlMailContent = mailContent
    }
    
    
     func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return htmlMailContent
    }
    
     func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if activityType == UIActivityTypeMail {
            return htmlMailContent
        } else {
            return nil
        }
    }
}