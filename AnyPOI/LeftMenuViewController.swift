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
            theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuTitles.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row < menuTitles.count {
            let theCell = theTableView.dequeueReusableCellWithIdentifier("LeftMenuCellId", forIndexPath: indexPath) as! LeftMenuTableViewCell
            theCell.menuTitle.text = menuTitles[indexPath.row]
             return theCell
        } else {
            return theTableView.dequeueReusableCellWithIdentifier("MenuAboutCellId", forIndexPath: indexPath)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            container.showCenterView(.Map)
        } else if indexPath.row == 1 {
            container.showCenterView(.PoiManager)
        } else if indexPath.row == 2 {
            container.showCenterView(.Travels)
        } else if indexPath.row == 3 {
            container.showCenterView(.Options)
        }
    }
    
 }
