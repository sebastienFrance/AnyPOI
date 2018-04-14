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

    
    private static let TRANSITION_DURATION = 0.6

    override init() {
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
        
        let containerView = transitionContext.containerView
        
        //ToView is a TabBarController that contains the whole display
        toVC.view.frame = transitionContext.finalFrame(for: toVC)


        // Create a Visual Effect with the light blur
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)

        // Add the toVC at the bottom of the hierarchy (Blur will be on top of the ToVC)
        containerView.insertSubview(toVC.view, at: 0)
        
        // Get the image currently displayed in the CollectionView of the From ViewController and make it invisible
        let indexVisibleCell = fromPoiImageVC.theCollectionView.indexPathsForVisibleItems[0]
        fromPoiImageVC.theCollectionView.alpha = 0.0 // Hide the collection view

        // Force the CollectionView to scroll at the index that is displaying the same image
        toPoiDetailsVC.showImageAt(indexPath: indexVisibleCell)
        
        var isVideoImage = true
        var imageView:UIImageView?
        var backgroundView = fromPoiImageVC.getSnapshotViewFromVideoCell()
        if let theBackgroundView = backgroundView {
            theBackgroundView.contentMode = .scaleAspectFit
        } else {
            isVideoImage = false
            
            // Create an imageView using the initial image. It has a higher resolution than the one that will be displayed
            // in the target ViewController and so we don't need to request a new version of the image using the Asset
            imageView = UIImageView(frame: fromPoiImageVC.getVisibleRect()!)
            imageView?.clipsToBounds = true
            imageView?.contentMode = .scaleAspectFit
            imageView?.isUserInteractionEnabled = false
            imageView?.image = fromPoiImageVC.getSnapshotImageFromImageCell()
            
            // The background view has the same size and position as the CollectionView
            // It will just contain the image to clip the image in the "CollectionView" even when user has zoomed on the image
            backgroundView = UIView(frame: fromPoiImageVC.theCollectionView.frame)
            backgroundView!.addSubview(imageView!)
            backgroundView!.clipsToBounds = true // Make sure the image will not exceed the size of the "collectionView"
        }

        // Get the Rect where the image will be displayed in the target collection view
        var newTargetFrame = toPoiDetailsVC.getRectImageAt(indexPath: indexVisibleCell)
        newTargetFrame = newTargetFrame.offsetBy(dx: 0, dy: isVideoImage ? 0 : -20)
        
        // Add the UIImageView to the containerView
        containerView.addSubview(backgroundView!)
        
        // Add the close Button in the containerView to progressively hide is during the animation
        let viewCloseButton = fromPoiImageVC.theCloseButton.snapshotView(afterScreenUpdates: false)
        viewCloseButton?.frame = fromPoiImageVC.theCloseButton.convert(fromPoiImageVC.theCloseButton.bounds, to: nil)
        if let theViewCloseButton  = viewCloseButton {
            containerView.addSubview(theViewCloseButton)
        }
        
        
        // At this step in the container View we have from the bottom to top: ToVC, VisualEffect, ImageView
        
        // Start the animation
        let animator = UIViewPropertyAnimator(duration: POIDetailImagesDismissAnimationController.TRANSITION_DURATION, curve: .easeOut) {
            // Make progressively the image smaller
            if isVideoImage {
                // It's directly the background view when it's a video
                backgroundView?.frame = newTargetFrame
            } else {
                // It's an image when it's an image (because the image can be zoom
                imageView?.frame = newTargetFrame
            }
            
            // Make progressively the from VC and the close button to disappear
            fromPoiImageVC.view.alpha = 0.0
            viewCloseButton?.alpha = 0.0
            
            // Make progressively the blur to become non blurred !
            visualEffectView.effect = nil
        }

        animator.addCompletion() { position in
            // Remove useless view from the container
            viewCloseButton?.removeFromSuperview()
            if !isVideoImage {
                imageView?.removeFromSuperview()
            }
            visualEffectView.removeFromSuperview()

            
            // Tell the system the animation is completed
            transitionContext.completeTransition(true)
        }

        animator.startAnimation()
    }
}

