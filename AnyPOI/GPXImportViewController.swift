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
    
    fileprivate var allParsedGPXRoutes = [GPXRoute]()
    fileprivate var filteredGPXRoutes = [GPXRoute]()
    fileprivate var routeSelectedState:[Bool]!
   
    var importOptions = GPXImportOptions()
    
    fileprivate var dataParsed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !dataParsed {
            dataParsed = true
            PKHUD.sharedHUD.dimsBackground = true
            HUD.show(.progress)
            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
            hudBaseView.titleLabel.text = "Importing POIs"
            
            DispatchQueue.global(qos: .userInitiated).async {
                // Background thread
                let parser = GPXParser(url: self.gpxURL)
                _ = parser.parse()
                
                // Remove the GPX file from the disk
                do {
                   try FileManager.default.removeItem(at: self.gpxURL)
                } catch {
                    print("\(#function) warning file \(self.gpxURL.absoluteString) cannot be deleted")
                }
                
                self.allParsedGPXPois = parser.GPXPois
                self.updateFilteredGPXPois()
                
                self.allParsedGPXRoutes = parser.GPXRoutes
                self.updateFilteredGPXRoutes()
                
                DispatchQueue.main.async(execute: {
                    self.theTableView.reloadData()
                    HUD.hide()
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func update(options:GPXImportOptions) {
        if importOptions != options {
            
            // FIXEDME: should take into account routes !
       //     importButton.isEnabled = importOptions.poiOptions.importNew || importOptions.poiOptions.importUpdate
           importOptions = options
            
            updateFilteredGPXPois()
            updateFilteredGPXRoutes()
          
            theTableView.reloadData()
        }
    }
    
    
    fileprivate func updateFilteredGPXPois() {
        
        filteredGPXPois = allParsedGPXPois.filter { (currentGPXPoi) -> Bool in
            if !importOptions.poiOptions.textFilter.isEmpty && !currentGPXPoi.poiName.localizedCaseInsensitiveContains(importOptions.poiOptions.textFilter) {
                return false
            }
            
            if importOptions.poiOptions.importAsNew {
                return true
            } else {
                if currentGPXPoi.isPoiAlreadyExist {
                    if importOptions.poiOptions.importUpdate {
                        return true
                    }
                } else if importOptions.poiOptions.importNew {
                    return true
                }
            }
            return false
        }
        
        selectedState = Array(repeating: true, count: filteredGPXPois.count)
        importButton.isEnabled = filteredGPXPois.count > 0 || filteredGPXRoutes.count > 0
    }
    
    fileprivate func updateFilteredGPXRoutes() {
        
        filteredGPXRoutes = allParsedGPXRoutes.filter { (currentGPXRoute) -> Bool in
            
            if importOptions.routeOptions.importAsNew {
                return true
            } else {
                if currentGPXRoute.isRouteAlreadyExist {
                    if importOptions.routeOptions.importUpdate {
                        return true
                    }
                } else if importOptions.routeOptions.importNew {
                    return true
                }
            }
            return false
        }
        
        routeSelectedState = Array(repeating: true, count: filteredGPXRoutes.count)
        importButton.isEnabled = filteredGPXPois.count > 0 || filteredGPXRoutes.count > 0
   }

    

    @IBAction func ImportButtonPushed(_ sender: UIBarButtonItem) {
        let selectedPoisForImport = selectedState.filter { return $0 }
        let selectedRouteForImport = routeSelectedState.filter { return $0 }
        
        var message:String
        if selectedPoisForImport.count > 0 && selectedRouteForImport.count > 0 {
            message = String(format:NSLocalizedString("GPXImport %d POIs and %d route", comment: ""), selectedPoisForImport.count, selectedRouteForImport.count)
        } else if selectedRouteForImport.count > 0 {
            message = String(format:NSLocalizedString("GPXImport %d route", comment: ""), selectedRouteForImport.count)
        } else {
            message = String(format:NSLocalizedString("GPXImport %d POIs", comment: ""), selectedPoisForImport.count)
        }
        
        let alertActionSheet = UIAlertController(title: NSLocalizedString("Warning", comment: ""),
                                                 message: message,
                                                 preferredStyle: .alert)
        alertActionSheet.addAction(UIAlertAction(title:  NSLocalizedString("ImportAction", comment: ""), style: .default) { alertAction in
            //FIXEDME: It should by done in background!
            var importedPOIs = [PointOfInterest]()
            for index in 0...(self.filteredGPXPois.count - 1) {
                if self.selectedState[index] {
                    if let poi = self.filteredGPXPois[index].importGPXPoi(options:self.importOptions) {
                        importedPOIs.append(poi)
                    }
                }
            }

            for index in 0...(self.filteredGPXRoutes.count - 1) {
                if self.routeSelectedState[index] {
                    self.filteredGPXRoutes[index].importIt(options:self.importOptions, importedPOIs:importedPOIs)
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
        return importOptions.poiOptions.importAsNew ? true : !poi.isPoiAlreadyExist
    }
    
    func isNewRoute(route:GPXRoute) -> Bool {
        return importOptions.routeOptions.importAsNew ? true : !route.isRouteAlreadyExist
    }
    
    fileprivate struct storyboard {
        static let openImportOptions = "openGPXImportOptionsId"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == storyboard.openImportOptions {
            let viewController = segue.destination as! GPXImportOptionsTableViewController
            viewController.importOptions = importOptions
            viewController.importViewController = self
            viewController.enableRouteOptions = allParsedGPXRoutes.count > 0
        }
    }
}

extension GPXImportViewController: UITableViewDelegate, UITableViewDataSource {
    
    struct Sections {
        static let importDescription = 0
        static let routes = 1
        static let pois = 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.importDescription:
            return 1
        case Sections.pois:
            return filteredGPXPois.count
        case Sections.routes:
            return filteredGPXRoutes.count
        default:
            return 0
        }
     }
    
    struct CellId {
        static let GPXImportCellId = "GPXImportCellId"
        static let ImportDescriptionCellId = "ImportDescriptionCellId"
        static let GPXImportRouteTableViewCellId = "GPXImportRouteTableViewCellId"
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.importDescription:
            return nil
        case Sections.pois:
            return NSLocalizedString("Points of interests", comment: "")
        case Sections.routes:
            return allParsedGPXRoutes.count == 0 ? nil : NSLocalizedString("Routes", comment: "")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.importDescription:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.ImportDescriptionCellId, for: indexPath) as! ImportTextualDescriptionTableViewCell
            
            let descriptionString = NSMutableAttributedString()
            
            if allParsedGPXRoutes.count > 0 {
                descriptionString.append(NSAttributedString(string:"Routes: ", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
                descriptionString.append(importOptions.routeTextualDescription)
                descriptionString.append(NSAttributedString(string:"\n"))
            }
            
            descriptionString.append(NSAttributedString(string:"Points of interests: ", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
            descriptionString.append(importOptions.poiTextualDescription)
            
            cell.texttualDescriptionLabel?.attributedText = descriptionString
            return cell
        case Sections.pois:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportCellId, for: indexPath) as! GPXImportTableViewCell
            
            let poi = filteredGPXPois[indexPath.row]
            cell.initWith(poi: poi, isPOINew: isNewPoi(poi:poi))
            
            cell.tag = indexPath.row
            if selectedState[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        case Sections.routes:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportRouteTableViewCellId, for: indexPath) as! GPXImportRouteTableViewCell
            cell.initWith(route:filteredGPXRoutes[indexPath.row], isRouteNew: isNewRoute(route:filteredGPXRoutes[indexPath.row]))
            
            cell.tag = indexPath.row
            if routeSelectedState[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }

            return cell
        default:
            return UITableViewCell()
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Sections.pois:
            if let cell = tableView.cellForRow(at: indexPath) as? GPXImportTableViewCell {
                if selectedState[indexPath.row] {
                    cell.accessoryType = .none
                    selectedState[indexPath.row] = false
                } else {
                    cell.accessoryType = .checkmark
                    selectedState[indexPath.row] = true
                }
            }
        case Sections.routes:
            if let cell = tableView.cellForRow(at: indexPath) as? GPXImportRouteTableViewCell {
                if routeSelectedState[indexPath.row] {
                    cell.accessoryType = .none
                    routeSelectedState[indexPath.row] = false
                } else {
                    cell.accessoryType = .checkmark
                    routeSelectedState[indexPath.row] = true
                }
            }
        default:
            return
        }
    }
}

