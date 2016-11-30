//
//  GPXImportViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 30/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import PKHUD

class GPXImportViewController: UIViewController {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                tableView.estimatedRowHeight = 80
                tableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    var gpxURL:URL!
    
    fileprivate var GPXPois = [GPXPoi]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
   }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = "Importing POIs"
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Background thread
            let parser = GPXParser(url: self.gpxURL)
            _ = parser.parse()
            self.GPXPois = parser.GPXPois
            DispatchQueue.main.async(execute: {
                self.theTableView.reloadData()
                HUD.hide()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func ImportButtonPushed(_ sender: UIBarButtonItem) {
        for currentGPXPoi in GPXPois {
            currentGPXPoi.importGPXPoi()
        }
    }
    
    @IBAction func cancelButtonPushed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}

extension GPXImportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GPXPois.count
    }
    
    struct CellId {
        static let GPXImportCellId = "GPXImportCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportCellId, for: indexPath) as! GPXImportTableViewCell
        
        cell.poiDisplayName.text = GPXPois[indexPath.row].poiName
        
        return cell
    }
}
