//
//  ImageAcvitityItemSource.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


class ImageAcvitityItemSource: NSObject, UIActivityItemSource {
    
    let imageContent:UIImage
    
    init(image:UIImage) {
        imageContent = image
    }
    
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return imageContent
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if activityType == UIActivityTypeMail {
            return imageContent
        } else {
            return nil
        }
    }
}