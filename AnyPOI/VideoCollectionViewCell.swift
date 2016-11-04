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
    fileprivate var initDone = false
    
    func initialize(video:AVPlayerItem) {
        if !initDone {
            playerViewController.videoGravity = AVLayerVideoGravityResizeAspect
            //playerViewController.showsPlaybackControls = true
            
            translatesAutoresizingMaskIntoConstraints = false
            playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(playerViewController.view)
            
            // Add my own constraints
            
            var constraint = playerViewController.view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
            constraint.isActive = true
            addConstraint(constraint)
            constraint = playerViewController.view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            constraint.isActive = true
            addConstraint(constraint)
            constraint = playerViewController.view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            constraint.isActive = true
            addConstraint(constraint)
            constraint = playerViewController.view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)
            constraint.isActive = true
            addConstraint(constraint)
            layoutIfNeeded()
            //setNeedsLayout()
//            setNeedsDisplay()
            
            //playerViewController.view.frame = CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height)
            initDone = true
        }
        
        let player = AVPlayer(playerItem: video)
        playerViewController.player = player
    }

}
