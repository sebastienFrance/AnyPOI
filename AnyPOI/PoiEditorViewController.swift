//
//  PoiEditorViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 16/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit


class PoiEditorViewController: UIViewController {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                theTableView.estimatedRowHeight = 80
                theTableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }

    @IBOutlet weak var saveButton: UIBarButtonItem!

    fileprivate enum rowType {
        case poiDisplayName, poiDescription, poiCategory, poiGroup
    }

    fileprivate enum rowIndexForPicker:Int {
        case category = 3, group
    }

    fileprivate let model = [rowType.poiDisplayName, rowType.poiDescription, rowType.poiCategory, rowType.poiGroup]

    fileprivate var isPickerDisplayed = false
    fileprivate var pickerIndex = 0
    
    // Map image
    private var mapBackground = MapBackground()

    var thePoi:PointOfInterest! {
        didSet {
            newRegionEnter = thePoi.poiRegionNotifyEnter
            newRegionExit = thePoi.poiRegionNotifyExit
            newRadius = thePoi.poiRegionRadius
            sliderRadius = Float(thePoi.poiRegionRadius)
            newCategory = thePoi.category
            newParentGroup = thePoi.parentGroup
            newDisplayName = thePoi.poiDisplayName
            newDescription = thePoi.poiDescription
        }
    }

    fileprivate var newRegionEnter:Bool!
    fileprivate var newRegionExit:Bool!
    fileprivate var newRadius:Double!
    fileprivate var newParentGroup:GroupOfInterest?
    fileprivate var newDisplayName:String!
    fileprivate var newDescription:String!
    
    fileprivate var newCategory:CategoryUtils.Category!
    
    private var sliderRadius:Float = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PoiEditorViewController.locationAuthorizationHasChanged(_:)),
                                               name: NSNotification.Name(rawValue: LocationManager.LocationNotifications.AuthorizationHasChanged),
                                               object: LocationManager.sharedInstance.locationManager)

        mapBackground.imageSize = CGSize(width: view.bounds.width, height: Cste.MapViewHeight)
        mapBackground.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapBackground.loadFor(POI:thePoi)
    }
    
    @objc func locationAuthorizationHasChanged(_ notification : Notification) {
        let index = IndexPath(row: Rows.monitoringControls, section: Sections.regionMonitoring)
        theTableView.reloadRows(at: [index], with: .automatic)
        refreshMapImageForMonitoring()
    }

    func pickerViewUpdated(_ picker:PickerViewCell, selectedCategory:CategoryUtils.Category) {
        let theCell = theTableView.cellForRow(at: IndexPath(row: pickerIndex - 1, section: 0)) as! CategoryTableViewCell
        newCategory = selectedCategory
        theCell.initWith(category:selectedCategory)
    }
    
    func pickerGroupViewUpdated(_ picker:GroupPickerViewCell, selectedRowIndex:Int) {
        newParentGroup = picker.getSelectedGroup()
        theTableView.reloadData()
        DispatchQueue.main.async {self.refreshMapImageForMonitoring() }
    }

    //MARK: Buttons Callback
    @IBAction func saveButtonPushed(_ sender: AnyObject) {

        
        // Save the new value in database
        thePoi.title = newDisplayName
        thePoi.poiDescription = newDescription
        thePoi.category = newCategory
        
        if let parentGroup = newParentGroup, thePoi.parentGroup != parentGroup {
            UserPreferences.sharedInstance.lastUsedGroupOfInterest = parentGroup
        }
        
        thePoi.parentGroup = newParentGroup
        
        POIDataManager.sharedInstance.updatePOI(thePoi)
        POIDataManager.sharedInstance.commitDatabase()
        
        if newRegionExit || newRegionEnter {
            switch thePoi.startMonitoring(radius:newRadius, notifyEnterRegion: newRegionEnter, notifyExitRegion: newRegionExit) {
            case .noError:
                break
            case .deviceNotSupported:
                Utilities.showAlertMessage(self, title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("StartMonitoringDeviceNotSupported", comment: ""))
                break
            case .internalError:
                Utilities.showAlertMessage(self, title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("InternalError", comment: ""))
                break
            case .maxMonitoredRegionAlreadyReached:
                Utilities.showAlertMessage(self, title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("MaxMonitoredPOIReachedErrorMsg", comment: ""))
            }
        } else {
            thePoi.stopMonitoring()
        }
        
        dismiss(animated: true, completion: nil )
    }
    
    @IBAction func cancelButtonPushed(_ sender: AnyObject) {
        POIDataManager.sharedInstance.rollback()
        dismiss(animated: true, completion: nil )
    }

    @IBAction func switchMonitorEnterRegionChanged(_ sender: UISwitch) {
        if !thePoi.isMonitored && LocationManager.sharedInstance.isMaxMonitoredRegionReached() {
            sender.setOn(false, animated: true)
            Utilities.showAlertMessage(self, title: NSLocalizedString("MaxMonitoredPOIReachedErrorTitle", comment: ""), message: NSLocalizedString("MaxMonitoredPOIReachedErrorMsg", comment: ""))
        } else {
            newRegionEnter = sender.isOn
            refreshMonitoringSection()
        }
    }
    
    @IBAction func switchMonitorExitRegionChanged(_ sender: UISwitch) {
        if !thePoi.isMonitored && LocationManager.sharedInstance.isMaxMonitoredRegionReached() {
            sender.setOn(false, animated: true)
            Utilities.showAlertMessage(self, title: NSLocalizedString("MaxMonitoredPOIReachedErrorTitle", comment: ""), message: NSLocalizedString("MaxMonitoredPOIReachedErrorMsg", comment: ""))
        } else {
            newRegionExit = sender.isOn
            refreshMonitoringSection()
        }
    }

    @IBAction func sliderRadiusChanged(_ sender: UISlider) {
        newRadius = Double((Int(sender.value) / 10) * 10)
        sliderRadius = sender.value
        refreshMapImageForMonitoring()
        if let cell = theTableView.cellForRow(at: IndexPath(row: Rows.monitoringControls, section: Sections.regionMonitoring)) as? PoiRegionConfigurationViewCell {
            cell.initWith(newRegionEnter, exitRegion:newRegionExit, radiusSlider:sliderRadius, realRadius:newRadius)
        }
    }

 }

extension PoiEditorViewController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.tag == Cste.poiDisplayNameTextField {
            let length = textField.text!.count - range.length + string.count
            saveButton.isEnabled = length > 0 ? true : false
            newDisplayName = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        } else if textField.tag == Cste.poiDescriptionTextField {
            newDescription = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField.tag == Cste.poiDisplayNameTextField {
            saveButton.isEnabled = false
            newDisplayName = ""
        } else if textField.tag == Cste.poiDescriptionTextField {
            newDescription = ""
        }
        
        textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}


extension PoiEditorViewController: UITableViewDataSource, UITableViewDelegate {
    fileprivate struct Sections {
        static let properties = 0
        static let regionMonitoring = 1
    }
    
    fileprivate struct Rows {
        static let monitoringMap = 0
        static let monitoringControls = 1
    }
    
    fileprivate struct Cste {
        static let poiDisplayNameTextField = 0
        static let poiDescriptionTextField = 1
        
        static let MapViewHeight = CGFloat(170.0)
        static let MaxPerimeterInMeters = LocationManager.constants.maxRadius * 2
    }


    //MARK : UITableViewDatasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.properties:
            var numberOfRows = model.count
            if isPickerDisplayed {
                numberOfRows += 1
            }
            return numberOfRows
        case Sections.regionMonitoring:
            return 2
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.properties:
            return nil
        case Sections.regionMonitoring:
            return NSLocalizedString("PoiEditorRegionMonitoringSectionName", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Sections.regionMonitoring {
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Sections.regionMonitoring  && indexPath.row == Rows.monitoringMap {
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    fileprivate struct cellIdentifier {
        static let textFieldCellId = "textFieldCellId"
        static let textFieldDescriptionCellId = "textFieldDescriptionCellId"
        static let cellCategoryId = "cellCategoryId"
        static let cellPickerId = "cellPickerId"
        static let cellGroupPickerId = "cellGroupPickerId"
        static let groupDescriptionCellId = "groupDescriptionCellId"
        static let poiRegionConfigurationCellId = "poiRegionConfigurationCellId"
        static let poiRegionMapViewCellId = "poiRegionMapViewCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.properties:
            return getCellForProperties(indexPath)
        case Sections.regionMonitoring:
            if indexPath.row == Rows.monitoringControls {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.poiRegionConfigurationCellId, for: indexPath) as! PoiRegionConfigurationViewCell
                theCell.initWith(newRegionEnter, exitRegion:newRegionExit, radiusSlider:sliderRadius, realRadius:newRadius)
                return theCell
            } else {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.poiRegionMapViewCellId, for: indexPath)
                refreshMapCell(theCell)
                return theCell
            }
        default:
            NSLog("\(#function) unknown section \(indexPath.section)")
            return UITableViewCell()
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.properties {
            if isPickerDisplayed {
                if (rowIndexForPicker(rawValue: pickerIndex) == rowIndexForPicker.category && (indexPath.row == 2 || indexPath.row == 4)) ||
                    (rowIndexForPicker(rawValue: pickerIndex) == rowIndexForPicker.group && (indexPath.row == 2 || indexPath.row == 3)) {
                    updateRowPicker(indexPath)
                }
            } else {
                if indexPath.row == 2 || indexPath.row  == 3 {
                    updateRowPicker(indexPath)
                }
            }
        }
    }

    // MARK: Cell Update
    func refreshMonitoringSection() {
        if let monitoringCell = theTableView.cellForRow(at: IndexPath(row: Rows.monitoringControls, section: Sections.regionMonitoring)) as? PoiRegionConfigurationViewCell {
            monitoringCell.initWith(newRegionEnter, exitRegion: newRegionExit, radiusSlider:sliderRadius, realRadius:newRadius)
        }
        
        refreshMapImageForMonitoring()
    }
    

    fileprivate func refreshMapCell(_ theCell:UITableViewCell) {
        
        mapBackground.monitoringRadius = newRadius
        mapBackground.withMonitoringCircle = newRegionExit || newRegionEnter
        
        if !mapBackground.isLoading, let mapImage = mapBackground.mapImage {
            theCell.backgroundView = UIImageView(image: mapImage)
            if !newRegionExit && !newRegionEnter {
                theCell.backgroundView?.alpha = 0.3
            } else {
                theCell.backgroundView?.alpha = 1.0
            }
       }
    }
    
    // MARK: MapSnapshot
    func refreshMapImageForMonitoring() {
        if let theCell = theTableView.cellForRow(at: IndexPath(row: Rows.monitoringMap, section: Sections.regionMonitoring)) {
            refreshMapCell(theCell)
        }
    }

    // MARK: RowPicker
    fileprivate func getCellForProperties(_ indexPath:IndexPath) -> UITableViewCell {
        var row = indexPath.row
        if isPickerDisplayed {
            if row == 3 && pickerIndex == row {
                let pickerCategoryCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellPickerId, for: indexPath) as! PickerViewCell
                pickerCategoryCell.delegate = self
                pickerCategoryCell.initWith(poi: thePoi)
                return pickerCategoryCell
            } else if row == 4 && pickerIndex == row {
                let pickerCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellGroupPickerId, for: indexPath) as! GroupPickerViewCell
                
                var allGroups = [String]()
                let groups = POIDataManager.sharedInstance.getGroups()
                for currentGroup in groups {
                    allGroups.append(currentGroup.groupDisplayName!)
                }
                
                pickerCell.values = allGroups
                pickerCell.groups = groups
                pickerCell.delegate = self
                pickerCell.setInitialGroup(newParentGroup!)
                return pickerCell
            } else {
                row -= 1
            }
        }
        
        
        let rowType = model[indexPath.row]
        switch rowType {
        case .poiDisplayName:
            let theCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.textFieldCellId, for: indexPath) as! TextFieldViewCell
            theCell.theTextField.text = thePoi.poiDisplayName
            theCell.theTextField.delegate = self
            theCell.theTextField.placeholder = NSLocalizedString("PoiEditorPOINamePlaceholder", comment: "")
            theCell.theTextField.tag = Cste.poiDisplayNameTextField
            return theCell
        case .poiDescription:
            let theCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.textFieldDescriptionCellId, for: indexPath) as! POIDescriptionTableViewCell
            theCell.poiDescriptionTextField.text = thePoi.poiDescription
            theCell.poiDescriptionTextField.delegate = self
            theCell.poiDescriptionTextField.placeholder = NSLocalizedString("PoiEditorPOIDescriptionPlaceholder", comment: "")
            theCell.poiDescriptionTextField.tag = Cste.poiDescriptionTextField
            return theCell
        case .poiCategory:
            let theCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.cellCategoryId, for: indexPath) as! CategoryTableViewCell
            theCell.initWith(category: newCategory)

            return theCell
        case .poiGroup:
            let theCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.groupDescriptionCellId, for: indexPath) as! PoiEditorGroupViewCell
            theCell.initWith(newParentGroup!)
            return theCell
        }
    }
    
    fileprivate func closePicker() {
        if isPickerDisplayed {
            theTableView.deleteRows(at: [IndexPath(row: pickerIndex, section: 0)] , with: .automatic)
            isPickerDisplayed = false
        }
    }
    
    fileprivate func updateRowPicker(_ indexPath: IndexPath) {
        theTableView.beginUpdates()
        
        var hasClosedPicker = false
        
        // If a picker is already displayed we remove it to display only the new one
        if isPickerDisplayed {
            theTableView.deleteRows(at: [IndexPath(row: pickerIndex, section: 0)] , with: .fade)
            isPickerDisplayed = false
            hasClosedPicker = true
        }
        
        // when no picker was already displayed or
        // when a picker was already displayed (and then closed) but the selected cell of the
        // indexPath contain also a picker then we display the new picker
        if !hasClosedPicker || (hasClosedPicker && pickerIndex != (indexPath.row + 1)) {
            isPickerDisplayed = true
            if hasClosedPicker && indexPath.row > pickerIndex {
                pickerIndex = indexPath.row
            } else {
                pickerIndex = indexPath.row + 1
            }
            
            // Add the new row that will display the Picker
            theTableView.insertRows(at: [IndexPath(row: pickerIndex, section: 0)], with: .fade)
            theTableView.deselectRow(at: indexPath, animated: false)
        }
        
        theTableView.endUpdates()
    }
    
    
}

extension PoiEditorViewController: MapBackgroundDelegate {
    func mapBackgroundDidLoad(mapBackground:MapBackground, mapImage:UIImage?) {
        refreshMapImageForMonitoring()
    }
}

