//
//  ContainerViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol ContainerViewControllerDelegate : class {
    weak var container:ContainerViewController? {get set}
    var isStartedByLeftMenu:Bool {get set}
    
    func enableGestureRecognizer(_ enable:Bool)
}


protocol CenterViewControllerDelegate : class {
    // Called by the Center ViewController
    func goToMap()
    func toggleLeftPanel()
}

class ContainerViewController: UIViewController {

    enum CenterViewOptions {
        case map, poiManager, travels, options, purchase, about, debug
    }
    
    fileprivate struct Cste {
        static let widthHiddenCenterViewContoller = CGFloat(60.0)
    }

    static fileprivate(set) var sharedInstance:ContainerViewController!
    
    fileprivate var mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    fileprivate var optionsStoryboard = UIStoryboard(name: "Options", bundle: Bundle.main)
    fileprivate var debugStoryboard = UIStoryboard(name: "Debug", bundle: Bundle.main)

    // Navigation Controller that contains the MapViewController
    fileprivate var mapViewNavigationController:UINavigationController!
    
    fileprivate var leftViewController:LeftMenuViewController?
    
    // Current CenterViewController displayed on the screen
    fileprivate var currentApplicationViewController:UINavigationController!
    fileprivate var currentCenterDisplay = CenterViewOptions.map

    // Status of the left panel
    enum SlideOutState {
        case collapsed
        case leftPanelExpanded
    }

    fileprivate var currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadow = currentState != .collapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }
    
    fileprivate var panGestureRecognizer:UIPanGestureRecognizer?


    //MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        ContainerViewController.sharedInstance = self;
        addMapViewControllerInContainer()
    }
    
    // Add the MapViewController in a NavigationController and then set it as the CenterView in the Container
    fileprivate func addMapViewControllerInContainer() {
//        let mapViewController = mainStoryboard.instantiateViewController(withIdentifier: "MapViewControllerId") as! MapViewController
//        mapViewController.container = self
//        mapViewController.isStartedByLeftMenu = false
//
//        mapViewNavigationController = UINavigationController(rootViewController: mapViewController)
//        currentApplicationViewController = mapViewNavigationController
//
//        addChildViewController(currentApplicationViewController)
//        view.addSubview(currentApplicationViewController.view)
//
//        currentApplicationViewController.didMove(toParentViewController: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: status bar
    
    // MapViewController controls the display of the Status bar
    override var childViewControllerForStatusBarStyle : UIViewController? {
        if mapViewNavigationController != nil {
            return mapViewNavigationController.viewControllers[0]
        } else {
            return nil
        }
    }
    
    // Status bar is given by the MapViewController
    override var prefersStatusBarHidden : Bool {
        if mapViewNavigationController != nil {
            let mapVC = mapViewNavigationController.viewControllers[0] as! MapViewController
            return  mapVC.hideStatusBar
        } else {
            return false
        }
    }

    
    
    // This Method is called by the Left Menu only, when the user select the view to be displayed
    func showCenterView(_ viewType:ContainerViewController.CenterViewOptions) {
        if let gestureRecognizer = panGestureRecognizer {
            currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
        }

        switch viewType {
        case .map:
            removeCurrentCenterViewController()
            currentApplicationViewController = mapViewNavigationController
        case .options, .poiManager, .travels, .about, .purchase, .debug:
            displayCenterView(viewType)
        }
        toggleLeftPanel()
        currentCenterDisplay = viewType
    }

    //MARK: Utilities
    
    // Allocate a new ViewController and put it as the CenterViewController
    fileprivate func displayCenterView(_ viewType:ContainerViewController.CenterViewOptions) {
        if currentCenterDisplay != viewType {
            removeCurrentCenterViewController()
            
            var viewController:UIViewController?
            switch viewType {
            case .poiManager:
                viewController = mainStoryboard.instantiateViewController(withIdentifier: "POIsGroupListViewControllerId")
            case .options:
                let optionsViewController = optionsStoryboard.instantiateViewController(withIdentifier: "configureOptions") as! OptionsViewController
                //optionsViewController.theMapView = MapViewController.instance?.theMapView
                viewController = optionsViewController
            case .travels:
                viewController = mainStoryboard.instantiateViewController(withIdentifier: "Routes")
            case .purchase:
                viewController = mainStoryboard.instantiateViewController(withIdentifier: "PurchaseViewControllerId")
            case .debug:
                viewController = debugStoryboard.instantiateViewController(withIdentifier: "DebugMenuViewController") as! DebugMenuTableViewController
            default:
                viewController = nil
            }

            if let vc = viewController {
                insertCenterViewController(vc)
            }
        }
    }
    
    // Remove current CenterViewController from the Container only if it's not the MapViewController
    fileprivate func removeCurrentCenterViewController() {
        if currentCenterDisplay != .map {
            currentApplicationViewController.willMove(toParentViewController: nil)
            currentApplicationViewController.view.removeFromSuperview()
            currentApplicationViewController.removeFromParentViewController()
        }
    }
    
    // Install the viewController as the new CenterViewController in the container
    fileprivate func insertCenterViewController(_ viewController:UIViewController) {
        if let containerDelegate = viewController as? ContainerViewControllerDelegate {
            containerDelegate.container = self
            containerDelegate.isStartedByLeftMenu = true
        }
        
        // Put the CenterViewController in a Navigation controller
        currentApplicationViewController = UINavigationController(rootViewController: viewController)
        
        addChildViewController(currentApplicationViewController)
        view.addSubview(currentApplicationViewController.view)
        
        // Move the view on the right edge of the screen (outside). Next it will be animated to move from the right edge to the left edge
        currentApplicationViewController.view.frame = CGRect(x: view.frame.width, y: view.frame.origin.y, width: view.frame.width, height: view.frame.height)
        currentApplicationViewController.didMove(toParentViewController: self)
    }
    
    // Create the Left menu and add it in the Container
    fileprivate func addLeftPanelViewController() {
        if (leftViewController == nil) {
            leftViewController = mainStoryboard.instantiateViewController(withIdentifier: "LeftMenuViewControllerId") as? LeftMenuViewController
            leftViewController!.container = self
            
            addChildViewController(leftViewController!)
            view.insertSubview(leftViewController!.view, at: 0)
           
            leftViewController!.didMove(toParentViewController: self)
            
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
            currentApplicationViewController.view.addGestureRecognizer(panGestureRecognizer!)
            
            if let containerDelegate = currentApplicationViewController.topViewController as? ContainerViewControllerDelegate {
                containerDelegate.enableGestureRecognizer(false)
            }
        }
    }
    
    
    fileprivate func animateLeftPanel(_ shouldExpandLeftMenu: Bool) {
        if (shouldExpandLeftMenu) {
            // Move the centerViewController to the right of the screen to show the Left Menu
            currentState = .leftPanelExpanded
            animateCenterPanelXPosition(currentApplicationViewController.view.frame.width - Cste.widthHiddenCenterViewContoller)
        } else {
            // Move the centerViewController to left edge of the screen (to fill the whole screen)
            // and we remove the leftViewController from the ContainerView
            animateCenterPanelXPosition(0) { finished in
                self.currentState = .collapsed
                
                self.leftViewController?.willMove(toParentViewController: nil)
                self.leftViewController!.view.removeFromSuperview()
                self.leftViewController?.removeFromParentViewController()
                self.leftViewController = nil;
            }
        }
    }
    
    // Add the shadow on the displayed CenterViewController
    fileprivate func showShadowForCenterViewController(_ shouldShowShadow: Bool) {
        currentApplicationViewController.view.layer.shadowOpacity = shouldShowShadow ? 0.8 : 0.0
    }
    
    fileprivate func animateCenterPanelXPosition(_ targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.currentApplicationViewController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }

}

//MARK: CenterViewControllerDelegate
extension ContainerViewController : CenterViewControllerDelegate {
    
    // Called by a centerViewController to display immediately the MapViewController
    func goToMap() {
        if currentApplicationViewController != mapViewNavigationController {
//            mapViewNavigationController.view.frame = view.frame // Put the map on the right place
//            
//            currentApplicationViewController.willMove(toParentViewController: nil)
//            let viewControllerToRemove = currentApplicationViewController
//            
//            UIView.animate(withDuration: 0.5, animations: {
//                viewControllerToRemove?.view.alpha = 0.0
//            }, completion: { result in
//                viewControllerToRemove?.view.removeFromSuperview()
//                viewControllerToRemove?.removeFromParentViewController()
//            }) 
//            
//            currentApplicationViewController = mapViewNavigationController
//            currentCenterDisplay = .map
//            currentState = .collapsed
//            MapViewController.instance?.enableGestureRecognizer(true)
        } else {
            mapViewNavigationController.popToRootViewController(animated: true)
        }
    }
    
    // Called by a centerViewController when the Left Menu must be displayed
    func toggleLeftPanel() {
        let shouldExpandLeftMenu = (currentState != .leftPanelExpanded)
        
        if shouldExpandLeftMenu {
            addLeftPanelViewController()
        } else {
            if let gestureRecognizer = panGestureRecognizer {
                currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
                if let containerDelegate = currentApplicationViewController.topViewController as? ContainerViewControllerDelegate {
                    containerDelegate.enableGestureRecognizer(true)
                }
            }
        }
        
        animateLeftPanel(shouldExpandLeftMenu)
    }
}

// MARK: UIGestureRecognizerDelegate
extension ContainerViewController: UIGestureRecognizerDelegate {
    
    
    // When the right ViewController has been moved from more than 50% then it automatically replaces the left menu
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        
        switch(recognizer.state) {
        case .began:
            break
        case .changed:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
            recognizer.setTranslation(CGPoint.zero, in: view)
        case .ended:
            if leftViewController != nil {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(hasMovedGreaterThanHalfway)
                
                if !hasMovedGreaterThanHalfway {
                    if let gestureRecognizer = panGestureRecognizer {
                        currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
                        if let containerDelegate = currentApplicationViewController.topViewController as? ContainerViewControllerDelegate {
                            containerDelegate.enableGestureRecognizer(true)
                        }
                    }
                }
            }
        default:
            break
        }
    }
}

