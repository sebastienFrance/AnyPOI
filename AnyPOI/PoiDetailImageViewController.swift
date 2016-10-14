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

    @IBOutlet fileprivate weak var theScrollView: UIScrollView!
    @IBOutlet fileprivate weak var poiDetailImage: UIImageView!
    
    fileprivate var asset:PHAsset!
    fileprivate var hideStatusBar = false
   
    func initWithAsset(_ asset:PHAsset) {
        self.asset = asset
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadImage()
        theScrollView.delegate = self
    }
    
    override var prefersStatusBarHidden : Bool {
        return hideStatusBar
    }

    
    @IBAction func tapGestureRecognized(_ sender: AnyObject) {
        navigationController?.setNavigationBarHidden(!navigationController!.isNavigationBarHidden, animated: true)
        hideStatusBar = !hideStatusBar
        setNeedsStatusBarAppearanceUpdate()
   }
    
    func loadImage() {
        let configuredOptions = PHImageRequestOptions()
        configuredOptions.deliveryMode = .opportunistic
        configuredOptions.isSynchronous = false
        configuredOptions.resizeMode = .fast
        configuredOptions.isNetworkAccessAllowed = true
        configuredOptions.progressHandler = nil
        
        // The Handler can be called multiple times when images with higher resolution are loaded
        PHImageManager.default().requestImage(for: asset,
                                                             targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                                             contentMode: .aspectFit,
                                                             options: configuredOptions,
                                                             resultHandler: {(result, info)->Void in
                                                                if let resultImage = result {
                                                                    self.poiDetailImage.image = resultImage
                                                                }
        })

    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return poiDetailImage
    }

}
