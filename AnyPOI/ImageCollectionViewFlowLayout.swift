//
//  ImageCollectionViewFlowLayout.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 05/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class ImageCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
