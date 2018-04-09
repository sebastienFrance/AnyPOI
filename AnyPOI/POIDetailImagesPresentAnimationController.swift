//
//  POIDetailImagesPresentAnimationController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 05/04/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos

class POIDetailImagesPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    // Initial image and rect used to start the animation
    // Here the start image is very small
    private let initialFrame:CGRect
    private var initialCellImage:UIImage
    
    // Target image that must be displayed in the To ViewController
    // It's retreived asynchronously using the Asset
    private var imageView:UIImageView!

    private static let TRANSITION_DURATION = 0.6

    
    init(initialRect:CGRect, initialImage:UIImage) {
        self.initialFrame = initialRect
        self.initialCellImage = initialImage
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return POIDetailImagesPresentAnimationController.TRANSITION_DURATION
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let toPoiDetailsVC = transitionContext.viewController(forKey: .to) as? PoiImageCollectionViewController
            else {
                transitionContext.completeTransition(true)
                return
        }
        
        let containerView = transitionContext.containerView
        
        // Create an empty VisualEffect that will be used during the animation
        // to progressively perform the blur of the From ViewController
        let visualEffectView = UIVisualEffectView(effect: nil)
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)
        
        
        // Make invisible the To ViewController and its collectionView
        // The collectionView must becomes visible only when the full animation has been completed else the image begins to be displayed too soon
        toPoiDetailsVC.view.alpha = 0.0
        toPoiDetailsVC.theCollectionView.alpha = 0.0
        toPoiDetailsVC.view.frame = transitionContext.finalFrame(for: toPoiDetailsVC)

        
        containerView.addSubview(toPoiDetailsVC.view)
        
        //Create the imageVuew using the initial image
        imageView = UIImageView(frame: containerView.convert(initialFrame, from: nil))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.image = self.initialCellImage
        
        // Configure an Image Request to get an image with the target resolution
        let configuredOptions = PHImageRequestOptions()
        configuredOptions.deliveryMode = .opportunistic
        configuredOptions.isSynchronous = false
        configuredOptions.resizeMode = .fast
        configuredOptions.isNetworkAccessAllowed = true
        configuredOptions.progressHandler = nil
        
        // Get the size of the image as it should be displayed in the target VC (viewDidAppear() has not yet been called on the target ViewController at this step)
        let size = toPoiDetailsVC.getSizeWhenImageWillAppear()
        
        // Compute the real resolution of the image based on the scale of the screen (like X2, X3... depending on the device)
        let sizeWithScale = CGSize(width: size.width * UIScreen.main.scale , height: size.height * UIScreen.main.scale)
        
        // Request the image with the better resolution
        // When a new image it received it directly update the imageView that we have build for the animation
        let requestId = PHImageManager.default().requestImage(for: toPoiDetailsVC.assets[toPoiDetailsVC.startAssetIndex],
                                                          targetSize: sizeWithScale,
                                                          contentMode: .aspectFit,
                                                          options: configuredOptions) { result, info in
                                                            
                                                            // SEB: TBC
                                                            //self.isLoadingImage = false
                                                            if let resultImage = result {
                                                                self.imageView.image = resultImage
                                                            }
        }
        
        // Add the UIImageView to the containerView, it means we have from bottom to up the FromVC, VisualEffect, toVC, animated Image
        containerView.addSubview(imageView)
        
        // Start the animation
        let animator = UIViewPropertyAnimator(duration: POIDetailImagesPresentAnimationController.TRANSITION_DURATION, curve: .easeIn) {
            // Add progressively the blur effect
            visualEffectView.effect = UIBlurEffect(style: .light)
            
            // Increase progressively the size of the image to its target size
            // We need to add 20 points on y axis because of the status bar
            self.imageView.frame = CGRect(x: 0, y: 20, width: size.width , height: size.height)
            
            // Make the To ViewController progressively visible
            toPoiDetailsVC.view.alpha = 1.0
        }
        
        animator.addCompletion() { position in
            // Make the collection view visible
            toPoiDetailsVC.theCollectionView.alpha = 1.0
            
            // Remove all views that was just added for the animation
            self.imageView.removeFromSuperview()
            visualEffectView.removeFromSuperview()
            
            // Tell the system the animation is completed
            transitionContext.completeTransition(true)
        }
        
        // launch the animation
        animator.startAnimation()
    }
}
