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
    
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return textMessageContent
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if activityType == UIActivityTypeMessage {
            return textMessageContent
        } else {
            return nil
        }
    }
}