//
//  ImageCollectionViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 01/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var theScrollView: UIScrollView!
    @IBOutlet weak var theImageView: UIImageView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return theImageView
    }

}
