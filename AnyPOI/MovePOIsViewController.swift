//
//  MovePOIsViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 19/08/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MovePOIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                tableView.estimatedRowHeight = 86
                tableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    var pois:[PointOfInterest]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancelButtonPushed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return POIDataManager.sharedInstance.getGroups().count + 1
    }
    
    struct storyboard {
        static let moveToGroupCellId = "moveToGroupCellId"
        static let moveCellHeaderId = "moveCellHeaderId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = theTableView.dequeueReusableCell(withIdentifier: storyboard.moveCellHeaderId, for: indexPath)
            return cell
        } else {
            let cell = theTableView.dequeueReusableCell(withIdentifier: storyboard.moveToGroupCellId, for: indexPath) as! MovePOIsTableViewCell
            
            cell.initWithGroup(POIDataManager.sharedInstance.getGroups()[indexPath.row - 1])
            
            return cell
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            let selectedGroup = POIDataManager.sharedInstance.getGroups()[indexPath.row - 1]
            for currentPOI in self.pois {
                if currentPOI.parentGroup != selectedGroup {
                    currentPOI.parentGroup = selectedGroup
                }
            }
            POIDataManager.sharedInstance.commitDatabase()
            self.dismiss(animated: true, completion: nil)
        }
    }
}


