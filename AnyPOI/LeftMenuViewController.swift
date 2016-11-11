//
//  LeftMenuViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import SafariServices

class LeftMenuViewController: UIViewController {
    
    let menuTitles = [NSLocalizedString("MapMenuTitle",comment:""), NSLocalizedString("PointOfInterestMenuTitle",comment:""), NSLocalizedString("TravelsMenuTitle",comment:""), NSLocalizedString("OptionsMenuTitle",comment:"")]

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            theTableView.delegate = self
            theTableView.dataSource = self
            theTableView.estimatedRowHeight = 69
            theTableView.rowHeight = UITableViewAutomaticDimension
            theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
        }
    }
    
    weak var container:ContainerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func icons8ButtonPushed(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: "https://icons8.com", delegate: self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LeftMenuViewController : SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // Nothing to do
    }

}

extension LeftMenuViewController : UITableViewDataSource, UITableViewDelegate {
    //MARK: UITableViewDataSource
    struct Row {
        static let Map = 0
        static let POIs = 1
        static let Route = 2
        static let Options = 3
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuTitles.count + 1
    }
    
    struct storyboard {
        static let LeftMenuPOIsTableViewCellId = "LeftMenuPOIsTableViewCellId"
        static let LeftMenuCellId = "LeftMenuCellId"
        static let MenuAboutCellId = "MenuAboutCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row < menuTitles.count {
            if indexPath.row == Row.POIs {
                let theCell = theTableView.dequeueReusableCell(withIdentifier: storyboard.LeftMenuPOIsTableViewCellId, for: indexPath) as! LeftMenuPOIsTableViewCell
                theCell.pinView.animatesDrop = false
                theCell.pinView.canShowCallout = false
                theCell.pinView.pinTintColor = ColorsUtils.defaultGroupColor()
                theCell.menuTitle.text = menuTitles[indexPath.row]
                return theCell
            } else {
                
                let theCell = theTableView.dequeueReusableCell(withIdentifier: storyboard.LeftMenuCellId, for: indexPath) as! LeftMenuTableViewCell
                theCell.menuTitle.text = menuTitles[indexPath.row]
                
                switch indexPath.row {
                case Row.Map:
                    theCell.imageMenu.image = UIImage(named: "Geography-40")
                case Row.Route:
                    theCell.imageMenu.image = UIImage(named: "Waypoint Map-40")
                case Row.Options:
                    theCell.imageMenu.image = UIImage(named: "Settings-40")
                default:
                    break
                }
                
                return theCell
            }
        } else {
            let theCell =  theTableView.dequeueReusableCell(withIdentifier: storyboard.MenuAboutCellId, for: indexPath) as! LeftMenuAboutTableViewCell
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
            
            theCell.buildLabel.text = "\(NSLocalizedString("BuildLeftMenuViewController", comment: "")) \(version) (\(build))"
            
            return theCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            container.showCenterView(.map)
        } else if indexPath.row == 1 {
            container.showCenterView(.poiManager)
        } else if indexPath.row == 2 {
            container.showCenterView(.travels)
        } else if indexPath.row == 3 {
            container.showCenterView(.options)
        }
    }
    
 }
