//
//  LocationCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class LocationCell: UITableViewCell {

    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var poiCategoryImage: UIImageView!

    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var poiDescription: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var mailWidth: NSLayoutConstraint!
    @IBOutlet weak var phoneNumberButton: UIButton!
    @IBOutlet weak var phoneWidth: NSLayoutConstraint!
    @IBOutlet weak var urlButton: UIButton!
    @IBOutlet weak var urlWidth: NSLayoutConstraint!

    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var showContactDetailsButton: UIButton!
    @IBOutlet weak var showContactWidth: NSLayoutConstraint!
    
    func buildWith(_ poi:PointOfInterest) {
        configureGeneralInfo(poi)
        
        poiCategoryImage.image = poi.imageForType

        // Hide all buttons not used when the POI is not related to a contact
        showContactDetailsButton.isHidden = true
        showContactWidth.constant = 0
        
        mailButton.isEnabled = false
        mailButton.isHidden = true
        mailWidth.constant = 0

        if poi.poiPhoneNumber != nil {
            phoneNumberButton.isEnabled = true
            phoneNumberButton.isHidden = false
            phoneWidth.constant = 40.0
        } else {
            phoneNumberButton.isEnabled = false
            phoneNumberButton.isHidden = true
            phoneWidth.constant = 0
        }
        
        configureURL(poi.poiURL)
        configureCategory(poi:poi)
    }
    
    

    func buildWith(_ poi:PointOfInterest, contact:CNContact) {
        configureGeneralInfo(poi)
        configurePhone(contact)
        configureURL(ContactsUtilities.extractURL(contact))
        configureThumbail(poi:poi, contact:contact)
        configureEmail(contact)
        showContactDetailsButton.isHidden = false
        showContactWidth.constant = 40.0
        configureCategory(poi:poi)
    }
    
    fileprivate func configureCategory(poi:PointOfInterest) {
        if let image = poi.categoryIcon {
            categoryImage.image = image
            categoryImage.tintColor = UIColor.black
            categoryImage.isHidden = false
        } else {
            categoryImage.isHidden = true
        }
    }

    
    fileprivate func configureGeneralInfo(_ poi:PointOfInterest) {
        addressTextView.text = poi.address
        poiDescription.text = poi.poiDescription
        
        if let group = poi.parentGroup {
            groupName.text = group.groupDisplayName
            groupImage.image = group.iconImage
        } else {
            groupName.text = "No group!"
        }
        
    }

    fileprivate func configureThumbail(poi:PointOfInterest, contact:CNContact) {
        if contact.imageDataAvailable, let thumbail = contact.thumbnailImageData {
            poiCategoryImage.image = UIImage(data: thumbail)
        } else {
            poiCategoryImage.image = poi.imageForType
        }
    }
    
    fileprivate func configurePhone(_ contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            if contact.phoneNumbers.count > 1 {
                phoneNumberButton.setImage(UIImage(named: Utilities.IconName.severalsPhoneNumbers), for: UIControlState())
            } else {
                phoneNumberButton.setImage(UIImage(named: Utilities.IconName.phoneNumber), for: UIControlState())
            }
            
            phoneNumberButton.isEnabled = true
            phoneNumberButton.isHidden = false
            phoneWidth.constant = 40.0
        } else {
            phoneNumberButton.isEnabled = false
            phoneNumberButton.isHidden = true
            phoneWidth.constant = 0
        }
    }
    
    fileprivate func configureEmail(_ contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            mailButton.isEnabled = false
            mailButton.isHidden = true
            mailWidth.constant = 0
        } else {
            if contact.emailAddresses.count > 1 {
                mailButton.setImage(UIImage(named: Utilities.IconName.severalseMailsAddress), for: UIControlState())
            } else {
                mailButton.setImage(UIImage(named: Utilities.IconName.eMailAddress), for: UIControlState())
            }
            
            mailButton.isEnabled = true
            mailButton.isHidden = false
            mailWidth.constant = 40.0
        }
    }
    
    fileprivate func configureURL(_ url:String?) {
        if url != nil {
            urlButton.isEnabled = true
            urlButton.isHidden = false
            urlWidth.constant = 40.0
        } else {
            urlButton.isEnabled = false
            urlButton.isHidden = true
            urlWidth.constant = 0
        }
    }
}
