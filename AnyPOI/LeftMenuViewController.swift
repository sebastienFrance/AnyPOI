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
    
    var menuTitles = [NSLocalizedString("MapMenuTitle",comment:""),
                      NSLocalizedString("PointOfInterestMenuTitle",comment:""),
                      NSLocalizedString("TravelsMenuTitle",comment:""),
                      NSLocalizedString("OptionsMenuTitle",comment:""),
                      
                      NSLocalizedString("HelpMenuTitle",comment:"")
    //        NSLocalizedString("PurchaseMenuTitle", comment:"")
    ]

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
        #if DEBUG
            menuTitles.append("Debug")
        #endif

        super.viewDidLoad()
    }

    @IBAction func anyPOIButtonPushed(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: "http://sebbrugalieres.fr/anypoi/AnyPOI/Presentation.html", delegate: self)
    }

    @IBAction func icons8ButtonPushed(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: "https://icons8.com", delegate: self)
    }
    @IBAction func alamoFireButtonPushed(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: "https://github.com/Alamofire/Alamofire", delegate: self)
   }
    @IBAction func pkhudButtonPushed(_ sender: UIButton) {
        Utilities.openSafariFrom(self, url: "https://github.com/pkluz/PKHUD", delegate: self)
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
    private struct Row {
        static let Map = 0
        static let POIs = 1
        static let Route = 2
        static let Options = 3
        static let Help = 4
        static let Debug = 5
        //static let Purchase = 5
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return  1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return menuTitles.count + 1
        } else {
            return 0
        }
    }
    
    private struct storyboard {
        static let LeftMenuPOIsTableViewCellId = "LeftMenuPOIsTableViewCellId"
        static let LeftMenuCellId = "LeftMenuCellId"
        static let MenuAboutCellId = "MenuAboutCellId"
        static let LeftMenuPurchaseTableViewCellId = "LeftMenuPurchaseTableViewCellId"
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == Row.POIs {
                let theCell = cell as! LeftMenuPOIsTableViewCell
                theCell.pinView.animatesWhenAdded = false
                theCell.pinView.canShowCallout = false
                theCell.pinView.glyphTintColor = ColorsUtils.defaultGroupColor()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row < menuTitles.count {
            if indexPath.row == Row.POIs {
                let theCell = theTableView.dequeueReusableCell(withIdentifier: storyboard.LeftMenuPOIsTableViewCellId, for: indexPath) as! LeftMenuPOIsTableViewCell
                theCell.menuTitle.text = menuTitles[indexPath.row]
                return theCell
            } else {
                
                let theCell = theTableView.dequeueReusableCell(withIdentifier: storyboard.LeftMenuCellId, for: indexPath) as! LeftMenuTableViewCell
                theCell.menuTitle.text = menuTitles[indexPath.row]
                
                switch indexPath.row {
                case Row.Map:
                    theCell.imageMenu.image = #imageLiteral(resourceName: "Geography-30")
                case Row.Route:
                    theCell.imageMenu.image = #imageLiteral(resourceName: "Waypoint Map-30")
                case Row.Options:
                    theCell.imageMenu.image = #imageLiteral(resourceName: "Settings-30")
                case Row.Help:
                    theCell.imageMenu.image = #imageLiteral(resourceName: "Help-30")
//                case Row.Purchase:
//                    theCell.imageMenu.image = #imageLiteral(resourceName: "Apple App Store-30")
                case Row.Debug:
                    theCell.imageMenu.image = #imageLiteral(resourceName: "Apple App Store-30")
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
        if indexPath.row == Row.Map {
            container.showCenterView(.map)
        } else if indexPath.row == Row.POIs {
            container.showCenterView(.poiManager)
        } else if indexPath.row == Row.Route {
            container.showCenterView(.travels)
        } else if indexPath.row == Row.Options {
            container.showCenterView(.options)
        } else if indexPath.row == Row.Help {
            performSegue(withIdentifier: "showHelpId", sender: nil)
        } else if indexPath.row == Row.Debug {
            container.showCenterView(.debug)
        }
//        } else if indexPath.row == Row.Purchase {
//            container.showCenterView(.purchase)
//        }
    }
    
 }
