//
//  Utilities.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import AddressBookUI
import SafariServices
import PKHUD
import Contacts
import MessageUI

class Utilities {

    struct IconName {
        static let monitoringEnabled = "Circled Dot Minus-26"
        static let monitoringDisabled = "Circled Dot Plus-26"
        static let severalseMailsAddress = "New Message-26"
        static let eMailAddress = "Message-26"
        static let severalsPhoneNumbers = "Phone severals-26"
        static let phoneNumber = "Phone-26"
    }

    static func getCurrentViewController() -> UIViewController? {
        let app = UIApplication.shared.delegate as! AppDelegate
        guard let rvc = app.window?.rootViewController else {
            return nil
        }
        return getCurrentViewController(vc:rvc)
    }
    
    fileprivate static func getCurrentViewController(vc: UIViewController) -> UIViewController? {
        if let pvc = vc.presentedViewController {
            return getCurrentViewController(vc:pvc)
        }
        else if let svc = vc as? UISplitViewController, svc.viewControllers.count > 0 {
            return getCurrentViewController(vc:svc.viewControllers.last!)
        }
        else if let nc = vc as? UINavigationController, nc.viewControllers.count > 0 {
            return getCurrentViewController(vc:nc.topViewController!)
        }
        else if let tbc = vc as? UITabBarController {
            if let svc = tbc.selectedViewController {
                return getCurrentViewController(vc:svc)
            }
        }
        return vc
    }
    
    static func showAlertMaxPOI(viewController: UIViewController) {
        let fullMessage = String(format: NSLocalizedString("To create more than %d Point of Interest you need to purchase an In-App", comment: ""), MapViewController.MAX_POI_WITHOUT_LICENSE)
        Utilities.showAlertMessage(viewController, title: NSLocalizedString("Error", comment: ""), message: fullMessage)
    }

    static func showAlertMessage(_ viewController: UIViewController, title:String, message:String) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let actionClose = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel) { alertAction in
            alertView.dismiss(animated: true, completion: nil)
        }

        alertView.addAction(actionClose)
        viewController.present(alertView, animated: true, completion: nil)
    }

    static func showAlertMessage(_ viewController: UIViewController, title:String, error:Error) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: error.localizedDescription, preferredStyle: .alert)
        let actionClose = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel) { alertAction in
            alertView.dismiss(animated: true, completion: nil)
        }

        alertView.addAction(actionClose)
        viewController.present(alertView, animated: true, completion: nil)
    }


    static func stringFromTimeInterval(_ interval:TimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        
        let ms = Int((interval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
    
    static func shortStringFromTimeInterval(_ interval:TimeInterval) -> NSString {
        if !interval.isNaN && !interval.isInfinite {
            
            let ti = NSInteger(interval)
            
            let minutes = (ti / 60) % 60
            let hours = (ti / 3600)
            
            return NSString(format: "%0.2d:%0.2d",hours,minutes)
        } else {
            return ""
        }
    }
    
    static func getAddressFrom(_ placemark:CLPlacemark) -> String {
        if let addressDictionary = placemark.postalAddress {
            return CNPostalAddressFormatter.string(from: addressDictionary, style:.mailingAddress)
        } else {
            return NSLocalizedString("NoAddressUtilities", comment: "")
        }
    }
    
    static func postalAddressFromDictionary(dict:Dictionary<AnyHashable,Any>) -> CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = dict["Street"] as? String ?? ""
        address.state = dict["State"] as? String ?? ""
        address.city = dict["City"] as? String ?? ""
        address.country = dict["Country"] as? String ?? ""
        address.postalCode = dict["ZIP"] as? String ?? ""
        
        return address
    }
    
    static func startPhoneCall(_ phoneNumber:String) {
        if let formatedURL = "tel://\(phoneNumber)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
            if let telURL = URL(string:formatedURL) {
                if UIApplication.shared.canOpenURL(telURL) { 
                    UIApplication.shared.open(telURL, options:[ : ]) { callResult in
                        if !callResult {
                            NSLog("\(#function) cannot make a call with \(telURL.absoluteString)")
                        }
                    }
                } else {
                    NSLog("\(#function) cannot open this url: \(telURL.absoluteString)")
                }
            }
        }
    }
    
    static func startFaceTimeCall(phoneNumber:String) {
        if let formatedURL = "tel://\(phoneNumber)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
            if let facetimeURL = URL(string: formatedURL) {
                if UIApplication.shared.canOpenURL(facetimeURL) {
                    UIApplication.shared.open(facetimeURL, options:[ : ]) { callResult in
                        if !callResult {
                            NSLog("\(#function) cannot make a Facetime call with \(facetimeURL.absoluteString)")
                        }
                    }
                }
            }
        }
    }
    
    
    static func openSafariFrom(_ viewController:UIViewController, url:String?, delegate:SFSafariViewControllerDelegate) {
        if let URL = url {
            if let formatedURL = "\(URL)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
                if let myURL = Foundation.URL(string: formatedURL) {
                    openSafariFrom(viewController, url: myURL, delegate: delegate)
                }
            }
        }
    }
    
    static func openSafariFrom(_ viewController:UIViewController, url:URL?, delegate:SFSafariViewControllerDelegate) {
        if let myURL = url {
            let safari = SFSafariViewController(url: myURL)
            safari.modalPresentationStyle = .overFullScreen // Display it as a modal instead of push on Navigation Statck
            safari.dismissButtonStyle = .close
            safari.delegate = delegate
            viewController.navigationController?.isToolbarHidden = true
            viewController.present(safari, animated: true, completion: nil)
        }
    }


}
