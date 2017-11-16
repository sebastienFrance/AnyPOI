//
//  POIDetailsInterfaceController.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import Foundation


class POIDetailsInterfaceController: WKInterfaceController {

    @IBOutlet var theGroupDescription: WKInterfaceGroup!
    @IBOutlet var theMap: WKInterfaceMap!
    @IBOutlet var theImage: WKInterfaceImage!
    @IBOutlet var theLabel: WKInterfaceLabel!
    @IBOutlet var theAddress: WKInterfaceLabel!
    @IBOutlet var thePhoneButton: WKInterfaceButton!
    @IBOutlet var theCategoryLabel: WKInterfaceLabel!
    @IBOutlet var theSpacerGroup: WKInterfaceGroup!
    
    var poi:WatchPointOfInterest?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let watchPOI = context as? WatchPointOfInterest {
            poi = watchPOI
            theImage.setImage(watchPOI.category?.glyph)
            theImage.setTintColor(UIColor.white)
          
            theLabel.setText(watchPOI.title)
            if let category = watchPOI.category?.localizedString {
                theCategoryLabel.setText(category)
            } else {
                theCategoryLabel.setHidden(true)
            }
            theAddress.setText(watchPOI.address)
            theMap.addAnnotation(watchPOI.coordinate, with: WKInterfaceMapPinColor.green)
            theMap.setRegion(MKCoordinateRegionMakeWithDistance(watchPOI.coordinate, 200, 200))
            
            if watchPOI.phones.count == 0 {
                thePhoneButton.setHidden(true)
            }
            
            theGroupDescription.setBackgroundColor(watchPOI.color.withAlphaComponent(0.0))
        }
        // Configure interface objects here.
    }
    
    override func didAppear() {
        super.didAppear()
        guard poi != nil else { return }
        
        animate(withDuration: 0.3) {
            self.theGroupDescription.setBackgroundColor(self.poi!.color.withAlphaComponent(0.3))
            self.theSpacerGroup.setWidth(0.0)
        }
    }

    @IBAction func phoneButtonPressed() {
        
        guard poi != nil && poi!.phones.count > 0 else { return }
        
        var actions = [WKAlertAction]()
        for phoneNumber in poi!.phones {
            
            let action = WKAlertAction(title: phoneNumber, style: .default) {
                DispatchQueue.main.async {
                    POIDetailsInterfaceController.startPhoneCall(phoneNumber)
                }
            }
            actions.append(action)
        }

        presentAlert(withTitle: NSLocalizedString("POIDetails_Call", comment: ""),
                     message: NSLocalizedString("POIDetails_SelectNumber", comment: ""),
                     preferredStyle: .actionSheet,
                     actions: actions)
       
    }
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    static func startPhoneCall(_ phoneNumber:String) {
        if let formatedURL = "tel://\(phoneNumber)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
            
            if let telURL = URL(string:formatedURL) {
                WKExtension.shared().openSystemURL(telURL)
            }
        }
    }

}
