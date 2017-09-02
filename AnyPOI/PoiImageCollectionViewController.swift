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

    @IBOutlet weak var theCollectionView: UICollectionView! {
        didSet {
            theCollectionView.backgroundColor = UIColor.black
            theCollectionView.delegate = self
            theCollectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var theFlowLayout: UICollectionViewFlowLayout! {
        didSet {
            theFlowLayout.itemSize = theCollectionView.frame.size
            theFlowLayout.sectionInset = UIEdgeInsetsMake(0,0,0,0)
            theFlowLayout.minimumLineSpacing = 0.0
        }
    }
    
    var assets:[PHAsset]!
    var startAssetIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black

        theCollectionView.reloadData()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theCollectionView.scrollToItem(at: IndexPath(row:startAssetIndex, section:0), at: .left, animated: true)
    }
    
    
    /// Resize the collectionView during device rotation
    ///
    /// - Parameters:
    ///   - size: New size of the viewController
    ///   - coordinator: coordinator for the animation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Compute the index of the image/video currently displayed
        let offset = self.theCollectionView.contentOffset;
        let index = round(offset.x / self.theCollectionView.bounds.size.width);
        
        // hide the collection view to avoid horrible animation during the rotation
        // animation is horrible due to the offset change
        theCollectionView.alpha = 0.0
        coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            // display the collectionView during the animation
            self.theCollectionView.alpha = 1.0
            
            // compute the new offset based on the index and the new size
            let newOffset = CGPoint(x: index * self.theCollectionView.frame.size.width, y: offset.y)
            self.theCollectionView.setContentOffset(newOffset, animated: false)
        })
    }

    
    /// Invalidate the layout of the FlowLayout, it's mandatory for the rotation
    override func viewWillLayoutSubviews() {
        theFlowLayout.invalidateLayout()
        super.viewWillLayoutSubviews()
    }
    
    
    /// Set the size of the items (mandatory for the rotation)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        theFlowLayout.itemSize = theCollectionView.frame.size
    }

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
    
    
    /// Stop the video when the user starts to scroll
    ///
    /// - Parameter scrollView: the scrollView which is the CollectionView
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        for cell in theCollectionView.visibleCells {
            if cell is VideoCollectionViewCell {
                let videoCell = cell as! VideoCollectionViewCell
                videoCell.resetPlayer()
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if assets[indexPath.row].mediaType == .video {
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: storyboard.VideoCollectionViewCellId, for: indexPath) as! VideoCollectionViewCell
            
            theCell.configureWith(asset:assets[indexPath.row])
            return theCell
        } else {
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: storyboard.ImageCollectionViewCellId, for: indexPath) as! ImageCollectionViewCell
            
            theCell.configureWith(asset:assets[indexPath.row])
            return theCell
        }
    }
    
}
