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
}


protocol CenterViewControllerDelegate : class {
    // Called by the Center ViewController
    func goToMap()
    func toggleLeftPanel()
}

class ContainerViewController: UIViewController {

    enum CenterViewOptions {
        case Map, PoiManager, Travels, Options, About
    }
    
    private struct Cste {
        static let widthHiddenCenterViewContoller = CGFloat(60.0)
    }

    static private(set) var sharedInstance:ContainerViewController!
    
    private var mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    
    // Navigation Controller that contains the MapViewController
    private var mapViewNavigationController:UINavigationController!
    
    private var leftViewController:LeftMenuViewController?
    
    // Current CenterViewController displayed on the screen
    private var currentApplicationViewController:UIViewController!
    private var currentCenterDisplay = CenterViewOptions.Map

    // Status of the left panel
    enum SlideOutState {
        case Collapsed
        case LeftPanelExpanded
    }

    private var currentState: SlideOutState = .Collapsed {
        didSet {
            let shouldShowShadow = currentState != .Collapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }

    //MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        ContainerViewController.sharedInstance = self;
        addMapViewControllerInContainer()
    }
    
    // Add the MapViewController in a NavigationController and then set it as the CenterView in the Container
    private func addMapViewControllerInContainer() {
        let mapViewController = mainStoryboard.instantiateViewControllerWithIdentifier("MapViewControllerId") as! MapViewController
        mapViewController.container = self
        mapViewController.isStartedByLeftMenu = false

        mapViewNavigationController = UINavigationController(rootViewController: mapViewController)
        currentApplicationViewController = mapViewNavigationController
        
        addChildViewController(currentApplicationViewController)
        view.addSubview(currentApplicationViewController.view)
        
        currentApplicationViewController.didMoveToParentViewController(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: status bar
    
    // MapViewController controls the display of the Status bar
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        if mapViewNavigationController != nil {
            return mapViewNavigationController.viewControllers[0]
        } else {
            return nil
        }
    }
    
    // Status bar is given by the MapViewController
    override func prefersStatusBarHidden() -> Bool {
        if mapViewNavigationController != nil {
            let mapVC = mapViewNavigationController.viewControllers[0] as! MapViewController
            return  mapVC.hideStatusBar
        } else {
            return false
        }
    }

    private var panGestureRecognizer:UIPanGestureRecognizer?
    
    
    // This Method is called by the Left Menu only, when the user select the view to be displayed
    func showCenterView(viewType:ContainerViewController.CenterViewOptions) {
        if let gestureRecognizer = panGestureRecognizer {
            currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
        }

        
        switch viewType {
        case .Map:
            removeCurrentCenterViewController()
            currentApplicationViewController = mapViewNavigationController
        case .Options, .PoiManager, .Travels, .About:
            displayCenterView(viewType)
        }
        toggleLeftPanel()
        currentCenterDisplay = viewType
    }

    //MARK: Utilities
    
    // Allocate a new ViewController and put it as the CenterViewController
    private func displayCenterView(viewType:ContainerViewController.CenterViewOptions) {
        if currentCenterDisplay != viewType {
            removeCurrentCenterViewController()
            
            var viewController:UIViewController?
            switch viewType {
            case .PoiManager:
                viewController = mainStoryboard.instantiateViewControllerWithIdentifier("POIsGroupListViewControllerId")
            case .Options:
                let optionsViewController = mainStoryboard.instantiateViewControllerWithIdentifier("configureOptions") as! OptionsViewController
                optionsViewController.theMapView = MapViewController.instance?.theMapView
                viewController = optionsViewController
            case .Travels:
                viewController = mainStoryboard.instantiateViewControllerWithIdentifier("Routes")
            default:
                print("\(#function) Error, default case called, it should never happen!!!!")
                viewController = nil
            }

            if let vc = viewController {
                insertCenterViewController(vc)
            }
        }
    }
    
    // Remove current CenterViewController from the Container only if it's not the MapViewController
    private func removeCurrentCenterViewController() {
        if currentCenterDisplay != .Map {
            currentApplicationViewController.willMoveToParentViewController(nil)
            currentApplicationViewController.view.removeFromSuperview()
            currentApplicationViewController.removeFromParentViewController()
        }
    }
    
    // Install the viewController as the new CenterViewController in the container
    private func insertCenterViewController(viewController:UIViewController) {
        if let containerDelegate = viewController as? ContainerViewControllerDelegate {
            containerDelegate.container = self
            containerDelegate.isStartedByLeftMenu = true
        }
        
        // Put the CenterViewController in a Navigation controller
        currentApplicationViewController = UINavigationController(rootViewController: viewController)
        
        addChildViewController(currentApplicationViewController)
        view.addSubview(currentApplicationViewController.view)
        
        // Move the view on the right edge of the screen (outside). Next it will be animated to move from the right edge to the left edge
        currentApplicationViewController.view.frame = CGRectMake(view.frame.width, view.frame.origin.y, view.frame.width, view.frame.height)
        currentApplicationViewController.didMoveToParentViewController(self)
    }
    
    // Create the Left menu and add it in the Container
    private func addLeftPanelViewController() {
        if (leftViewController == nil) {
            leftViewController = mainStoryboard.instantiateViewControllerWithIdentifier("LeftMenuViewControllerId") as? LeftMenuViewController
            leftViewController!.container = self
            
            addChildViewController(leftViewController!)
            view.insertSubview(leftViewController!.view, atIndex: 0)
           
            leftViewController!.didMoveToParentViewController(self)
            
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
            currentApplicationViewController.view.addGestureRecognizer(panGestureRecognizer!)
            
            if currentApplicationViewController === mapViewNavigationController {
                MapViewController.instance?.enableGestureRecognizer(false)
            }
        }
    }
    
    
    private func animateLeftPanel(shouldExpandLeftMenu: Bool) {
        if (shouldExpandLeftMenu) {
            // Move the centerViewController to the right of the screen to show the Left Menu
            currentState = .LeftPanelExpanded
            animateCenterPanelXPosition(CGRectGetWidth(currentApplicationViewController.view.frame) - Cste.widthHiddenCenterViewContoller)
        } else {
            // Move the centerViewController to left edge of the screen (to fill the whole screen)
            // and we remove the leftViewController from the ContainerView
            animateCenterPanelXPosition(0) { finished in
                self.currentState = .Collapsed
                
                self.leftViewController?.willMoveToParentViewController(nil)
                self.leftViewController!.view.removeFromSuperview()
                self.leftViewController?.removeFromParentViewController()
                self.leftViewController = nil;
            }
        }
    }
    
    // Add the shadow on the displayed CenterViewController
    private func showShadowForCenterViewController(shouldShowShadow: Bool) {
        currentApplicationViewController.view.layer.shadowOpacity = shouldShowShadow ? 0.8 : 0.0
    }
    
    private func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.currentApplicationViewController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }

}

extension ContainerViewController : CenterViewControllerDelegate {
    
    // Called by a centerViewController to display immediately the MapViewController
    func goToMap() {
        if currentApplicationViewController != mapViewNavigationController {
            mapViewNavigationController.view.frame = view.frame // Put the map on the right place
            
            currentApplicationViewController.willMoveToParentViewController(nil)
            let viewControllerToRemove = currentApplicationViewController
            
            UIView.animateWithDuration(0.5, animations: {
                viewControllerToRemove.view.alpha = 0.0
            }) { result in
                viewControllerToRemove.view.removeFromSuperview()
                viewControllerToRemove.removeFromParentViewController()
            }
            
            currentApplicationViewController = mapViewNavigationController
            currentCenterDisplay = .Map
            currentState = .Collapsed
            MapViewController.instance?.enableGestureRecognizer(true)
        } else {
            mapViewNavigationController.popToRootViewControllerAnimated(true)
        }
    }
    
    // Called by a centerViewController when the Left Menu must be displayed
    func toggleLeftPanel() {
        let shouldExpandLeftMenu = (currentState != .LeftPanelExpanded)
        
        if shouldExpandLeftMenu {
            addLeftPanelViewController()
        } else {
            if let gestureRecognizer = panGestureRecognizer {
                currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
                if currentApplicationViewController == mapViewNavigationController {
                    MapViewController.instance?.enableGestureRecognizer(true)
                }
            }
        }
        
        animateLeftPanel(shouldExpandLeftMenu)
    }
}

extension ContainerViewController: UIGestureRecognizerDelegate {
    // MARK: Gesture recognizer
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        
        switch(recognizer.state) {
        case .Began:
            break
        case .Changed:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended:
            if leftViewController != nil {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(hasMovedGreaterThanHalfway)
                
                if !hasMovedGreaterThanHalfway {
                    if let gestureRecognizer = panGestureRecognizer {
                        currentApplicationViewController.view.removeGestureRecognizer(gestureRecognizer)
                        if currentApplicationViewController == mapViewNavigationController {
                            MapViewController.instance?.enableGestureRecognizer(true)
                        }
                    }
                }

            }
        default:
            break
        }
    }
}

