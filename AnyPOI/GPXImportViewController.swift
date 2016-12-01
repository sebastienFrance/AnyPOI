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
                tableView.estimatedRowHeight = 70
                tableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    var gpxURL:URL!
    
    fileprivate var GPXPois = [GPXPoi]()
    fileprivate var selectedState:[Bool]!

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
            self.selectedState = Array(repeating: true, count: self.GPXPois.count)
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
        for index in 0...(GPXPois.count - 1) {
            if selectedState[index] {
                GPXPois[index].importGPXPoi()
            }
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
        cell.poiDescription.text = GPXPois[indexPath.row].poiDescription
        cell.poiImageCategory.image = GPXPois[indexPath.row].poiCategory.icon
        
        cell.tag = indexPath.row
        if selectedState[indexPath.row] {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GPXImportTableViewCell {
            if selectedState[indexPath.row] {
                cell.accessoryType = .none
                selectedState[indexPath.row] = false
            } else {
                cell.accessoryType = .checkmark
                selectedState[indexPath.row] = true
            }
        }
    }
}
