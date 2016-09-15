//
//  GroupConfiguratorViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 29/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol DismissModalViewController: class {
    func didDismiss()
}


class GroupConfiguratorViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet private weak var groupNameTextField: UITextField!
    @IBOutlet private weak var groupDescriptionTextField: UITextField!
    
    @IBOutlet private weak var colorsCollectionView: UICollectionView!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    private var colors = [UIColor]()
    private var selectedColorIndex = 0
   
    var group:GroupOfInterest?
    weak var delegate:DismissModalViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.layer.masksToBounds = true;

        colorsCollectionView.delegate = self
        colorsCollectionView.dataSource = self

        colors = ColorsUtils.initColors()

        // if we update an existing group then we initialize
        // the view with the group properties
        if let theGroup = group {
            // If the original color cannot be found then we use the first color from the array.
            selectedColorIndex = ColorsUtils.findColorIndex(theGroup.color, inColors:colors)
            if selectedColorIndex == -1 {
                selectedColorIndex = 0
            }
            
            groupNameTextField.text = theGroup.groupDisplayName
            groupDescriptionTextField.text = theGroup.groupDescription

        }
        
        groupNameTextField.delegate = self
        groupNameTextField.becomeFirstResponder()
        enableSaveButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Move the collectionView on the group color
        colorsCollectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: selectedColorIndex, inSection: 0), atScrollPosition: .Left, animated: true)
    }

    // A Group cannot be saved when its name is empty
    private func enableSaveButton() {
        if let groupName = groupNameTextField.text where !groupName.isEmpty {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
        }
    }

    //MARK: Action buttons
    @IBAction func saveButtonPushed(sender: UIButton) {
        if let theGroup = group {
            // Update an existing group
            theGroup.groupDisplayName = groupNameTextField.text ?? "No descriptions"
            theGroup.color = colors[selectedColorIndex]
            POIDataManager.sharedInstance.updatePOIGroup(theGroup)
         } else {
            // Create a new group
            let groupDescription = groupDescriptionTextField.text ?? "No descriptions"
            POIDataManager.sharedInstance.addGroup(groupName: groupNameTextField.text!, groupDescription: groupDescription, groupColor:colors[selectedColorIndex])
        }
        POIDataManager.sharedInstance.commitDatabase()
        
        self.delegate?.didDismiss() // Warn the delegate the view will be dismissed
        dismissViewControllerAnimated(true, completion:  nil)
   }
    
    @IBAction func cancelButtonPushed(sender: UIButton) {
        dismissViewControllerAnimated(true, completion:  nil)
        delegate?.didDismiss()
    }

    
    //MARK: UITextFieldDelegate

    // When the group name becomes empty we set the save button to disabled otherwise it's enabled
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField === groupNameTextField {
            let length = textField.text!.characters.count - range.length + string.characters.count
            saveButton.enabled = length > 0 ? true : false
        }
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField === groupNameTextField {
            saveButton.enabled = false
            textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        }
        return true
    }

    // Return key goes to description field, only when the groupName is not empty
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === groupNameTextField && !groupNameTextField.text!.isEmpty {
            groupDescriptionTextField.becomeFirstResponder()
        }
        return true
    }

    //MARK: UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    private struct CollectionViewCell {
        static let colorCellId = "ColorSelectorCellId"
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CollectionViewCell.colorCellId, forIndexPath: indexPath) as! ColorCollectionViewCell
        
        let stroke = selectedColorIndex == indexPath.row ? true : false
        DrawingUtils.insertCircleForGroup(cell.colorView, fillColor: colors[indexPath.row], withStroke: stroke)
        return cell
     }

    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectedColorIndex != indexPath.row {
            // Refresh the unselected and selected colors
            let oldSelectedColorIndexPath =  NSIndexPath(forRow: selectedColorIndex, inSection: 0)
            selectedColorIndex = indexPath.row
            colorsCollectionView.reloadItemsAtIndexPaths([indexPath, oldSelectedColorIndexPath])
        }
    }
}
