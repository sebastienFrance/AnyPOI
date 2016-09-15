//
//  PoiDetailImageViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 02/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos

class PoiDetailImageViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet private weak var theScrollView: UIScrollView!
    @IBOutlet private weak var poiDetailImage: UIImageView!
    
    private var asset:PHAsset!
    private var hideStatusBar = false
   
    func initWithAsset(asset:PHAsset) {
        self.asset = asset
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadImage()
        theScrollView.delegate = self
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }

    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        navigationController?.setNavigationBarHidden(!navigationController!.navigationBarHidden, animated: true)
        hideStatusBar = !hideStatusBar
        setNeedsStatusBarAppearanceUpdate()
   }
    
    func loadImage() {
        let configuredOptions = PHImageRequestOptions()
        configuredOptions.deliveryMode = .Opportunistic
        configuredOptions.synchronous = false
        configuredOptions.resizeMode = .Fast
        configuredOptions.networkAccessAllowed = true
        configuredOptions.progressHandler = nil
        
        // The Handler can be called multiple times when images with higher resolution are loaded
        PHImageManager.defaultManager().requestImageForAsset(asset,
                                                             targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                                             contentMode: .AspectFit,
                                                             options: configuredOptions,
                                                             resultHandler: {(result, info)->Void in
                                                                if let resultImage = result {
                                                                    self.poiDetailImage.image = resultImage
                                                                }
        })

    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return poiDetailImage
    }

}
