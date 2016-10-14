//
//  POISimpleViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts

class POISimpleViewCell: UITableViewCell {

    @IBOutlet weak var POITitle: UILabel!
    @IBOutlet weak var POIDescription: UILabel!
    @IBOutlet weak var POIAddress: UILabel!
    @IBOutlet weak var POICategoryImage: UIImageView!
    
    @IBOutlet weak var groupImage: UIImageView!

    @IBOutlet weak var POICategoryImageHeight: NSLayoutConstraint!
    @IBOutlet weak var POICategoryImageWidth: NSLayoutConstraint!
    

    func initializeWith(_ poi:PointOfInterest, index:Int) {
        POITitle.text = poi.poiDisplayName
        POIDescription.text = poi.poiDescription
        POIAddress.text = poi.address
        groupImage.image = poi.parentGroup!.iconImage
        if poi.poiIsContact {
            POICategoryImage.isHidden = true
//            let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!)
//            initImageWithContact(contact)
        } else {
            if let image = poi.categoryIcon {
                POICategoryImage.image = image
                POICategoryImageWidth.constant = 25.0
                POICategoryImageHeight.constant = 25.0
                POICategoryImage.tintColor = UIColor.black
                POICategoryImage.isHidden = false
            } else {
                POICategoryImage.isHidden = true
            }
        }
    }
    
    
    func initializeWith(_ poi:PointOfInterest, index:Int, image:UIImage) {
        POITitle.text = poi.poiDisplayName
        POIDescription.text = poi.poiDescription
        POIAddress.text = poi.address
        
        groupImage.image = poi.parentGroup!.iconImage

        
        self.POICategoryImage.isHidden = false
        self.POICategoryImage.image = image
        self.POICategoryImageHeight.constant = 70
        self.POICategoryImageWidth.constant = 70
    }
    
    func initImageWithContact(_ contact:CNContact?) {
        if let theContact = contact {
            if theContact.imageDataAvailable {
                if let thumbail = theContact.thumbnailImageData {
                    self.POICategoryImage.isHidden = false
                    self.POICategoryImage.image = UIImage(data: thumbail)
                    self.POICategoryImageHeight.constant = 70
                    self.POICategoryImageWidth.constant = 70
                } else {
                    self.POICategoryImage.isHidden = true
                }
            } else {
                self.POICategoryImage.isHidden = true
            }
        }
    }
}
