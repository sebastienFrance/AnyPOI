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

    static func showAlertMessage(viewController: UIViewController, title:String, message:String) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: message, preferredStyle: .Alert)
        let actionClose = UIAlertAction(title: "Close", style: .Cancel) { alertAction in
            alertView.dismissViewControllerAnimated(true, completion: nil)
        }

        alertView.addAction(actionClose)
        viewController.presentViewController(alertView, animated: true, completion: nil)
    }

    static func showAlertMessage(viewController: UIViewController, title:String, error:NSError) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: error.localizedDescription, preferredStyle: .Alert)
        let actionClose = UIAlertAction(title: "Close", style: .Cancel) { alertAction in
            alertView.dismissViewControllerAnimated(true, completion: nil)
        }

        alertView.addAction(actionClose)
        viewController.presentViewController(alertView, animated: true, completion: nil)
    }


    static func stringFromTimeInterval(interval:NSTimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        
        let ms = Int((interval % 1) * 1000)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
    static func shortStringFromTimeInterval(interval:NSTimeInterval) -> NSString {
        if !interval.isNaN && !interval.isInfinite {
            
            let ti = NSInteger(interval)
            
            let minutes = (ti / 60) % 60
            let hours = (ti / 3600)
            
            return NSString(format: "%0.2d:%0.2d",hours,minutes)
        } else {
            return ""
        }
    }
    
    static func getAddressFrom(placemark:CLPlacemark) -> String {
        if let addressDictionary = placemark.addressDictionary {
            return ABCreateStringWithAddressDictionary(addressDictionary, false)
        } else {
            return "no address"
        }
    }
    
    static func startPhoneCall(phoneNumber:String?) {
        if let thePhoneNumber = phoneNumber {
            if let formatedURL = "tel://\(thePhoneNumber)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet()) {
                if let myURL = NSURL(string: formatedURL) {
                    UIApplication.sharedApplication().openURL(myURL)
                }
            }
        }
    }
    
    static func openSafariFrom(viewController:UIViewController, url:String?, subTitle:String?, delegate:SFSafariViewControllerDelegate) {
        if let URL = url {
            if let formatedURL = "\(URL)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet()) {
                if let myURL = NSURL(string: formatedURL) {
                    openSafariFrom(viewController, url: myURL, subTitle: subTitle, delegate: delegate)
                }
            }
        }
    }
    
    static func openSafariFrom(viewController:UIViewController, url:NSURL?, subTitle:String?, delegate:SFSafariViewControllerDelegate) {
        if let myURL = url {
            let safari = SFSafariViewController(URL: myURL)
            safari.delegate = delegate
            
            viewController.navigationController?.toolbarHidden = true
            
            viewController.showViewController(safari, sender: nil)
            
            PKHUD.sharedHUD.dimsBackground = true
            HUD.show(.Progress)
            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
            if let theSubTitle = subTitle {
                hudBaseView.titleLabel.text = "Page loading for"
                hudBaseView.subtitleLabel.text = theSubTitle
            } else {
                hudBaseView.titleLabel.text = "Page loading"
            }
        }
    }


}