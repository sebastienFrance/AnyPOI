//
//  MessageActivityItemSource.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 03/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MessageActivityItemSource: NSObject, UIActivityItemSource {
    
    let textMessageContent:String
    
    init(messageContent:String) {
        textMessageContent = messageContent
    }
    
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return textMessageContent
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        if let theActivityType = activityType, theActivityType == UIActivityType.message {
            return textMessageContent
        } else {
            return nil
        }
    }
}
