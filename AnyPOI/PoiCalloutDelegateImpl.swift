//
//  PoiCalloutDelegateImpl.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 28/05/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SafariServices
import PKHUD
import MessageUI

class PoiCalloutDelegateImpl: NSObject   {
    
    fileprivate weak var theMapView:MKMapView!
    weak var viewController:UIViewController!
    
    init(mapView:MKMapView, sourceViewController:UIViewController) {
        theMapView = mapView
        viewController = sourceViewController
    }
    
}

extension PoiCalloutDelegateImpl : PoiCalloutDelegate {
    struct storyboard {
        static let startTableRouteId = "startTableRouteId"
        static let openPhonesId = "openPhones"
        static let openEmailsId = "openEmails"
    }

    func zoomOnPoi(_ sender: UIButton) {
        let selectedAnnotations = theMapView.selectedAnnotations
        if selectedAnnotations.count > 0 {
            let poi = selectedAnnotations[0] as! PointOfInterest
            MapViewController.instance!.flyoverAround(poi)
        }
    }
    
    func startRoute(_ sender: UIButton) {
        let selectedAnnotations = theMapView.selectedAnnotations
        if selectedAnnotations.count > 0 {
            viewController.performSegue(withIdentifier: storyboard.startTableRouteId, sender: selectedAnnotations[0])
        }
    }
    
    
    func startPhoneCall(_ sender:UIButton) {
        let selectedAnnotations = theMapView.selectedAnnotations
        if selectedAnnotations.count > 0 {
            let poi = selectedAnnotations[0] as! PointOfInterest
            let viewAnnotation = theMapView.view(for: poi)
            let calloutAccessoryView = viewAnnotation?.detailCalloutAccessoryView as? CustomCalloutAccessoryView
            
            if poi.poiIsContact {
                if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
                    if contact.phoneNumbers.count > 1 {
                        viewController.performSegue(withIdentifier: storyboard.openPhonesId, sender: poi)
                    } else {
                        if let phoneNumber = ContactsUtilities.extractPhoneNumber(contact) {
                            Utilities.startPhoneCall(phoneNumber.stringValue)
                        }
                    }
                }
            } else {
                Utilities.startPhoneCall(calloutAccessoryView?.phoneNumber)
            }
        }
    }
    
    func startEmail(_ sender:UIButton) {
        let selectedAnnotations = theMapView.selectedAnnotations
        if selectedAnnotations.count > 0 {
            let poi = selectedAnnotations[0] as! PointOfInterest
           // let viewAnnotation = theMapView.viewForAnnotation(poi)
           // let calloutAccessoryView = viewAnnotation?.detailCalloutAccessoryView as? CustomCalloutAccessoryView
            
            if poi.poiIsContact {
                if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
                    if contact.emailAddresses.count > 1 {
                        viewController.performSegue(withIdentifier: storyboard.openEmailsId, sender: poi)
                    } else {
                        // To be completed, start a mail !
                        if MFMailComposeViewController.canSendMail() {
                            let currentLabeledValue = contact.emailAddresses[0]
                            let email = currentLabeledValue.value as String
                            let mailComposer = MFMailComposeViewController()
                            mailComposer.setToRecipients([email])
                            mailComposer.mailComposeDelegate = self
                            viewController.present(mailComposer, animated: true, completion: nil)
                        }

                    }
                }
            }
        }
    }
    
    func showURL(_ sender: UIButton) {
        let selectedAnnotations = theMapView.selectedAnnotations
        if selectedAnnotations.count > 0 {
            let poi = selectedAnnotations[0] as! PointOfInterest
            let viewAnnotation = theMapView.view(for: poi)
            let calloutAccessoryView = viewAnnotation?.detailCalloutAccessoryView as? CustomCalloutAccessoryView
            
            Utilities.openSafariFrom(viewController, url: calloutAccessoryView?.URL, delegate:self)
        }
    }
    
    
    func trashWayPoint(_ sender:UIButton) {
        let mapViewControler = viewController as! MapViewController
        mapViewControler.removeSelectedPoi()
    }
    
    func addWayPoint(_ sender:UIButton) {
        let mapViewControler = viewController as! MapViewController
        mapViewControler.addSelectedPoi()
       
    }
    
    func showRouteFromCurrentLocation(_ sender:UIButton) {
        if let routeManager = MapViewController.instance?.routeManager {
            if !routeManager.isRouteFromCurrentLocationDisplayed {
                sender.tintColor = UIColor.red
                if theMapView.selectedAnnotations.count > 0 {
                    let mapViewControler = viewController as! MapViewController
                    mapViewControler.showRouteFromCurrentLocation(theMapView.selectedAnnotations[0] as! PointOfInterest)
                }
            } else {
                sender.tintColor = MapViewController.instance!.view.tintColor
                MapViewController.instance!.removeRouteFromCurrentLocation()
            }
        }
    }
}

extension PoiCalloutDelegateImpl : MapCameraAnimationsDelegate {
    func mapAnimationCompleted() {
    }
}

extension PoiCalloutDelegateImpl : SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        HUD.hide()
    }
}

extension PoiCalloutDelegateImpl: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

