//
//  LeftMenuViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 04/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LeftMenuViewController : UITableViewDataSource, UITableViewDelegate {
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuTitles.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath as NSIndexPath).row < menuTitles.count {
            let theCell = theTableView.dequeueReusableCell(withIdentifier: "LeftMenuCellId", for: indexPath) as! LeftMenuTableViewCell
            theCell.menuTitle.text = menuTitles[(indexPath as NSIndexPath).row]
             return theCell
        } else {
            let theCell =  theTableView.dequeueReusableCell(withIdentifier: "MenuAboutCellId", for: indexPath) as! LeftMenuAboutTableViewCell
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
            
            theCell.buildLabel.text = "\(NSLocalizedString("BuildLeftMenuViewController", comment: "")) \(version) (\(build))"
            
            return theCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            container.showCenterView(.map)
        } else if (indexPath as NSIndexPath).row == 1 {
            container.showCenterView(.poiManager)
        } else if (indexPath as NSIndexPath).row == 2 {
            container.showCenterView(.travels)
        } else if (indexPath as NSIndexPath).row == 3 {
            container.showCenterView(.options)
        }
    }
    
 }
