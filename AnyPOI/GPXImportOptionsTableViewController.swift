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
    
    @IBOutlet weak var poiMergeSwitch: UISwitch!
    @IBOutlet weak var poiImportAsNewSwitch: UISwitch!
    @IBOutlet weak var poiUpdateSwitch: UISwitch!
    @IBOutlet weak var poiTextFilter: UITextField!
    
    @IBOutlet weak var poiImportAsNewLabel: UILabel!
    @IBOutlet weak var poiUpdateLabel: UILabel!
    @IBOutlet weak var routeImportAsNewSwitch: UISwitch!
    
    var importOptions:GPXImportOptions!
    var importViewController:GPXImportViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        poiTextFilter.delegate = self
       
        refreshState()
    }
    
    func refreshState(withUpdate:Bool = false) {
        routeImportAsNewSwitch.isOn = importOptions.routeOptions.importAsNew
        poiMergeSwitch.isOn = importOptions.poiOptions.merge
        
        poiImportAsNewSwitch.isEnabled = importOptions.poiOptions.merge
        poiUpdateSwitch.isEnabled = importOptions.poiOptions.merge
        poiImportAsNewLabel.isEnabled = importOptions.poiOptions.merge
        poiUpdateLabel.isEnabled = importOptions.poiOptions.merge
        if !importOptions.poiOptions.merge {
            poiImportAsNewSwitch.isOn = true
            poiUpdateSwitch.isOn = false
       } else {
            poiImportAsNewSwitch.isOn = importOptions.poiOptions.importNew
            poiUpdateSwitch.isOn = importOptions.poiOptions.importUpdate
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
        refreshState(withUpdate: true)
    }

    @IBAction func switchPOIMerge(_ sender: UISwitch) {
        importOptions.poiOptions.merge = sender.isOn
        refreshState(withUpdate: true)
    }
    
    @IBAction func switchPOIImportAsNew(_ sender: UISwitch) {
        importOptions.poiOptions.importNew = sender.isOn
        refreshState(withUpdate: true)
    }
    
    // MARK: - Table view data source
    @IBAction func switchPOIUpdate(_ sender: UISwitch) {
        importOptions.poiOptions.importUpdate = sender.isOn
        refreshState(withUpdate: true)
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
        //tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
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

