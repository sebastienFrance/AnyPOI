//
//  CustomCalloutAccessoryView.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import MapKit

class CustomCalloutAccessoryView: UIView {

    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryImageHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var categoryImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var flyoverButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var startStopMonitoring: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var navigationStackView: UIStackView!

    @IBOutlet weak var actionsStackView: UIStackView!
    
    fileprivate(set) var URL:String?
    fileprivate(set) var phoneNumber:String?
    
    fileprivate struct ImageName {
        static let monitoringEnabled = "Circled Dot Minus-40"
        static let monitoringDisabled = "Circled Dot Plus-40"
    }
    
    func initWith(_ poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        
        // Delegate will never change, it can be initialized once for all
        flyoverButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.zoomOnPoi(_:)), for: .touchUpInside)
        routeButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startRoute(_:)), for: .touchUpInside)
        startStopMonitoring.addTarget(delegate, action: #selector(PoiCalloutDelegate.startOrStopMonitoring(_:)), for: .touchUpInside)
        phoneButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startPhoneCall(_:)), for: .touchUpInside)
        emailButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startEmail(_:)), for: .touchUpInside)
        webSiteButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showURL(_:)), for: .touchUpInside)

        refreshWith(poi, delegate: delegate)
    }
    
    func refreshWith(_ poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        if let subtitle = poi.subtitle {
            addressLabel.text = subtitle
        }
        
        let monitoringStateImageName = poi.isMonitored ? ImageName.monitoringEnabled : ImageName.monitoringDisabled
        startStopMonitoring.setImage(UIImage(named: monitoringStateImageName), for: UIControlState())
        startStopMonitoring.tintColor = poi.isMonitored ? UIColor.red : self.tintColor
        
        startStopMonitoring.removeTarget(nil, action: #selector(PoiCalloutDelegate.startOrStopMonitoring(_:)), for: .touchUpInside)
        startStopMonitoring.addTarget(delegate, action: #selector(PoiCalloutDelegate.startOrStopMonitoring(_:)), for: .touchUpInside)
       
        poi.poiIsContact ? configureForContact(poi) : configureForSimplePoi(poi)
    }
    
    fileprivate func configureForSimplePoi(_ poi:PointOfInterest) {
        configureCategory(poi)
        
        configureURL(poi.poiURL)
        configurePhoneNumber(poi.poiPhoneNumber)
        
        emailButton.isHidden = true
        navigationStackView.isHidden = phoneButton.isHidden && webSiteButton.isHidden && emailButton.isHidden
   }
    
    fileprivate func configureCategory(_ poi:PointOfInterest) {
        if let image = poi.categoryIcon {
            categoryImage.image = image
            categoryImage.isHidden = false
            categoryImage.tintColor = UIColor.black
            categoryImageHeightConstraint.constant = 25
            categoryImageWidthConstraint.constant = 25
        } else {
            categoryImage.isHidden = true
        }
    }
    
    fileprivate func configureContactThumbail(_ contact:CNContact) {
        if let thumbail = contact.thumbnailImageData {
            categoryImage.isHidden = false
            categoryImage.image = UIImage(data: thumbail)
            categoryImageHeightConstraint.constant = 70
            categoryImageWidthConstraint.constant = 70
        } else {
            categoryImage.isHidden = true
        }
    }
    
    fileprivate func configureForContact(_ poi:PointOfInterest) {
        if let contactId = poi.poiContactIdentifier, let theContact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            configureContactThumbail(theContact)
            configurePhoneNumber(theContact)
            configureURL(ContactsUtilities.extractURL(theContact))
            configureMail(theContact)
        } else {
            phoneButton.isHidden = true
            webSiteButton.isHidden = true
            emailButton.isHidden = true
            categoryImage.isHidden = true
        }
        navigationStackView.isHidden = phoneButton.isHidden && webSiteButton.isHidden && emailButton.isHidden
   }
    
    fileprivate func configureMail(_ contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            emailButton.isHidden = true
        } else {
            if contact.emailAddresses.count > 1 {
                emailButton.setImage(UIImage(named: "MessageSeverals-40"), for: UIControlState())
            } else {
                emailButton.setImage(UIImage(named: "Message-40"), for: UIControlState())
            }
            emailButton.isHidden = false
        }
    }
    
    fileprivate func configurePhoneNumber(_ contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            phoneButton.isHidden = false
            if contact.phoneNumbers.count > 1 {
                phoneButton.setImage(UIImage(named: "PhoneSeverals Filled-40"), for: UIControlState())
            } else {
                phoneButton.setImage(UIImage(named: "Phone Filled-40"), for: UIControlState())
            }
        } else {
            phoneButton.isHidden = true
        }
    }

    fileprivate func configurePhoneNumber(_ phoneNumber:String?) {
        if let thePhoneNumber = phoneNumber {
            self.phoneNumber = thePhoneNumber
            phoneButton.isHidden = false
        } else {
            phoneButton.isHidden = true
        }
    }
    
    
    fileprivate func configureURL(_ url:String?) {
        URL = url
        if url != nil {
            webSiteButton.isEnabled = true
            webSiteButton.isHidden = false
        } else {
            webSiteButton.isEnabled = false
            webSiteButton.isHidden = true
        }
    }
}
