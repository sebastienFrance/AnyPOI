//
//  RouteEditorController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 27/06/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit

protocol RouteEditorDelegate {
    func routeCreated(route:Route)
    func routeUpdated(route:Route)
    func routeEditorCancelled()
}

class RouteEditorController {
    
    private var createRouteController:UIAlertController?
    
    func modifyRoute(parentViewController:UIViewController, delegate:RouteEditorDelegate,route:Route) {
        
        let routeTitle = NSLocalizedString("UpdateRouteRouteEditorController", comment: "")
        createRouteController = UIAlertController(title: routeTitle, message: NSLocalizedString("GetNewRouteNameRouteEditorController", comment: ""), preferredStyle: .Alert)
        
        createRouteController!.addTextFieldWithConfigurationHandler()  { textField in
            textField.placeholder = NSLocalizedString("RouteNameRouteEditorControllerPlaceholder", comment: "")
            textField.secureTextEntry = false
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.spellCheckingType = .Yes
            textField.clearButtonMode = .Always
            textField.text = route.routeName!
            
            textField.addTarget(self, action: #selector(RouteEditorController.checkRouteName(_:)), forControlEvents: .AllEditingEvents)
        }
        
        let okButton = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .Default) { alertAction in
            let routeName = self.createRouteController!.textFields?[0].text
            route.routeName = routeName
            POIDataManager.sharedInstance.commitDatabase()
            delegate.routeUpdated(route)
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Default) { alertAction in
            delegate.routeEditorCancelled()
        }
        
        okButton.enabled = false
        createRouteController!.addAction(okButton)
        createRouteController!.addAction(cancelButton)
        parentViewController.presentViewController(createRouteController!, animated: true, completion: nil)
    }
    
    func createRouteWith(parentViewController:UIViewController, delegate:RouteEditorDelegate, routeName:String = "", pois:[PointOfInterest] = [PointOfInterest]()) {
        
        let routeTitle = NSLocalizedString("CreateRouteRouteEditorController", comment: "")
        createRouteController = UIAlertController(title: routeTitle, message: NSLocalizedString("GetNewRouteNameRouteEditorController", comment: ""), preferredStyle: .Alert)
        
        createRouteController!.addTextFieldWithConfigurationHandler()  { textField in
            textField.placeholder = NSLocalizedString("RouteNameRouteEditorControllerPlaceholder", comment: "")
            textField.secureTextEntry = false
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.spellCheckingType = .Yes
            textField.clearButtonMode = .Always
            textField.text = routeName
            
            textField.addTarget(self, action: #selector(RouteEditorController.checkRouteName(_:)), forControlEvents: .AllEditingEvents)
        }
        
        let okButton = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .Default) { alertAction in
            let routeName = self.createRouteController!.textFields?[0].text
            
            let newRoute = POIDataManager.sharedInstance.addRoute(routeName!, routePath:pois)
            delegate.routeCreated(newRoute) // Must be done before the route notif is sent
            POIDataManager.sharedInstance.commitDatabase()
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Default) { alertAction in
            delegate.routeEditorCancelled()
        }
        
        okButton.enabled = false
        createRouteController!.addAction(okButton)
        createRouteController!.addAction(cancelButton)
        parentViewController.presentViewController(createRouteController!, animated: true, completion: nil)
    }
 
   
    @objc func checkRouteName(sender:AnyObject) {
        if let textfield = sender as? UITextField {
            if !textfield.text!.characters.isEmpty {
                createRouteController!.actions[0].enabled = true
            } else {
                createRouteController!.actions[0].enabled = false
            }
        }
    }
    

}
