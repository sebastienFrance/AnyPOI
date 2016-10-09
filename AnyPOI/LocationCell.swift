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

    //@IBOutlet weak var street: UILabel!

    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var poiCategoryImage: UIImageView!
    @IBOutlet weak var poiCategoryHeight: NSLayoutConstraint!
    @IBOutlet weak var poiCategoryWidth: NSLayoutConstraint!

    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var phoneNumberButton: UIButton!
    @IBOutlet weak var urlButton: UIButton!

    @IBOutlet weak var showContactDetailsButton: UIButton!
    
    func buildWith(poi:PointOfInterest) {
        configureGeneralInfo(poi)
        configureCategory(poi)
        
        showContactDetailsButton.hidden = true
        
        mailButton.enabled = false
        mailButton.hidden = true

        if poi.poiPhoneNumber != nil {
            phoneNumberButton.enabled = true
            phoneNumberButton.hidden = false
        } else {
            phoneNumberButton.enabled = false
            phoneNumberButton.hidden = true
        }
        
        configureURL(poi.poiURL)
    }
    

    func buildWith(poi:PointOfInterest, contact:CNContact) {
        configureGeneralInfo(poi)
        configurePhone(contact)
        configureURL(ContactsUtilities.extractURL(contact))
        configureThumbail(contact)
        configureEmail(contact)
        showContactDetailsButton.hidden = false
    }
    
    private func configureCategory(poi:PointOfInterest) {
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.blackColor()
            poiCategoryWidth.constant = 25
            poiCategoryHeight.constant = 25
            poiCategoryImage.hidden = false
        } else {
            poiCategoryImage.hidden = true
        }

    }
    
    private func configureGeneralInfo(poi:PointOfInterest) {
        addressTextView.text = poi.address
        poiDescription.text = poi.poiDescription
        
        
        if let group = poi.parentGroup {
            groupName.text = group.groupDisplayName
            groupImage.image = group.iconImage
        } else {
            groupName.text = "No group!"
        }
        
    }

    private func configureThumbail(contact:CNContact) {
        if contact.imageDataAvailable {
            if let thumbail = contact.thumbnailImageData {
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
    }
    
    private func configurePhone(contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            if contact.phoneNumbers.count > 1 {
                phoneNumberButton.setImage(UIImage(named: "PhoneSeverals Filled-40"), forState: .Normal)
            } else {
                phoneNumberButton.setImage(UIImage(named: "Phone Filled-40"), forState: .Normal)
            }
            
            phoneNumberButton.enabled = true
            phoneNumberButton.hidden = false
        } else {
            phoneNumberButton.enabled = false
            phoneNumberButton.hidden = true
        }
    }
    
    private func configureEmail(contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            mailButton.enabled = false
            mailButton.hidden = true
        } else {
            if contact.emailAddresses.count > 1 {
                mailButton.setImage(UIImage(named: "MessageSeverals-40"), forState: .Normal)
            } else {
                mailButton.setImage(UIImage(named: "Message-40"), forState: .Normal)
            }
            
            mailButton.enabled = true
            mailButton.hidden = false
        }
    }
    
    private func configureURL(url:String?) {
        if url != nil {
            urlButton.enabled = true
            urlButton.hidden = false
        } else {
            urlButton.enabled = false
            urlButton.hidden = true
        }
    }


}
