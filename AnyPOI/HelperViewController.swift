//
//  HelperViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/03/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit

class HelperViewController: UIViewController {

    @IBOutlet weak var theCollectionView: UICollectionView! {
        didSet {
            theCollectionView.delegate = self
            theCollectionView.dataSource = self
        }
    }
    @IBOutlet weak var thePageControl: UIPageControl!
    @IBOutlet weak var bottomPageStackView: UIStackView!
    var isStartedFomMap = false
    
    private struct HelpData {
        let backgroundScreenshot:UIImage
        let title:String
        let description:String
    }
    
    private let helpPages = [
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "AddPOI1x"), title: NSLocalizedString("HelpAddPOITitle", comment: ""), description: NSLocalizedString("HelpAddPOIDescription", comment: "")),
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "POIDetails1x"), title: NSLocalizedString("HelpPOIDetailsTitle", comment: ""), description: NSLocalizedString("HelpPOIDetailsDescription", comment: "")),
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "CalloutTrip1x"), title: NSLocalizedString("HelpTripTitle", comment: ""), description: NSLocalizedString("HelpTripDescription", comment: "")),
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "CalloutSocial1x"), title: NSLocalizedString("HelpSocialTitle", comment: ""), description: NSLocalizedString("HelpSocialDescription", comment: "")),
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "CalloutUtilities1x"), title: NSLocalizedString("HelpUtilitiesTitle", comment: ""), description: NSLocalizedString("HelpUtilitiesDescription", comment: "")),
        HelpData(backgroundScreenshot: #imageLiteral(resourceName: "TravelNavigation1x"), title: NSLocalizedString("HelpTripNavigationTitle", comment: ""), description: NSLocalizedString("HelpTripNavigationDescription", comment: ""))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        thePageControl.numberOfPages = helpPages.count

        theCollectionView.reloadData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeButtonPushed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        if isStartedFomMap {
            MapViewController.instance?.showUserLocation()
        }
    }
}



extension HelperViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let indexPath = theCollectionView.indexPathsForVisibleItems.first {
            thePageControl.currentPage = indexPath.row
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Compute the height of the cell which is:
        // Size of the screen - height of the status bar - height of the bottom page (button + paging controller)
        return CGSize(width: view.frame.width, height: view.frame.height - bottomPageStackView.frame.height - UIApplication.shared.statusBarFrame.height)
    }
    
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return helpPages.count
    }
    
    fileprivate struct storyboard {
        static let helperCellId = "HelperCellId"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = theCollectionView.dequeueReusableCell(withReuseIdentifier: storyboard.helperCellId, for: indexPath) as! HelperCollectionViewCell
        
        let data = helpPages[indexPath.row]
        cell.theImage.image = data.backgroundScreenshot
        cell.theTitle.text = data.title
        cell.theDescription.text = data.description
        
        return cell
    }
}
