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

    @IBOutlet weak var detailsInfoButton: UIButton!
    @IBOutlet weak var categoryImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var flyoverButton: UIButton!
    @IBOutlet weak var navigationRowHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var startStopMonitoring: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    @IBOutlet weak var navigationStackView: UIStackView!

    @IBOutlet weak var actionsStackView: UIStackView!
    
    @IBOutlet weak var routeStackView: UIStackView!
    @IBOutlet weak var addWayPointButton: UIButton!
    @IBOutlet weak var removeWayPointButton: UIButton!
    @IBOutlet weak var routeFromCurrentLocationButton: UIButton!
    
    fileprivate(set) var URL:String?
    fileprivate(set) var phoneNumber:String?
    
    
    func initWith(_ poi:PointOfInterest, delegate:PoiCalloutDelegate) {
        
        // Delegate will never change, it can be initialized once for all
        detailsInfoButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showDetails(_:)), for: .touchUpInside)
        
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
        
        let monitoringStateImageName = poi.isMonitored ? Utilities.IconName.monitoringEnabled : Utilities.IconName.monitoringDisabled
        startStopMonitoring.setImage(UIImage(named: monitoringStateImageName), for: UIControlState())
        startStopMonitoring.tintColor = poi.isMonitored ? UIColor.red : self.tintColor
        
        startStopMonitoring.removeTarget(nil, action: #selector(PoiCalloutDelegate.startOrStopMonitoring(_:)), for: .touchUpInside)
        startStopMonitoring.addTarget(delegate, action: #selector(PoiCalloutDelegate.startOrStopMonitoring(_:)), for: .touchUpInside)
       
        poi.poiIsContact ? configureForContact(poi) : configureForSimplePoi(poi)
    }
    
    func update(isFlyover:Bool) {
        navigationStackView.isHidden = isFlyover
        actionsStackView.isHidden = isFlyover
        routeStackView.isHidden = isFlyover
        
        detailsInfoButton.isHidden = isFlyover
    }
    
    fileprivate func configureForSimplePoi(_ poi:PointOfInterest) {
        configureCategory(poi)
        
        configureURL(poi.poiURL)
        configurePhoneNumber(poi.poiPhoneNumber)
        
        emailButton.isHidden = true
        if phoneButton.isHidden && webSiteButton.isHidden && emailButton.isHidden {
            navigationStackView.isHidden = true
            navigationRowHeightConstraint.constant = 0.0
        } else {
            navigationStackView.isHidden = false
            navigationRowHeightConstraint.constant = 40.0
        }
        
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
        
        if phoneButton.isHidden && webSiteButton.isHidden && emailButton.isHidden {
            navigationStackView.isHidden = true
            navigationRowHeightConstraint.constant = 0.0
        } else {
            navigationStackView.isHidden = false
            navigationRowHeightConstraint.constant = 40.0
        }
   }
    
    fileprivate func configureMail(_ contact:CNContact) {
        if contact.emailAddresses.count == 0 {
            emailButton.isHidden = true
        } else {
            if contact.emailAddresses.count > 1 {
                emailButton.setImage(UIImage(named: Utilities.IconName.severalseMailsAddress), for: UIControlState())
            } else {
                emailButton.setImage(UIImage(named: Utilities.IconName.eMailAddress), for: UIControlState())
            }
            emailButton.isHidden = false
        }
    }
    
    fileprivate func configurePhoneNumber(_ contact:CNContact) {
        if contact.phoneNumbers.count > 0 {
            phoneButton.isHidden = false
            if contact.phoneNumbers.count > 1 {
                phoneButton.setImage(UIImage(named: Utilities.IconName.severalsPhoneNumbers), for: UIControlState())
            } else {
                phoneButton.setImage(UIImage(named: Utilities.IconName.phoneNumber), for: UIControlState())
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
    
    // From LeftCalloutAccessory
    
    func configureRouteButtons(_ delegate:PoiCalloutDelegate, type:MapUtils.PinAnnotationType) {
        
        switch type {
        case .normal:
            disableRemoveWayPoint()
            enableAddWayPoint(delegate)
            disableRouteFromCurrentLocation()
            break
        case .routeEnd:
            enableRemoveWayPoint(delegate)
            disableAddWayPoint()
            enableRouteFromCurrentLocation(delegate)
        case .routeStart:
            // Do not authorize to add the route start as a new WayPoint when the route contains only the start
            if let wayPoints = MapViewController.instance?.routeDatasource?.wayPoints, wayPoints.count > 1 {
                enableAddWayPoint(delegate)
            } else {
                disableAddWayPoint()
            }
            enableRemoveWayPoint(delegate)
            enableRouteFromCurrentLocation(delegate)
        case .waypoint:
            enableAddWayPoint(delegate)
            enableRemoveWayPoint(delegate)
            disableRouteFromCurrentLocation()
        }
    }
    
    fileprivate func enableAddWayPoint(_ delegate:PoiCalloutDelegate) {
        addWayPointButton.isHidden = false
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
        addWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
    }
    
    func disableAddWayPoint() {
        addWayPointButton.isHidden = true
        addWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.addWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func enableRemoveWayPoint(_ delegate:PoiCalloutDelegate) {
        removeWayPointButton.isHidden = false
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
        removeWayPointButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func disableRemoveWayPoint() {
        removeWayPointButton.isHidden = true
        removeWayPointButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.trashWayPoint(_:)), for: .touchUpInside)
    }
    
    fileprivate func enableRouteFromCurrentLocation(_ delegate:PoiCalloutDelegate) {
        if let fullRouteMode = MapViewController.instance?.routeDatasource?.isFullRouteMode, !fullRouteMode {
            
            if let routeManager = MapViewController.instance?.routeManager {
                if let _ = routeManager.fromCurrentLocation {
                    routeFromCurrentLocationButton.tintColor = UIColor.red
                } else {
                    routeFromCurrentLocationButton.tintColor = MapViewController.instance!.view.tintColor
                }
            }
            
            routeFromCurrentLocationButton.isHidden = false
            routeFromCurrentLocationButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
            routeFromCurrentLocationButton.addTarget(delegate, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
        } else {
            disableRouteFromCurrentLocation()
        }
    }
    
    fileprivate func disableRouteFromCurrentLocation() {
        routeFromCurrentLocationButton.isHidden = true
        routeFromCurrentLocationButton.removeTarget(nil, action: #selector(PoiCalloutDelegate.showRouteFromCurrentLocation(_:)), for: .touchUpInside)
    }
    

}
