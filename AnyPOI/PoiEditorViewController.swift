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

    private enum rowType {
        case poiDisplayName, poiDescription, poiCategory, poiGroup
    }

    private enum rowIndexForPicker:Int {
        case category = 3, group
    }

    private let model = [rowType.poiDisplayName, rowType.poiDescription, rowType.poiCategory, rowType.poiGroup]

    private var isPickerDisplayed = false
    private var pickerIndex = 0
    
    // Map image
    private var snapshotter:MKMapSnapshotter?
    private var snapshotMapImageView:UIImageView?
    private var mapSnapshot:MKMapSnapshot?

    var thePoi:PointOfInterest! {
        didSet {
            newRegionEnter = thePoi.poiRegionNotifyEnter
            newRegionExit = thePoi.poiRegionNotifyExit
            newRadius = thePoi.poiRegionRadius
            newCategory = Int(thePoi.poiCategory)
            newParentGroup = thePoi.parentGroup
            newDisplayName = thePoi.poiDisplayName
            newDescription = thePoi.poiDescription
        }
    }

    private var newRegionEnter:Bool!
    private var newRegionExit:Bool!
    private var newRadius:Double!
    private var newCategory:Int!
    private var newParentGroup:GroupOfInterest?
    private var newDisplayName:String!
    private var newDescription:String!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapSnapshot()
    }

    func pickerViewUpdated(picker:PickerViewCell, selectedRowIndex:Int) {
        let theCell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: pickerIndex - 1, inSection: 0)) as! CategoryTableViewCell
        newCategory = selectedRowIndex
        theCell.initWithCategory(newCategory)
    }
    
    func pickerGroupViewUpdated(picker:GroupPickerViewCell, selectedRowIndex:Int) {
        newParentGroup = picker.getSelectedGroup()
        theTableView.reloadData()
        dispatch_async(dispatch_get_main_queue()) {self.refreshMapImageForMonitoring() }
    }

    //MARK: Buttons Callback
    @IBAction func saveButtonPushed(sender: AnyObject) {

        // Keep the old values to check if we need to start/stop the RegionMonitoring
        let oldPoiRegionNotifyEnter = thePoi.poiRegionNotifyEnter
        let oldPoiRegionNotifyExit = thePoi.poiRegionNotifyExit
        let oldRadius = thePoi.poiRegionRadius
        
        // Save the new value in database
        thePoi.title = newDisplayName
        thePoi.poiDescription = newDescription
        thePoi.poiRegionNotifyEnter = newRegionEnter
        thePoi.poiRegionNotifyExit = newRegionExit
        thePoi.poiRegionRadius = newRadius
        thePoi.poiCategory = Int16(newCategory)
        thePoi.parentGroup = newParentGroup
        
        POIDataManager.sharedInstance.updatePOI(thePoi)
        POIDataManager.sharedInstance.commitDatabase()
        
        // If the RegionMonitoring was not activated for this POI, we check if we need to do it
        if (!oldPoiRegionNotifyEnter && !oldPoiRegionNotifyExit) && (newRegionExit || newRegionEnter) {
            // Start region monitoring
            if !LocationManager.sharedInstance.isMaxMonitoredRegionReached() {
                LocationManager.sharedInstance.startMonitoringRegion(thePoi)
            } else {
                Utilities.showAlertMessage(self, title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("MaxMonitoredPOIReached", comment: ""))
            }
        } else if (oldPoiRegionNotifyEnter || oldPoiRegionNotifyExit) && (!newRegionEnter && !newRegionExit) {
            // Stop region monitoring
            LocationManager.sharedInstance.stopMonitoringRegion(thePoi)
        } else if (oldPoiRegionNotifyEnter || oldPoiRegionNotifyExit) && (newRadius != oldRadius) {
            // Update the radius of the monitored region
            LocationManager.sharedInstance.updateMonitoringRegion(thePoi)
        }

        dismissViewControllerAnimated(true, completion: nil )
    }
    
    @IBAction func cancelButtonPushed(sender: AnyObject) {
        POIDataManager.sharedInstance.rollback()
        dismissViewControllerAnimated(true, completion: nil )
    }

    @IBAction func switchMonitorEnterRegionChanged(sender: UISwitch) {
        newRegionEnter = sender.on
        refreshMonitoringSection()
    }
    
    @IBAction func switchMonitorExitRegionChanged(sender: UISwitch) {
        newRegionExit = sender.on
        refreshMonitoringSection()
    }

    @IBAction func sliderRadiusChanged(sender: UISlider) {
        newRadius = Double(sender.value)
        dispatch_async(dispatch_get_main_queue()) {self.refreshMapImageForMonitoring() }
        if let cell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: Rows.monitoringControls, inSection: Sections.regionMonitoring)) as? PoiRegionConfigurationViewCell {
            cell.initWith(newRegionEnter, exitRegion:newRegionExit, radius:newRadius)
        }
    }

 }

extension PoiEditorViewController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if textField.tag == Cste.poiDisplayNameTextField {
            let length = textField.text!.characters.count - range.length + string.characters.count
            saveButton.enabled = length > 0 ? true : false
            newDisplayName = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        } else if textField.tag == Cste.poiDescriptionTextField {
            newDescription = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        }
        
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField.tag == Cste.poiDisplayNameTextField {
            saveButton.enabled = false
            newDisplayName = ""
        } else if textField.tag == Cste.poiDescriptionTextField {
            newDescription = ""
        }
        
        textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        return true
    }
}

extension PoiEditorViewController: UITableViewDataSource, UITableViewDelegate {
    private struct Sections {
        static let properties = 0
        static let regionMonitoring = 1
    }
    
    private struct Rows {
        static let monitoringMap = 0
        static let monitoringControls = 1
    }
    
    private struct Cste {
        static let poiDisplayNameTextField = 0
        static let poiDescriptionTextField = 1
        
        static let MapViewHeight = CGFloat(170.0)
        static let MaxPerimeterInMeters = 400.0
    }


    //MARK : UITableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.properties:
            return nil
        case Sections.regionMonitoring:
            return NSLocalizedString("PoiEditorRegionMonitoringSectionName", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }
    
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Sections.regionMonitoring {
            return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Sections.regionMonitoring  && indexPath.row == Rows.monitoringMap {
                return Cste.MapViewHeight
        } else {
            return  UITableViewAutomaticDimension
        }
    }
    
    private struct cellIdentifier {
        static let textFieldCellId = "textFieldCellId"
        static let cellCategoryId = "cellCategoryId"
        static let cellPickerId = "cellPickerId"
        static let cellGroupPickerId = "cellGroupPickerId"
        static let groupDescriptionCellId = "groupDescriptionCellId"
        static let poiRegionConfigurationCellId = "poiRegionConfigurationCellId"
        static let poiRegionMapViewCellId = "poiRegionMapViewCellId"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.properties:
            return getCellForProperties(indexPath)
        case Sections.regionMonitoring:
            if indexPath.row == Rows.monitoringControls {
                let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.poiRegionConfigurationCellId, forIndexPath: indexPath) as! PoiRegionConfigurationViewCell
                theCell.initWith(newRegionEnter, exitRegion:newRegionExit, radius:newRadius)
                return theCell
            } else {
                let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.poiRegionMapViewCellId, forIndexPath: indexPath)
                refreshMapCell(theCell)
                return theCell
            }
        default:
            print("\(#function) unknown section \(indexPath.section)")
            return UITableViewCell()
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
        if let monitoringCell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: Rows.monitoringControls, inSection: Sections.regionMonitoring)) as? PoiRegionConfigurationViewCell {
            monitoringCell.initWith(newRegionEnter, exitRegion: newRegionExit, radius: newRadius)
        }
        
        refreshMapImageForMonitoring()
    }
    

    private func refreshMapCell(theCell:UITableViewCell) {
        if let theSnapshotter = snapshotter where !theSnapshotter.loading {
            theCell.backgroundView = snapshotMapImageView
            if !newRegionExit && !newRegionEnter {
                theCell.backgroundView?.alpha = 0.3
            } else {
                theCell.backgroundView?.alpha = 1.0
            }
        }
    }
    
    // MARK: MapSnapshot
    // Display all POIs without any filter in the Map
    private func loadMapSnapshot() {
        let snapshotOptions = MKMapSnapshotOptions()
        
        snapshotOptions.region = MKCoordinateRegionMakeWithDistance(thePoi.coordinate, Cste.MaxPerimeterInMeters, Cste.MaxPerimeterInMeters)
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .Standard ? .Standard : .Satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSizeMake(view.bounds.width, Cste.MapViewHeight)
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter!.startWithCompletionHandler() { mapSnapshot, error in
            if let error = error {
                print("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                self.mapSnapshot = mapSnapshot
                self.refreshMapImageForMonitoring()
            }
        }
    }
    
    func refreshMapImageForMonitoring() {
        if let mapImage = mapSnapshot?.image {
            
            UIGraphicsBeginImageContextWithOptions(mapImage.size, true, 0)
            // Put the Map in the Graphic Context
            mapImage.drawAtPoint(CGPointMake(0, 0))
            
            if newRegionExit || newRegionEnter {
                MapUtils.addCircleInMapSnapshot(thePoi.coordinate, radius: newRadius, mapSnapshot: mapSnapshot!)
            }
            MapUtils.addAnnotationInMapSnapshot(self.thePoi, tintColor: newParentGroup!.color, mapSnapshot: mapSnapshot!)
            
            // Get the final image from the Grapic context
            let snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Build the UIImageView only once for the tableView
            let newImageView = UIImageView(image: snapshotImage)
            snapshotMapImageView = newImageView
            snapshotMapImageView!.contentMode = .ScaleAspectFill
            snapshotMapImageView!.clipsToBounds = true
            
            // Update the section 0 that display the Map as background
            if let cell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: Rows.monitoringMap, inSection: Sections.regionMonitoring)) {
                refreshMapCell(cell)
            }
        }
    }

    // MARK: RowPicker
    private func getCellForProperties(indexPath:NSIndexPath) -> UITableViewCell {
        var row = indexPath.row
        if isPickerDisplayed {
            if row == 3 && pickerIndex == row {
                let pickerCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.cellPickerId, forIndexPath: indexPath) as! PickerViewCell
                pickerCell.values = CategoryUtils.getAllCategoriesLabel()
                pickerCell.delegate = self
                pickerCell.setInitialValue(CategoryUtils.getLabelCategoryForIndex(Int(thePoi.poiCategory)))
                return pickerCell
            } else if row == 4 && pickerIndex == row {
                let pickerCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.cellGroupPickerId, forIndexPath: indexPath) as! GroupPickerViewCell
                
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
            let theCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.textFieldCellId, forIndexPath: indexPath) as! TextFieldViewCell
            theCell.theTextField.text = thePoi.poiDisplayName
            theCell.theTextField.delegate = self
            theCell.theTextField.placeholder = NSLocalizedString("PoiEditorPOINamePlaceholder", comment: "")
            theCell.theTextField.tag = Cste.poiDisplayNameTextField
            return theCell
        case .poiDescription:
            let theCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.textFieldCellId, forIndexPath: indexPath) as! TextFieldViewCell
            theCell.theTextField.text = thePoi.poiDescription
            theCell.theTextField.delegate = self
            theCell.theTextField.placeholder = NSLocalizedString("PoiEditorPOIDescriptionPlaceholder", comment: "")
            theCell.theTextField.tag = Cste.poiDescriptionTextField
            return theCell
        case .poiCategory:
            let theCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.cellCategoryId, forIndexPath: indexPath) as! CategoryTableViewCell
            theCell.initWithCategory(newCategory)

            return theCell
        case .poiGroup:
            let theCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.groupDescriptionCellId, forIndexPath: indexPath) as! PoiEditorGroupViewCell
            theCell.initWith(newParentGroup!)
            return theCell
        }
    }
    
    private func closePicker() {
        if isPickerDisplayed {
            theTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: pickerIndex, inSection: 0)] , withRowAnimation: .Automatic)
            isPickerDisplayed = false
        }
    }
    
    private func updateRowPicker(indexPath: NSIndexPath) {
        theTableView.beginUpdates()
        
        var hasClosedPicker = false
        
        // If a picker is already displayed we remove it to display only the new one
        if isPickerDisplayed {
            theTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: pickerIndex, inSection: 0)] , withRowAnimation: .Fade)
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
            theTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: pickerIndex, inSection: 0)], withRowAnimation: .Fade)
            theTableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        theTableView.endUpdates()
    }
    
    
}
