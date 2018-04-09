//
//  POIDetailImagesDismissAnimationController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/04/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos

class POIDetailImagesDismissAnimationController: NSObject ,UIViewControllerAnimatedTransitioning {

    // Initial image and its rect used to start the Animation
    private let initialFrame:CGRect
    private var initialCellImage:UIImage
    
    
    private static let TRANSITION_DURATION = 0.6

    init(initialRect:CGRect, initialImage:UIImage) {
        self.initialFrame = initialRect
        self.initialCellImage = initialImage
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return POIDetailImagesDismissAnimationController.TRANSITION_DURATION
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        // Warning: the toVC is the TabBarController and not the POIDetaulsViewController, we must follow the whole
        // ViewController hierarchy to get it= TabBarController -> NavigationController.topViewController -> POIDetailsViewController
        
        guard let fromPoiImageVC = transitionContext.viewController(forKey: .from) as? PoiImageCollectionViewController,
            fromPoiImageVC.theCollectionView.indexPathsForVisibleItems.count > 0,
            let toVC = transitionContext.viewController(forKey: .to),
            let navController = (toVC as? UITabBarController)?.selectedViewController as? UINavigationController,
            let toPoiDetailsVC = navController.topViewController as? POIDetailsViewController
            else {
                // When something goes wrong, just complete the transition
                transitionContext.completeTransition(true)
                return
        }

        // SEB: To be completed -> Must work also with Videos
        
        let containerView = transitionContext.containerView
        
        toVC.view.frame = transitionContext.finalFrame(for: toVC)


        // Create a Visual Effect with the light blur
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)

        // Add the toVC at the end of the hierarchy
        containerView.insertSubview(toVC.view, at: 0)

        // Get the image currently displayed in the CollectionView of the From ViewController
        let indexVisibleCell = fromPoiImageVC.theCollectionView.indexPathsForVisibleItems[0]
        fromPoiImageVC.theCollectionView.alpha = 0.0 // Hide the collection view

        // Force the CollectionView to scroll at the index that is displaying the same image
        toPoiDetailsVC.showImageAt(indexPath: indexVisibleCell)

        // Get the Rect where the image will be displayed in the target collection view
        let newTargetFrame = toPoiDetailsVC.getRectImageAt(indexPath: indexVisibleCell)

        // Create an imageView using the initial image. It has a higher resolution than the one that will be displayed
        // in the target ViewController and so we don't need to request a new version of the image using the Asset
        let imageView = UIImageView(frame: containerView.convert(initialFrame, from: nil))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.image = self.initialCellImage

        // Add the UIImageView to the containerView
        containerView.addSubview(imageView)
        
        // At this step in the container View we have from the bottom to top: ToVC, VisualEffect, ImageView

        // SEB: Check why the close button is not removing smoothly
        
        // Start the animation
        let animator = UIViewPropertyAnimator(duration: POIDetailImagesDismissAnimationController.TRANSITION_DURATION, curve: .easeOut) {
            // Make progressively the image smaller
            imageView.frame = newTargetFrame
            // Make progressively the from VC invislbe
            fromPoiImageVC.view.alpha = 0.0
            // Make progressively the blur to become non blurred !
            visualEffectView.effect = nil
        }

        animator.addCompletion() { position in
            // Remove useless view from the container
            imageView.removeFromSuperview()
            visualEffectView.removeFromSuperview()
            
            // Tell the system the animation is completed
            transitionContext.completeTransition(true)
        }

        animator.startAnimation()
    }
}

