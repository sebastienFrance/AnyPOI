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

class Utilities {

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
        if let addressDictionary = placemark.addressDictionary {
            return ABCreateStringWithAddressDictionary(addressDictionary, false)
        } else {
            return NSLocalizedString("NoAddressUtilities", comment: "")
        }
    }
    
    static func startPhoneCall(_ phoneNumber:String?) {
        if let thePhoneNumber = phoneNumber {
            if let formatedURL = "tel://\(thePhoneNumber)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
                if let myURL = URL(string: formatedURL) {
                    UIApplication.shared.openURL(myURL)
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
            safari.delegate = delegate
            viewController.navigationController?.isToolbarHidden = true
            viewController.show(safari, sender: nil)
            
//            PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = true
//            PKHUD.sharedHUD.dimsBackground = true
//            HUD.show(.Progress)
//            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
//            hudBaseView.titleLabel.text = "Page loading"

        }
    }


}
