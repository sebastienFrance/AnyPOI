//
//  CategoriesTableViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 11/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoriesTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scopeFilterSegmentedControl: UISegmentedControl!
    
    func initWith(_ selectedFilter:SearchController.ScopeFilter) {
        switch selectedFilter {
        case .all:
            scopeFilterSegmentedControl.selectedSegmentIndex = 0
        case .localSearch:
            scopeFilterSegmentedControl.selectedSegmentIndex = 1
        case .others:
            scopeFilterSegmentedControl.selectedSegmentIndex = 2
        }
    }

    
    func setCollectionViewDataSourceDelegate
        <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (_ dataSourceDelegate: D, forRow row: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }

    var collectionViewOffset: CGFloat {
        get {
            return collectionView.contentOffset.x
        }
        
        set {
            collectionView.contentOffset.x = newValue
        }
    }
}
