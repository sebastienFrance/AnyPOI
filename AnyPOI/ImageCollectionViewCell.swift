//
//  ImageCollectionViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 01/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos

class ImageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var theScrollView: UIScrollView!
    @IBOutlet weak var theImageView: UIImageView!
    
    fileprivate var isLoadingImage = false
    fileprivate var requestId = PHImageRequestID()
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return theImageView
    }

    func configureWith(asset:PHAsset) {
        if isLoadingImage {
            PHImageManager.default().cancelImageRequest(requestId)
        } else {
            isLoadingImage = true
        }
        
        
        let configuredOptions = PHImageRequestOptions()
        configuredOptions.deliveryMode = .opportunistic
        configuredOptions.isSynchronous = false
        configuredOptions.resizeMode = .fast
        configuredOptions.isNetworkAccessAllowed = true
        configuredOptions.progressHandler = nil
        
        // The Handler can be called multiple times when images with higher resolution are loaded
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        requestId = PHImageManager.default().requestImage(for: asset,
                                              targetSize: size,
                                              contentMode: .aspectFit,
                                              options: configuredOptions) { result, info in
                                                self.isLoadingImage = false
                                                if let resultImage = result {
                                                    self.theImageView.image = resultImage
                                                    self.theScrollView.delegate = self
                                                }
        }
    }
}
