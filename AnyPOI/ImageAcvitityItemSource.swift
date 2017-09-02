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
    
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return imageContent
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        if let theActivityType = activityType, theActivityType == UIActivityType.mail {
            return imageContent
        } else {
            return nil
        }
    }
}
