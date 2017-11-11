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


class GroupConfiguratorViewController: UIViewController {

    @IBOutlet fileprivate weak var groupNameTextField: UITextField!
    @IBOutlet fileprivate weak var groupDescriptionTextField: UITextField!
    
    @IBOutlet fileprivate weak var colorsCollectionView: UICollectionView!
    @IBOutlet fileprivate weak var saveButton: UIButton!
    @IBOutlet fileprivate weak var backgroundView: UIView!
    
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
        colorsCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      
        // Move the collectionView on the group color
        colorsCollectionView.scrollToItem(at: IndexPath(row: selectedColorIndex, section: 0), at: .left, animated: true)
    }

    // A Group cannot be saved when its name is empty
    private func enableSaveButton() {
        if let groupName = groupNameTextField.text , !groupName.isEmpty {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }

    //MARK: Action buttons
    @IBAction func saveButtonPushed(_ sender: UIButton) {
        if let theGroup = group {
            // Update an existing group
            theGroup.groupDisplayName = groupNameTextField.text ?? ""
            theGroup.color = colors[selectedColorIndex]
            theGroup.groupDescription = groupDescriptionTextField.text ?? ""
            POIDataManager.sharedInstance.updatePOIGroup(theGroup)
            POIDataManager.sharedInstance.commitDatabase()
         } else {
            // Create a new group
            let groupDescription = groupDescriptionTextField.text ?? ""
            _ = POIDataManager.sharedInstance.addGroup(groupName: groupNameTextField.text!, groupDescription: groupDescription, groupColor:colors[selectedColorIndex])
        }
        
        
        self.delegate?.didDismiss() // Warn the delegate the view will be dismissed
        dismiss(animated: true, completion:  nil)
   }
    
    @IBAction func cancelButtonPushed(_ sender: UIButton) {
        dismiss(animated: true, completion:  nil)
        delegate?.didDismiss()
    }
}

extension GroupConfiguratorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    

    //MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    private struct CollectionViewCell {
        static let colorCellId = "ColorSelectorCellId"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.colorCellId, for: indexPath) as! ColorCollectionViewCell
        let stroke = selectedColorIndex == indexPath.row ? true : false
        
        cell.colorImage.image = DrawingUtils.getImageForColor(colors[indexPath.row], imageSize: 25.0, lineWidth: stroke ? 2.0 : 0.0)
        return cell
     }

    //MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedColorIndex != indexPath.row {
            // Refresh the unselected and selected colors
            let oldSelectedColorIndexPath =  IndexPath(row: selectedColorIndex, section: 0)
            selectedColorIndex = indexPath.row
            colorsCollectionView.reloadItems(at: [indexPath, oldSelectedColorIndexPath])
        }
    }
}

extension GroupConfiguratorViewController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    
    // When the group name becomes empty we set the save button to disabled otherwise it's enabled
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === groupNameTextField {
            let length = textField.text!.count - range.length + string.count
            saveButton.isEnabled = length > 0 ? true : false
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField === groupNameTextField {
            saveButton.isEnabled = false
            textField.text = "" // Force the text field to empty in case the Keyboard has selected it for auto correction
        }
        return true
    }
    
    // Return key goes to description field, only when the groupName is not empty
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === groupNameTextField && !groupNameTextField.text!.isEmpty {
            groupDescriptionTextField.becomeFirstResponder()
        }
        return true
    }

}
