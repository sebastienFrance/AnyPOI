//
//  LocationCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 08/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class LocationCell: UITableViewCell {

    @IBOutlet weak var street: UILabel!
    @IBOutlet weak var poiCategoryImage: UIImageView!
    @IBOutlet weak var poiCategoryHeight: NSLayoutConstraint!
    @IBOutlet weak var poiCategoryWidth: NSLayoutConstraint!

    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    @IBOutlet weak var phoneNumberButton: UIButton!
    @IBOutlet weak var phoneNumberImageView: UIImageView!
    @IBOutlet weak var urlButton: UIButton!

    @IBOutlet weak var showContactDetailsButton: UIButton!
    
    
    private func initPhoneNumber(phoneNumber:String?) {
        if let thePhoneNumber = phoneNumber {
            enablePhoneNumber(thePhoneNumber)
        } else {
            disablePhoneNumber()
        }
    }
    
    private func enablePhoneNumber(phoneNumber:String) {
        phoneNumberButton.setTitle(phoneNumber, forState: .Normal)
        phoneNumberButton.enabled = true
        phoneNumberImageView.hidden = false
    }
    
    private func disablePhoneNumber() {
        phoneNumberButton.enabled = false
        phoneNumberButton.hidden = true
        phoneNumberImageView.hidden = true
    }
    
    private func initURL(url:String?) {
        if url != nil {
            enableURL()
        } else {
            disableURL()
        }
    }
    private func enableURL() {
        urlButton.enabled = true
        urlButton.hidden = false
    }
    private func disableURL() {
        urlButton.enabled = false
        urlButton.hidden = true
        
    }

    
    func buildWith(poi:PointOfInterest) {
        street.text = poi.address
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.blackColor()
            poiCategoryWidth.constant = 25
            poiCategoryHeight.constant = 25
            poiCategoryImage.hidden = false
        } else {
            poiCategoryImage.hidden = true
        }
        
        poiDescription.text = poi.poiDescription
        if let group = poi.parentGroup {
            groupName.text = group.groupDisplayName
            groupImage.image = group.iconImage
        } else {
            groupName.text = "No group!"
        }
        
        showContactDetailsButton.hidden = true

        initPhoneNumber(poi.poiPhoneNumber)
        initURL(poi.poiURL)
    }
    
    

    func buildWith(poi:PointOfInterest, contact:CNContact?) {
        street.text = poi.address
        poiDescription.text = poi.poiDescription

        if let group = poi.parentGroup {
            groupName.text = group.groupDisplayName
            groupImage.image = group.iconImage
        } else {
            groupName.text = "No group!"
        }
        
        if let theContact = contact {
            showContactDetailsButton.hidden = false

            
            if let phoneNumber = ContactsUtilities.extractPhoneNumber(theContact) {
                enablePhoneNumber(phoneNumber.stringValue)
            } else {
                disablePhoneNumber()
            }
            
            initURL(ContactsUtilities.extractURL(theContact))
           
            if theContact.imageDataAvailable {
                if let thumbail = theContact.thumbnailImageData {
                    poiCategoryImage.hidden = false
                    poiCategoryImage.image = UIImage(data: thumbail)
                    poiCategoryWidth.constant = 70
                    poiCategoryHeight.constant = 70
                } else {
                    poiCategoryImage.hidden = true
                }
            } else {
                poiCategoryImage.hidden = true
            }
            
        } else {
            disablePhoneNumber()
            disableURL()
            poiCategoryImage.hidden = true
        }
    }

}
