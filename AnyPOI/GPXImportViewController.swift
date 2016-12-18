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
                tableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
           }
        }
    }
    @IBOutlet weak var importButton: UIBarButtonItem!
    
    var gpxURL:URL!
    
    fileprivate var allParsedGPXPois = [GPXPoi]()
    fileprivate var filteredGPXPois = [GPXPoi]()
    fileprivate var selectedState:[Bool]!
    
    var importOptions = GPXImportOptions()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = "Importing POIs"
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Background thread
            let parser = GPXParser(url: self.gpxURL)
            _ = parser.parse()
            self.allParsedGPXPois = parser.GPXPois
            self.updateFilteredGPXPois()

            for currentGPXRoute in parser.GPXRoutes {
                print("\(#function) Import route \(currentGPXRoute.routeName)")
            }

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
    
    func update(options:GPXImportOptions) {
        if importOptions != options {
            importButton.isEnabled = importOptions.importNew || importOptions.importUpdate
            importOptions = options
            
            updateFilteredGPXPois();
            
            theTableView.reloadData()
        }
    }
    
    fileprivate func updateFilteredGPXPois() {
        
        filteredGPXPois = allParsedGPXPois.filter { (currentGPXPoi) -> Bool in
            if !importOptions.textFilter.isEmpty && !currentGPXPoi.poiName.localizedCaseInsensitiveContains(importOptions.textFilter) {
                return false
            }
            
            if !importOptions.merge {
                return true
            } else {
                if currentGPXPoi.isPoiAlreadyExist {
                    if importOptions.importUpdate {
                        return true
                    }
                } else if importOptions.importNew {
                    return true
                }
            }
            return false
        }
        
        selectedState = Array(repeating: true, count: filteredGPXPois.count)
    }
    

    @IBAction func ImportButtonPushed(_ sender: UIBarButtonItem) {
        let selectedPoisForImport = selectedState.filter { return $0 }
        
        let alertActionSheet = UIAlertController(title: "Warning", message: "Do you really want to import \(selectedPoisForImport.count) POIs ?", preferredStyle: .alert)
        alertActionSheet.addAction(UIAlertAction(title:  "Import", style: .default) { alertAction in
            //FIXEDME: It should by done in background!
            for index in 0...(self.filteredGPXPois.count - 1) {
                if self.selectedState[index] {
                    self.filteredGPXPois[index].importGPXPoi(options:self.importOptions)
                }
            }
            
            self.dismiss(animated: true, completion: nil)
        })
        
        alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { alertAction in
        })
        
        present(alertActionSheet, animated: true, completion: nil)
        
        

        
//        PKHUD.sharedHUD.dimsBackground = true
//        HUD.show(.progress)
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            for index in 0...(self.GPXPois.count - 1) {
//                if self.selectedState[index] {
//                    self.GPXPois[index].importGPXPoi()
//                }
//            }
//            DispatchQueue.main.async(execute: {
//                HUD.hide()
//                self.dismiss(animated: true, completion: nil)
//            })
//       }
    }
    
    @IBAction func cancelButtonPushed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func isNewPoi(poi:GPXPoi) -> Bool {
        if importOptions.merge {
            return !poi.isPoiAlreadyExist
        } else {
            return true
        }
    }
    
    fileprivate struct storyboard {
        static let openImportOptions = "openGPXImportOptionsId"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == storyboard.openImportOptions {
            let viewController = segue.destination as! GPXImportOptionsViewController
            viewController.importOptions = importOptions
            viewController.importViewController = self
        }
    }
}

extension GPXImportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return filteredGPXPois.count
        }
    }
    
    struct CellId {
        static let GPXImportCellId = "GPXImportCellId"
        static let ImportDescriptionCellId = "ImportDescriptionCellId"
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else {
            return "POIs to import"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.ImportDescriptionCellId, for: indexPath) as! ImportTextualDescriptionTableViewCell
            cell.texttualDescriptionLabel?.attributedText = importOptions.textualDescription
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportCellId, for: indexPath) as! GPXImportTableViewCell
            
            let poi = filteredGPXPois[indexPath.row]
            if isNewPoi(poi:poi) {
                cell.initWith(poi: poi, updatedPoi: false)
            } else {
                cell.initWith(poi: poi, updatedPoi: true)
            }
            
            cell.tag = indexPath.row
            if selectedState[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
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
}

