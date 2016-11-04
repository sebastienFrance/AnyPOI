//
//  PoiImageCollectionViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 01/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Photos
import AVKit

class PoiImageCollectionViewController: UIViewController {

    @IBOutlet weak var theCollectionView: UICollectionView!
    @IBOutlet weak var theFlowLayout: UICollectionViewFlowLayout!

    override func viewDidLoad() {
        super.viewDidLoad()

        theCollectionView.delegate = self
        theCollectionView.dataSource = self
        automaticallyAdjustsScrollViewInsets = false
        theFlowLayout.itemSize = CGSize(width: theCollectionView.frame.size.width, height: theCollectionView.frame.size.height)
        theFlowLayout.sectionInset = UIEdgeInsetsMake(0,0,0,0)
        theFlowLayout.minimumLineSpacing = 0.0

        
        theCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
       
    }
    
    var assets:[PHAsset]!

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PoiImageCollectionViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    struct storyboard {
        static let VideoCollectionViewCellId = "VideoCollectionViewCellId"
        static let ImageCollectionViewCellId = "ImageCollectionViewCellId"
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsetsMake(0, 0, 0, 0)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
//        return CGSize(width: 0, height: 0)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: 0, height: 0)
//    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if assets[indexPath.row].mediaType == .video {
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: storyboard.VideoCollectionViewCellId, for: indexPath) as! VideoCollectionViewCell
            
            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = .automatic
            videoOptions.isNetworkAccessAllowed = false
        
            PHImageManager.default().requestPlayerItem(forVideo: assets[indexPath.row], options: videoOptions) { playerItem, info in
                if let videoItem = playerItem {
                    DispatchQueue.main.async {
                        theCell.initialize(video:videoItem)
                    }
                }
            }
            
            return theCell
        } else {
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: storyboard.ImageCollectionViewCellId, for: indexPath) as! ImageCollectionViewCell
            
            let configuredOptions = PHImageRequestOptions()
            configuredOptions.deliveryMode = .opportunistic
            configuredOptions.isSynchronous = false
            configuredOptions.resizeMode = .fast
            configuredOptions.isNetworkAccessAllowed = true
            configuredOptions.progressHandler = nil
            
            // The Handler can be called multiple times when images with higher resolution are loaded
            let size = CGSize(width: assets[indexPath.row].pixelWidth, height: assets[indexPath.row].pixelHeight)
            PHImageManager.default().requestImage(for: assets[indexPath.row],
                                                  targetSize: size,
                                                  contentMode: .aspectFit,
                                                  options: configuredOptions,
                                                  resultHandler: {(result, info)->Void in
                                                    if let resultImage = result {
                                                        theCell.theImageView.image = resultImage
                                                        theCell.theScrollView.delegate = theCell
                                                    }
            })
            

            return theCell
           
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if assets[indexPath.row].mediaType == .video {
            if let videoCell = cell as? VideoCollectionViewCell {
               // videoCell.playerViewController.player?.replaceCurrentItem(with: nil)
                videoCell.playerViewController.player?.pause()
            }
        }
    }
}
