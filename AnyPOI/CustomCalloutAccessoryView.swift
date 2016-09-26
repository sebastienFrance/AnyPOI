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
    @IBOutlet weak var zoomButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var startStopMonitoring: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var navigationStackView: UIStackView!

    @IBOutlet weak var actionsStackView: UIStackView!
    
    private(set) var URL:String?
    private(set) var phoneNumber:String?
    
    private struct ImageName {
        static let monitoringEnabled = "Circled Dot Minus-40"
        static let monitoringDisabled = "Circled Dot Plus-40"
    }
    
    func initWith(poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        
        // Delegate will never change, it can be initialized once for all
        zoomButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.zoomOnPoi(_:)), forControlEvents: .TouchUpInside)
        routeButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startRoute(_:)), forControlEvents: .TouchUpInside)
        startStopMonitoring.addTarget(poi, action: #selector(PointOfInterest.startOrStopMonitoring(_:)), forControlEvents: .TouchUpInside)
        phoneButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startPhoneCall(_:)), forControlEvents: .TouchUpInside)
        emailButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.startEmail(_:)), forControlEvents: .TouchUpInside)
        webSiteButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showURL(_:)), forControlEvents: .TouchUpInside)

        refreshWith(poi)
    }
    
    func refreshWith(poi:PointOfInterest) {
        if let subtitle = poi.subtitle {
            addressLabel.text = subtitle
        }
        
        let monitoringStateImageName = poi.isMonitored ? ImageName.monitoringEnabled : ImageName.monitoringDisabled
        startStopMonitoring.setImage(UIImage(named: monitoringStateImageName), forState: .Normal)
        startStopMonitoring.removeTarget(nil, action: #selector(PointOfInterest.startOrStopMonitoring(_:)), forControlEvents: .TouchUpInside)
        startStopMonitoring.addTarget(poi, action: #selector(PointOfInterest.startOrStopMonitoring(_:)), forControlEvents: .TouchUpInside)
       
        poi.poiIsContact ? configureForContact(poi) : configureForSimplePoi(poi)
    }
    
    private func configureForSimplePoi(poi:PointOfInterest) {
        configureCategory(poi)
        
        configureURL(poi.poiURL)
        configurePhoneNumber(poi.poiPhoneNumber)
        
        emailButton.hidden = true
        navigationStackView.hidden = phoneButton.hidden && webSiteButton.hidden && emailButton.hidden
   }
    
    private func configureCategory(poi:PointOfInterest) {
        if let image = poi.categoryIcon {
            categoryImage.image = image
            categoryImage.hidden = false
            categoryImage.tintColor = UIColor.blackColor()
            categoryImageHeightConstraint.constant = 25
            categoryImageWidthConstraint.constant = 25
        } else {
            categoryImage.hidden = true
        }
    }
    
    private func configureContactThumbail(contact:CNContact) {
        if let thumbail = contact.thumbnailImageData {
            categoryImage.hidden = false
            categoryImage.image = UIImage(data: thumbail)
            categoryImageHeightConstraint.constant = 70
            categoryImageWidthConstraint.constant = 70
        } else {
            categoryImage.hidden = true
        }
    }
    
    private func configureForContact(poi:PointOfInterest) {
        if let theContact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
            configureContactThumbail(theContact)
            configurePhoneNumber(theContact)
            configureURL(ContactsUtilities.extractURL(theContact))
            configureMail(theContact)
        } else {
            phoneButton.hidden = true
            webSiteButton.hidden = true
            emailButton.hidden = true
            categoryImage.hidden = true
        }
        navigationStackView.hidden = phoneButton.hidden && webSiteButton.hidden && emailButton.hidden
   }
    
    private func configureMail(contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            emailButton.hidden = true
        } else {
            if contact.emailAddresses.count > 1 {
                emailButton.setImage(UIImage(named: "MessageSeverals-40"), forState: .Normal)
            } else {
                emailButton.setImage(UIImage(named: "Message-40"), forState: .Normal)
            }
            emailButton.hidden = false
        }
    }
    
    private func configurePhoneNumber(contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            phoneButton.hidden = false
            if contact.phoneNumbers.count > 1 {
                phoneButton.setImage(UIImage(named: "PhoneSeverals Filled-40"), forState: .Normal)
            } else {
                phoneButton.setImage(UIImage(named: "Phone Filled-40"), forState: .Normal)
            }
        } else {
            phoneButton.hidden = true
        }
    }

    private func configurePhoneNumber(phoneNumber:String?) {
        if let thePhoneNumber = phoneNumber {
            self.phoneNumber = thePhoneNumber
            phoneButton.hidden = false
        } else {
            phoneButton.hidden = true
        }
    }
    
    
    private func configureURL(url:String?) {
        URL = url
        if url != nil {
            webSiteButton.enabled = true
            webSiteButton.hidden = false
        } else {
            webSiteButton.enabled = false
            webSiteButton.hidden = true
        }
    }
}
