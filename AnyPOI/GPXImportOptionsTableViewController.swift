//
//  GPXImportOptionsTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 23/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXImportOptionsTableViewController: UITableViewController {

    
    @IBOutlet weak var poiTextualDescription: UILabel!
    @IBOutlet weak var poiImportAsNewSwitch: UISwitch!
    @IBOutlet weak var poiMergeImportNewSwitch: UISwitch!
    @IBOutlet weak var poiMergeImportUpdateSwitch: UISwitch!
    @IBOutlet weak var poiTextFilter: UITextField!
    
    @IBOutlet weak var poiMergeImportTitle: UILabel!
    @IBOutlet weak var poiMergeImportNewLabel: UILabel!
    @IBOutlet weak var poiMergeImportUpdateLabel: UILabel!

    @IBOutlet weak var routeTextualDescription: UILabel!
    @IBOutlet weak var routeImportAsNewSwitch: UISwitch!
    @IBOutlet weak var routeImportAsNewLabel: UILabel!
    @IBOutlet weak var routeMergeImportNewSwitch: UISwitch!
    @IBOutlet weak var routeMergeImportUpdateSwitch: UISwitch!
    @IBOutlet weak var routeMergeImportNewLabel: UILabel!
    @IBOutlet weak var routeMergeImportUpdateLabel: UILabel!
    @IBOutlet weak var routeMergeImportTitle: UILabel!
    
    var importOptions:GPXImportOptions!
    var importViewController:GPXImportViewController!
    var enableRouteOptions = true

    override func viewDidLoad() {
        super.viewDidLoad()
        poiTextFilter.delegate = self
       
        refreshDisplayedState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Make the height takes into account the safe area (especially for iPhone X)
        view.frame.size = CGSize(width: view.frame.width, height: view.frame.height - view.safeAreaInsets.bottom)
    }
    
    
    /// Refresh the buttons and textual description based on importOptions configuraton
    /// and update the GPXImportViewController with the new importOptions
    func refreshDisplayedState() {
        
        if enableRouteOptions {
            // Update states related to Route import
            routeImportAsNewSwitch.isOn = importOptions.routeOptions.importAsNew
            routeMergeImportNewSwitch.isEnabled = !importOptions.routeOptions.importAsNew
            routeMergeImportUpdateSwitch.isEnabled = !importOptions.routeOptions.importAsNew
            routeMergeImportNewLabel.isEnabled = !importOptions.routeOptions.importAsNew
            routeMergeImportUpdateLabel.isEnabled = !importOptions.routeOptions.importAsNew
            routeMergeImportTitle.isEnabled = !importOptions.routeOptions.importAsNew
            if importOptions.routeOptions.importAsNew {
                routeMergeImportNewSwitch.isOn = false
                routeMergeImportUpdateSwitch.isOn = false
            } else {
                routeMergeImportNewSwitch.isOn = importOptions.routeOptions.importNew
                routeMergeImportUpdateSwitch.isOn = importOptions.routeOptions.importUpdate
            }
            routeTextualDescription.attributedText = importOptions.routeTextualDescription
        } else {
            routeImportAsNewSwitch.isEnabled = false
            routeImportAsNewLabel.isEnabled = false
            routeMergeImportNewSwitch.isEnabled = false
            routeMergeImportNewLabel.isEnabled = false
            routeMergeImportUpdateSwitch.isEnabled = false
            routeMergeImportUpdateLabel.isEnabled = false
            routeMergeImportTitle.isEnabled = false
            routeTextualDescription.text = ""
            routeTextualDescription.isEnabled = false
        }
        
        // Update states related to POI import
        poiImportAsNewSwitch.isOn = importOptions.poiOptions.importAsNew
        
        poiMergeImportNewSwitch.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportUpdateSwitch.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportNewLabel.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportUpdateLabel.isEnabled = !importOptions.poiOptions.importAsNew
        poiMergeImportTitle.isEnabled = !importOptions.poiOptions.importAsNew
        if importOptions.poiOptions.importAsNew {
            poiMergeImportNewSwitch.isOn = false
            poiMergeImportUpdateSwitch.isOn = false
        } else {
            poiMergeImportNewSwitch.isOn = importOptions.poiOptions.importNew
            poiMergeImportUpdateSwitch.isOn = importOptions.poiOptions.importUpdate
        }
        poiTextualDescription.attributedText = importOptions.poiTextualDescription
        poiTextFilter.text = importOptions.poiOptions.textFilter
        
        // Update the importViewController with the new filter
        importViewController.update(options: importOptions)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func switchRouteImportAsNew(_ sender: UISwitch) {
        importOptions.routeOptions.importAsNew = sender.isOn
        importOptions.routeOptions.importNew = !importOptions.routeOptions.importAsNew
        importOptions.routeOptions.importUpdate = !importOptions.routeOptions.importAsNew
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
    
    @IBAction func switchRouteMergeImportNew(_ sender: UISwitch) {
        importOptions.routeOptions.importNew = sender.isOn
        refreshDisplayedState()
    }
    
    @IBAction func switchRouteMergeImportUpdate(_ sender: UISwitch) {
        importOptions.routeOptions.importUpdate = sender.isOn
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
        poiTextualDescription.attributedText = importOptions.poiTextualDescription
        tableView.reloadRows(at: [IndexPath(row:0, section:0)], with: .none)
        importViewController.update(options: importOptions)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        importOptions.poiOptions.textFilter = ""
        textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        poiTextualDescription.attributedText = importOptions.poiTextualDescription
        importViewController.update(options: importOptions)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

