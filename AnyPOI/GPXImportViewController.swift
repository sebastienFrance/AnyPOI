//
//  GPXImportViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 30/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import PKHUD

struct selectedElement<T> {
    var element:T
    var isSelected = true
}


class GPXImportViewController: UIViewController {
    
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                tableView.estimatedRowHeight = 103
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
           }
        }
    }
    
    // Import button can be disabled when there's nothing to import
    @IBOutlet weak var importButton: UIBarButtonItem!
    
    var gpxURL:URL! // GPX file to be parsed
    
    
    fileprivate var allParsedGPXPois = [GPXPoi]()
    fileprivate var filteredGPXPois = [selectedElement<GPXPoi>]()
    
    fileprivate var allParsedGPXRoutes = [GPXRoute]()
    fileprivate var filteredGPXRoutes = [selectedElement<GPXRoute>]()
   
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
            hudBaseView.titleLabel.text = NSLocalizedString("ImportLoadingGPXFile", comment: "")
            
            DispatchQueue.global(qos: .userInitiated).async {
                // Background thread
                let parser = GPXParser(url: self.gpxURL)
                if !parser.parse() {
                    NSLog("\(#function) Warning, error during the parsing!")
                }
                
                // Remove the GPX file from the disk
                do {
                   try FileManager.default.removeItem(at: self.gpxURL)
                } catch {
                    NSLog("\(#function) warning file \(self.gpxURL.absoluteString) cannot be deleted")
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
    
    
    /// Compute list of filtered POIs and Routes using the import options
    /// This method should be called each time import options are changed (it's called 
    /// by the GPXImportOptionsViewController
    ///
    /// - Parameter options: import options that must be used
    func update(options:GPXImportOptions) {
        if importOptions != options {
            
            // Do computation only when something has changed
            importOptions = options
            updateFilteredGPXPois()
            updateFilteredGPXRoutes()
            theTableView.reloadData()
        }
    }
    
    
    /// Refresh the list of filtered POIs based on import options
    /// It resets the list of selected POIs and enable/disable the import button
    fileprivate func updateFilteredGPXPois() {
        
        filteredGPXPois.removeAll()
        for currentGPXPoi in allParsedGPXPois {
            if !importOptions.poiOptions.textFilter.isEmpty && !currentGPXPoi.poiName.localizedCaseInsensitiveContains(importOptions.poiOptions.textFilter) {
                continue
            }
            
            if importOptions.poiOptions.importAsNew ||
                (currentGPXPoi.isPoiAlreadyExist && importOptions.poiOptions.importUpdate) ||
                (!currentGPXPoi.isPoiAlreadyExist && importOptions.poiOptions.importNew) {
                filteredGPXPois.append(selectedElement(element: currentGPXPoi, isSelected: true))
            }
        }
        
        importButton.isEnabled = filteredGPXPois.count > 0 || filteredGPXRoutes.count > 0
    }
    
    /// Refresh the list of filtered routes based on import options
    /// It resets the list of selected routes and enable/disable the import button
    fileprivate func updateFilteredGPXRoutes() {
        
        filteredGPXRoutes.removeAll()
        for currentGPXRoute in allParsedGPXRoutes {
            if importOptions.routeOptions.importAsNew ||
                (currentGPXRoute.isRouteAlreadyExist && importOptions.routeOptions.importUpdate) ||
                (!currentGPXRoute.isRouteAlreadyExist && importOptions.routeOptions.importNew) {
                filteredGPXRoutes.append(selectedElement(element: currentGPXRoute, isSelected: true))
            }
        }
        
        importButton.isEnabled = filteredGPXPois.count > 0 || filteredGPXRoutes.count > 0
   }

    
    
    /// Trigger the import of selected POIs and Routes
    /// It requests the user to confirm before to launch the import
    /// At the end of the import this ViewController is dismissed
    ///
    /// - Parameter sender: button used to trigger the import
    @IBAction func ImportButtonPushed(_ sender: UIBarButtonItem) {
        let selectedPoisForImport = filteredGPXPois.filter { return $0.isSelected }
        let selectedRoutesForImport = filteredGPXRoutes.filter { return $0.isSelected }
        
        var message:String
        if selectedPoisForImport.count > 0 && selectedRoutesForImport.count > 0 {
            message = String(format:NSLocalizedString("GPXImport %d POIs and %d route", comment: ""), selectedPoisForImport.count, selectedRoutesForImport.count)
        } else if selectedRoutesForImport.count > 0 {
            message = String(format:NSLocalizedString("GPXImport %d route", comment: ""), selectedRoutesForImport.count)
        } else {
            message = String(format:NSLocalizedString("GPXImport %d POIs", comment: ""), selectedPoisForImport.count)
        }
        
        let alertActionSheet = UIAlertController(title: NSLocalizedString("Warning", comment: ""),
                                                 message: message,
                                                 preferredStyle: .alert)
        alertActionSheet.addAction(UIAlertAction(title:  NSLocalizedString("ImportAction", comment: ""), style: .default) { alertAction in
            var importedPOIs = [PointOfInterest]()
            selectedPoisForImport.forEach() {
                if let poi = $0.element.importIt(options:self.importOptions) {
                    importedPOIs.append(poi)
                }
            }
            
            selectedRoutesForImport.forEach() {
                $0.element.importIt(options:self.importOptions, importedPOIs:importedPOIs)
            }

            //GeoCodeMgr.sharedInstance.resolvePlacemarksBatch()
            self.dismiss(animated: true, completion: nil)
        })
        
        alertActionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { alertAction in
        })
        
        present(alertActionSheet, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPushed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    
    fileprivate struct storyboard {
        static let openImportOptions = "openGPXImportOptionsId"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == GPXImportViewController.storyboard.openImportOptions {
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
    
    fileprivate func isNewPoi(poi:GPXPoi) -> Bool {
        return importOptions.poiOptions.importAsNew ? true : !poi.isPoiAlreadyExist
    }
    
    fileprivate func isNewRoute(route:GPXRoute) -> Bool {
        return importOptions.routeOptions.importAsNew ? true : !route.isRouteAlreadyExist
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.importDescription:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.ImportDescriptionCellId, for: indexPath) as! ImportTextualDescriptionTableViewCell
            cell.initWith(importOptions: importOptions, isRouteEnabled: allParsedGPXRoutes.count > 0)
            return cell
        case Sections.pois:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportCellId, for: indexPath) as! GPXImportTableViewCell
            
            let currentElement = filteredGPXPois[indexPath.row]
            let poi = currentElement.element
            cell.initWith(poi: poi, isPOINew: isNewPoi(poi:poi))
            
            cell.tag = indexPath.row
            cell.accessoryType = currentElement.isSelected ? .checkmark : .none
            
            return cell
        case Sections.routes:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportRouteTableViewCellId, for: indexPath) as! GPXImportRouteTableViewCell
            let currentElement = filteredGPXRoutes[indexPath.row]
            cell.initWith(route:currentElement.element, isRouteNew: isNewRoute(route:currentElement.element))
            
            cell.tag = indexPath.row
            cell.accessoryType = currentElement.isSelected ? .checkmark : .none

            return cell
        default:
            return UITableViewCell()
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Sections.pois:
            if let cell = tableView.cellForRow(at: indexPath) as? GPXImportTableViewCell {
                cell.accessoryType = filteredGPXPois[indexPath.row].isSelected ? .none : .checkmark
                filteredGPXPois[indexPath.row].isSelected = !filteredGPXPois[indexPath.row].isSelected
            }
        case Sections.routes:
            if let cell = tableView.cellForRow(at: indexPath) as? GPXImportRouteTableViewCell {
                cell.accessoryType = filteredGPXRoutes[indexPath.row].isSelected ? .none : .checkmark
                filteredGPXRoutes[indexPath.row].isSelected = !filteredGPXRoutes[indexPath.row].isSelected
            }
        default:
            return
        }
    }
}

