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
            theCollectionView.delegate = self
            theCollectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var theFlowLayout: UICollectionViewFlowLayout! {
        didSet {
            theFlowLayout.minimumLineSpacing = 40 // Min space between items on the same row
            theFlowLayout.minimumInteritemSpacing = 0 // Min Space between items on the same column (we have only 1 item)
            theFlowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 40)
        }
    }
    
    var assets:[PHAsset]!
    var startAssetIndex = 0

    @IBOutlet weak var theCloseButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        theCollectionView.reloadData()
    }
    
    /// This method is used to get the visible image and its rect when the viewController is dismissed
    /// and we need to perform the animated transition. It provides the initial image and rect to start the animation
    func getVisibleRect() -> CGRect? {
        if theCollectionView.visibleCells.count > 0  {
            if let visibleCell = theCollectionView.visibleCells[0] as? ImageCollectionViewCell {
                let targetFrame = CGRect(x: -visibleCell.theScrollView.contentOffset.x,
                                         y: -visibleCell.theScrollView.contentOffset.y,
                                         width: visibleCell.theImageView.frame.width,
                                         height: visibleCell.theImageView.frame.height)
                
                return targetFrame
            } else if let visibleCell = theCollectionView.visibleCells[0] as? VideoCollectionViewCell {
                let targetFrame = theCollectionView.convert(visibleCell.frame, to: nil)
                return targetFrame
            }
        }
        return nil
    }
    
    var isDisplayedCellVideo:Bool {
        if theCollectionView.visibleCells.count <= 0 {
            return false
        }
        
        let displayCell = theCollectionView.visibleCells[0]
        return displayCell is VideoCollectionViewCell
    }
    
    func getSnapshotViewFromVideoCell() -> UIView? {
        if isDisplayedCellVideo {
            let theVideoCell = theCollectionView.visibleCells[0] as! VideoCollectionViewCell
            let theViedeoCellView = theVideoCell.playerViewController.view
            return theViedeoCellView!.snapshotView(afterScreenUpdates: false)
        }
        
        return nil
    }
    
    func getSnapshotImageFromImageCell() -> UIImage? {
        if theCollectionView.visibleCells.count > 0, let visibleCell = theCollectionView.visibleCells[0] as? ImageCollectionViewCell  {
            return visibleCell.theImageView.image
        }
        return nil
    }
    
    func getSizeWhenImageWillAppear() -> CGSize {
        let indexFirstCell = IndexPath(row: startAssetIndex, section: 0)
        
        let layoutAttr = theFlowLayout.layoutAttributesForItem(at: indexFirstCell)
        return layoutAttr!.frame.size
    }
    
    @IBAction func closeButtonPushed(_ sender: UIButton) {
        
        for cell in theCollectionView.visibleCells {
            if cell is VideoCollectionViewCell {
                let videoCell = cell as! VideoCollectionViewCell
                videoCell.resetPlayer()
                videoCell.playerViewController.showsPlaybackControls = false
            }
        }

        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theCollectionView.scrollToItem(at: IndexPath(item:startAssetIndex, section:0), at: .left, animated: true)
        theCollectionView.layoutSubviews() // It's mandatory to make sure the collection view display the selected cell
    }
    
    
    

    /// Invalidate the layout of the FlowLayout, it's mandatory for the rotation
    override func viewWillLayoutSubviews() {
        theFlowLayout.invalidateLayout()
        super.viewWillLayoutSubviews()
    }
    
    
    /// Set the size of the items (mandatory for the rotation)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        theFlowLayout.itemSize = theCollectionView.bounds.size
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: PoiImageCollectionViewController.storyboard.VideoCollectionViewCellId, for: indexPath) as! VideoCollectionViewCell
            
            theCell.configureWith(asset:assets[indexPath.row])
            return theCell
        } else {
            let theCell = theCollectionView.dequeueReusableCell(withReuseIdentifier: PoiImageCollectionViewController.storyboard.ImageCollectionViewCellId, for: indexPath) as! ImageCollectionViewCell
            
            theCell.configureWith(asset:assets[indexPath.row], size:theCollectionView.frame.size)
            return theCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Size of the item is the width of the view and the height is the height of the collectionView
        // The collection view has a width > to te view because of linespacing between items (configured in Storyboard with constraints)
        // The view has a height > collectionView because of the space at the bottom that is reserved for the "close" button
        return CGSize(width: self.view.frame.width, height: theCollectionView.frame.height)
    }

}

