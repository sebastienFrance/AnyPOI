//
//  VideoCollectionViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 01/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos
import AVKit

class VideoCollectionViewCell: UICollectionViewCell {
    
    fileprivate(set) var playerViewController = AVPlayerViewController()
    
    fileprivate var isLoadingVideo = false
    fileprivate var requestId = PHImageRequestID()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.black
        addSubview(playerViewController.view)
        playerViewController.videoGravity = AVLayerVideoGravity.resizeAspect.rawValue
        playerViewController.view.frame = CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height)
    }
    
    func resetPlayer() {
        playerViewController.player?.pause()
    }
    
    /// Configure the cell with a Video
    /// If the cell is already loading a video the loading is canceled and a new one is launched
    ///
    /// - Parameter asset: Contains the video
    func configureWith(asset:PHAsset) {
        if isLoadingVideo {
            PHImageManager.default().cancelImageRequest(requestId)
        } else {
            isLoadingVideo = true
        }
        

        playerViewController.player = nil
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .fastFormat
        videoOptions.isNetworkAccessAllowed = false
        
        requestId = PHImageManager.default().requestPlayerItem(forVideo: asset, options: videoOptions) { playerItem, info in
            self.isLoadingVideo = false
            if let videoItem = playerItem {
                DispatchQueue.main.async {
                    let player = AVPlayer(playerItem: videoItem)
                    self.playerViewController.showsPlaybackControls = true
                    self.playerViewController.player = player
                }
            }
        }
    }
    
}
