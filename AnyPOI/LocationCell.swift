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
    
    func buildWith(_ poi:PointOfInterest) {
        configureGeneralInfo(poi)
        configureCategory(poi)
        
        showContactDetailsButton.isHidden = true
        
        mailButton.isEnabled = false
        mailButton.isHidden = true

        if poi.poiPhoneNumber != nil {
            phoneNumberButton.isEnabled = true
            phoneNumberButton.isHidden = false
        } else {
            phoneNumberButton.isEnabled = false
            phoneNumberButton.isHidden = true
        }
        
        configureURL(poi.poiURL)
    }
    

    func buildWith(_ poi:PointOfInterest, contact:CNContact) {
        configureGeneralInfo(poi)
        configurePhone(contact)
        configureURL(ContactsUtilities.extractURL(contact))
        configureThumbail(contact)
        configureEmail(contact)
        showContactDetailsButton.isHidden = false
    }
    
    fileprivate func configureCategory(_ poi:PointOfInterest) {
        if let image = poi.categoryIcon {
            poiCategoryImage.image = image
            poiCategoryImage.tintColor = UIColor.black
            poiCategoryWidth.constant = 25
            poiCategoryHeight.constant = 25
            poiCategoryImage.isHidden = false
        } else {
            poiCategoryImage.isHidden = true
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

    fileprivate func configureThumbail(_ contact:CNContact) {
        if contact.imageDataAvailable {
            if let thumbail = contact.thumbnailImageData {
                poiCategoryImage.isHidden = false
                poiCategoryImage.image = UIImage(data: thumbail)
                poiCategoryWidth.constant = 70
                poiCategoryHeight.constant = 70
            } else {
                poiCategoryImage.isHidden = true
            }
        } else {
            poiCategoryImage.isHidden = true
        }
    }
    
    fileprivate func configurePhone(_ contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            if contact.phoneNumbers.count > 1 {
                phoneNumberButton.setImage(UIImage(named: "PhoneSeverals Filled-40"), for: UIControlState())
            } else {
                phoneNumberButton.setImage(UIImage(named: "Phone Filled-40"), for: UIControlState())
            }
            
            phoneNumberButton.isEnabled = true
            phoneNumberButton.isHidden = false
        } else {
            phoneNumberButton.isEnabled = false
            phoneNumberButton.isHidden = true
        }
    }
    
    fileprivate func configureEmail(_ contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            mailButton.isEnabled = false
            mailButton.isHidden = true
        } else {
            if contact.emailAddresses.count > 1 {
                mailButton.setImage(UIImage(named: "MessageSeverals-40"), for: UIControlState())
            } else {
                mailButton.setImage(UIImage(named: "Message-40"), for: UIControlState())
            }
            
            mailButton.isEnabled = true
            mailButton.isHidden = false
        }
    }
    
    fileprivate func configureURL(_ url:String?) {
        if url != nil {
            urlButton.isEnabled = true
            urlButton.isHidden = false
        } else {
            urlButton.isEnabled = false
            urlButton.isHidden = true
        }
    }


}
