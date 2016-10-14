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
    
    
     func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return htmlMailContent
    }
    
     func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if activityType == UIActivityType.mail {
            return htmlMailContent
        } else {
            return nil
        }
    }
}
