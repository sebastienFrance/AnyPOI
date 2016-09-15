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
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
    func initWith(selectedFilter:SearchController.ScopeFilter) {
        switch selectedFilter {
        case .All:
            scopeFilterSegmentedControl.selectedSegmentIndex = 0
        case .LocalSearch:
            scopeFilterSegmentedControl.selectedSegmentIndex = 1
        case .Others:
            scopeFilterSegmentedControl.selectedSegmentIndex = 2
        }
    }

    
    func setCollectionViewDataSourceDelegate
        <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>
        (dataSourceDelegate: D, forRow row: Int) {
        
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
