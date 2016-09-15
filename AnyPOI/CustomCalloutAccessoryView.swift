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
        if let image = poi.categoryIcon {
            categoryImage.image = image
            categoryImage.hidden = false
            categoryImage.tintColor = UIColor.blackColor()
            categoryImageHeightConstraint.constant = 25
            categoryImageWidthConstraint.constant = 25
        } else {
            categoryImage.hidden = true
        }
        
        if poi.poiURL == nil && poi.poiPhoneNumber == nil {
            navigationStackView.hidden = true
        } else {
            navigationStackView.hidden = false
            initURL(poi.poiURL)
            
            if let phoneNumber = poi.poiPhoneNumber  {
                enablePhoneNumber(phoneNumber)
            } else {
                disablePhoneNumber()
            }
        }
        
        disableMail()
    }
    
    private func configureForContact(poi:PointOfInterest) {
        if let theContact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
            if let thumbail = theContact.thumbnailImageData {
                categoryImage.hidden = false
                categoryImage.image = UIImage(data: thumbail)
                categoryImageHeightConstraint.constant = 70
                categoryImageWidthConstraint.constant = 70
            } else {
                categoryImage.hidden = true
            }
            
            initPhoneNumber(theContact)
            initURL(theContact)
            initMail(theContact)
            navigationStackView.hidden =  phoneButton.hidden && webSiteButton.hidden && emailButton.hidden
        } else {
            disablePhoneNumber()
            disableURL()
            disableMail()
            categoryImage.hidden = true
        }
    }
    
    private func initPhoneNumber(contact:CNContact) {
        if let phone = ContactsUtilities.extractPhoneNumber(contact) {
            phoneButton.hidden = false
        } else {
            disablePhoneNumber()
        }
    }
    
    private func initMail(contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            disableMail()
        } else {
            enableMail()
        }
    }
    
    private func enablePhoneNumber(phoneNumber:String) {
        self.phoneNumber = phoneNumber
        phoneButton.hidden = false
    }
    
    private func disablePhoneNumber() {
        phoneButton.hidden = true
    }
    
    private func enableMail() {
        emailButton.hidden = false
    }
    
    private func disableMail() {
        emailButton.hidden = true
    }
    
    private func initURL(contact:CNContact) {
        if let url = ContactsUtilities.extractURL(contact) {
            URL = url
            enableURL()
        } else {
            disableURL()
        }
    }
    
    private func initURL(url:String?) {
        URL = url
        url != nil ? enableURL() : disableURL()
    }
    
    private func enableURL() {
        webSiteButton.enabled = true
        webSiteButton.hidden = false
    }
    private func disableURL() {
        webSiteButton.enabled = false
        webSiteButton.hidden = true
    }
    
}
