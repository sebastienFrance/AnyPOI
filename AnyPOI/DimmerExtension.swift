//
//  DimmerExtension.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 02/05/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

extension UIViewController {
    
    fileprivate static let DIMMER_VIEW_ID = 999
    
    // Add a dimmer view as the first subview of the currently displayed view
    fileprivate func performStartDim(_ alpha:CGFloat = 0.4, duration:TimeInterval = 0.5, sourceView:UIView) {
        let dimView = UIView(frame: sourceView.frame)
        dimView.backgroundColor = UIColor.black
        dimView.alpha = 0.0
        dimView.tag = UIViewController.DIMMER_VIEW_ID // Make it distinct from others views
        sourceView.addSubview(dimView) // The new view (dimmer) will be displayed on top of current view
        // Deal with Auto Layout to fill the full view
        dimView.translatesAutoresizingMaskIntoConstraints = false
        sourceView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))
        sourceView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))

        UIView.animate(withDuration: duration, animations: {
            dimView.alpha = alpha
        }) 
       
    }
    
    // Start Dim on the viewController. If the view controller is embedded in a NavigationController
    // we must get the topView of the Navigation to build the dimmer to fill the full screen (including the Nav toolbar).
    // If not embedded in a Navigation controller we just need to take the topView of the viewController
    public func startDim(_ alpha:CGFloat = 0.4, duration:TimeInterval = 0.5) {
        if let navController = navigationController {
            performStartDim(alpha, duration: duration, sourceView: navController.view)
        } else {
            performStartDim(alpha, duration: duration, sourceView: view)
        }
    }

    // Remove the Dimmer view from the ViewController or from the Navigation Controller
    // This method check if there's a real Dimmer view instantiated to avoid deletion of 
    // a usefull view when there's no dimmer displayed
    public func stopDim(_ duration:TimeInterval = 0.5) {
        var sourceView:UIView!
        if navigationController != nil {
            sourceView = navigationController!.view
        } else {
            sourceView = self.view
        }
        
        if sourceView.subviews.last?.tag == UIViewController.DIMMER_VIEW_ID {
            if duration > 0.0 {
                UIView.animate(withDuration: duration,
                                           animations: {
                                            sourceView.subviews.last?.alpha = 0.0
                    },
                                           completion: { result in
                                            sourceView.subviews.last?.removeFromSuperview()
                    }
                )
            } else {
                sourceView.subviews.last?.removeFromSuperview()
            }
        }
    }
    


}
