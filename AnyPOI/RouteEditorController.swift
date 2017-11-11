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
    func routeCreated(_ route:Route)
    func routeUpdated(_ route:Route)
    func routeEditorCancelled()
}

class RouteEditorController {
    
    fileprivate var createRouteController:UIAlertController?
    
    func modifyRoute(_ parentViewController:UIViewController, delegate:RouteEditorDelegate,route:Route) {
        
        let routeTitle = NSLocalizedString("UpdateRouteRouteEditorController", comment: "")
        createRouteController = UIAlertController(title: routeTitle, message: NSLocalizedString("GetNewRouteNameRouteEditorController", comment: ""), preferredStyle: .alert)
        
        createRouteController!.addTextField()  { textField in
            textField.placeholder = NSLocalizedString("RouteNameRouteEditorControllerPlaceholder", comment: "")
            textField.isSecureTextEntry = false
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
            textField.spellCheckingType = .yes
            textField.clearButtonMode = .always
            textField.text = route.routeName!
            
            textField.addTarget(self, action: #selector(RouteEditorController.checkRouteName(_:)), for: .allEditingEvents)
        }
        
        let okButton = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default) { alertAction in
            let routeName = self.createRouteController!.textFields?[0].text
            route.routeName = routeName
            POIDataManager.sharedInstance.commitDatabase()
            delegate.routeUpdated(route)
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { alertAction in
            delegate.routeEditorCancelled()
        }
        
        okButton.isEnabled = false
        createRouteController!.addAction(okButton)
        createRouteController!.addAction(cancelButton)
        parentViewController.present(createRouteController!, animated: true, completion: nil)
    }
    
    func createRouteWith(_ parentViewController:UIViewController, delegate:RouteEditorDelegate, routeName:String = "", pois:[PointOfInterest] = [PointOfInterest]()) {
        
        let routeTitle = NSLocalizedString("CreateRouteRouteEditorController", comment: "")
        createRouteController = UIAlertController(title: routeTitle, message: NSLocalizedString("GetNewRouteNameRouteEditorController", comment: ""), preferredStyle: .alert)
        
        createRouteController!.addTextField()  { textField in
            textField.placeholder = NSLocalizedString("RouteNameRouteEditorControllerPlaceholder", comment: "")
            textField.isSecureTextEntry = false
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
            textField.spellCheckingType = .yes
            textField.clearButtonMode = .always
            textField.text = routeName
            
            textField.addTarget(self, action: #selector(RouteEditorController.checkRouteName(_:)), for: .allEditingEvents)
        }
        
        let okButton = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default) { alertAction in
            let routeName = self.createRouteController!.textFields?[0].text
            
            let newRoute = POIDataManager.sharedInstance.addRoute(routeName!, routePath:pois)
            delegate.routeCreated(newRoute) // Must be done before the route notif is sent
            POIDataManager.sharedInstance.commitDatabase()
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { alertAction in
            delegate.routeEditorCancelled()
        }
        
        okButton.isEnabled = false
        createRouteController!.addAction(okButton)
        createRouteController!.addAction(cancelButton)
        parentViewController.present(createRouteController!, animated: true, completion: nil)
    }
 
   
    @objc func checkRouteName(_ sender:AnyObject) {
        if let textfield = sender as? UITextField {
            if !textfield.text!.isEmpty {
                createRouteController!.actions[0].isEnabled = true
            } else {
                createRouteController!.actions[0].isEnabled = false
            }
        }
    }
    

}
