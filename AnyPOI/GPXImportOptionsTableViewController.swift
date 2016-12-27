//
//  GPXImportOptionsTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 23/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXImportOptionsTableViewController: UITableViewController {

    @IBOutlet weak var textualDescription: UILabel!
    
    @IBOutlet weak var poiImportAsNewSwitch: UISwitch!
    @IBOutlet weak var poiMergeImportNewSwitch: UISwitch!
    @IBOutlet weak var poiMergeImportUpdateSwitch: UISwitch!
    @IBOutlet weak var poiTextFilter: UITextField!
    
    @IBOutlet weak var poiMergeImportNewLabel: UILabel!
    @IBOutlet weak var poiMergeImportUpdateLabel: UILabel!
    @IBOutlet weak var routeImportAsNewSwitch: UISwitch!
    
    var importOptions:GPXImportOptions!
    var importViewController:GPXImportViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        poiTextFilter.delegate = self
       
        refreshDisplayedState()
    }
    
    
    /// Refresh the buttons and textual description based on importOptions configuraton
    /// and update the GPXImportViewController with the new importOptions
    func refreshDisplayedState() {
        routeImportAsNewSwitch.isOn = importOptions.routeOptions.importAsNew
        poiImportAsNewSwitch.isOn = importOptions.poiOptions.importAsNew
        
        poiMergeImportNewSwitch.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportUpdateSwitch.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportNewLabel.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportUpdateLabel.isEnabled = !importOptions.poiOptions.importAsNew
        if importOptions.poiOptions.importAsNew {
            poiMergeImportNewSwitch.isOn = false
            poiMergeImportUpdateSwitch.isOn = false
       } else {
            poiMergeImportNewSwitch.isOn = importOptions.poiOptions.importNew
            poiMergeImportUpdateSwitch.isOn = importOptions.poiOptions.importUpdate
        }
        
        textualDescription.attributedText = importOptions.textualDescription
        importViewController.update(options: importOptions)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func switchRouteImportAsNew(_ sender: UISwitch) {
        importOptions.routeOptions.importAsNew = sender.isOn
        refreshDisplayedState()
    }

    @IBAction func switchPOIImportAsNew(_ sender: UISwitch) {
        importOptions.poiOptions.importAsNew = sender.isOn
        importOptions.poiOptions.importNew = !importOptions.poiOptions.importAsNew
        importOptions.poiOptions.importUpdate = !importOptions.poiOptions.importAsNew
        refreshDisplayedState()
    }
    
    @IBAction func switchPOIMergeImportNew(_ sender: UISwitch) {
        importOptions.poiOptions.importNew = sender.isOn
        refreshDisplayedState()
    }
    
    // MARK: - Table view data source
    @IBAction func switchPOIMergeImportUpdate(_ sender: UISwitch) {
        importOptions.poiOptions.importUpdate = sender.isOn
        refreshDisplayedState()
   }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}

extension GPXImportOptionsTableViewController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        importOptions.poiOptions.textFilter = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        textualDescription.attributedText = importOptions.textualDescription
        tableView.reloadRows(at: [IndexPath(row:0, section:0)], with: .none)
        importViewController.update(options: importOptions)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        importOptions.poiOptions.textFilter = ""
        textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        textualDescription.attributedText = importOptions.textualDescription
        importViewController.update(options: importOptions)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

