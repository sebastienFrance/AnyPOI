//
//  GPXImportOptionsViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXImportOptionsViewController: UIViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    var importOptions:GPXImportOptions!
    var importViewController:GPXImportViewController!

    @IBAction func switchOptionPressed(_ sender: UISwitch) {
        if sender.tag < 100 {
            switch sender.tag {
            case ImportOptionsRow.merge:
                importOptions.merge = sender.isOn
                if !importOptions.merge {
                    importOptions.importNew = true
                    importOptions.importUpdate = false
                }
            case ImportOptionsRow.importNew:
                importOptions.importNew = sender.isOn
            case ImportOptionsRow.importUpdate:
                importOptions.importUpdate = sender.isOn
            default:
                break
            }
        } else {
            importOptions.routeImportAsNew = sender.isOn
        }
        theTableView.reloadData()
    }
    
    @IBAction func closeButtonPressed(_ sender: UIBarButtonItem) {
        
        importViewController.update(options: importOptions)
        dismiss(animated: true, completion: nil)
    }
}

extension GPXImportOptionsViewController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        importOptions.textFilter = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        theTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        importOptions.textFilter = ""
        textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        theTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        return true
    }
}

extension GPXImportOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    struct Sections {
        static let TextualDescription = 0
        static let RouteOptions = 1
        static let POIOptions = 2
    }
    
    
     struct ImportOptionsRow {
        static let merge = 0
        static let importNew = 1
        static let importUpdate = 2
        static let textFilter = 3
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.TextualDescription:
            return nil
        case Sections.POIOptions:
            return "Point Of interest options"
        case Sections.RouteOptions:
            return "Route options"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.TextualDescription:
            return 1
        case Sections.POIOptions:
            return 4
        case Sections.RouteOptions:
            return 1
        default:
            return 0
        }
    }
    
    struct CellId {
        static let GPXImportOptionsCellId = "GPXImportOptionsCellId"
        static let GPXImportOptionsDescriptionCellId = "GPXImportOptionsDescriptionCellId"
        static let GPXImportOptionsTextFilterCellId = "GPXImportOptionsTextFilterCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.TextualDescription:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportOptionsDescriptionCellId, for: indexPath) as! ImportTextualDescriptionTableViewCell
            cell.texttualDescriptionLabel?.attributedText = importOptions.textualDescription
            return cell
        case Sections.POIOptions:
            if indexPath.row == ImportOptionsRow.textFilter {
                let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportOptionsTextFilterCellId, for: indexPath) as! GPXImportOptionsTextFilterTableViewCell
                cell.textFilter.text = importOptions.textFilter
                cell.textFilter.delegate = self
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportOptionsCellId, for: indexPath) as! GPXImportOptionsTableViewCell
                
                switch indexPath.row {
                case ImportOptionsRow.merge:
                    cell.cellTitle.text = "Merge"
                    cell.cellSwitch.isOn = importOptions.merge
                case ImportOptionsRow.importNew:
                    cell.cellSwitch.isEnabled = importOptions.merge
                    cell.cellTitle.isEnabled = importOptions.merge
                    if !importOptions.merge {
                        cell.cellSwitch.isOn = true
                    } else {
                        cell.cellSwitch.isOn = importOptions.importNew
                    }
                    cell.cellTitle.text = "Import new POI"
                case ImportOptionsRow.importUpdate:
                    cell.cellSwitch.isEnabled = importOptions.merge
                    cell.cellTitle.isEnabled = importOptions.merge
                    if !importOptions.merge {
                        cell.cellSwitch.isOn = false
                    } else {
                        cell.cellSwitch.isOn = importOptions.importUpdate
                        
                    }
                    cell.cellTitle.text = "Update"
                default:
                    break
                }
                
                cell.cellSwitch.tag = indexPath.row
                
                return cell
            }
        case Sections.RouteOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellId.GPXImportOptionsCellId, for: indexPath) as! GPXImportOptionsTableViewCell
            cell.cellTitle.text = "Import as new"
            cell.cellSwitch.isOn = importOptions.routeImportAsNew
            
            cell.cellSwitch.tag = 101
            
            return cell
        default:
            return UITableViewCell()
        }
    }
}
