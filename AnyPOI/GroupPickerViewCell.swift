//
//  GroupPickerViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 17/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

//
//  PickerViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 16/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GroupPickerViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var thePickerView: UIPickerView! {
        didSet {
            if let pickerView = thePickerView {
                pickerView.dataSource = self
                pickerView.delegate = self
            }
        }
    }
    
    var values = [String]()
    var groups = [GroupOfInterest]()
    
    
    weak var delegate:PoiEditorViewController!
    
    func setInitialGroup(_ group:GroupOfInterest) {
        for index in 0..<groups.count {
            if group == groups[index] {
                thePickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }
    
    func getSelectedGroup() -> GroupOfInterest {
        let index = thePickerView.selectedRow(inComponent: 0)
        return groups[index]
    }
    
    //MARK: UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    
    //MARK: UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate.pickerGroupViewUpdated(self, selectedRowIndex:row)
    }
     
    fileprivate struct Storyboard {
        static let pickerGroupView = "PickerGroupView"
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var groupView = view as? PickerGroupView
        if groupView == nil {
            let nib = UINib(nibName: Storyboard.pickerGroupView, bundle: nil)
            groupView = nib.instantiate(withOwner: nil, options: nil)[0] as? PickerGroupView
        }
        
        groupView!.groupLabel.text = groups[row].groupDisplayName
        groupView!.groupImage.image = groups[row].iconImage
        return groupView!

    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 29
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.bounds.width
    }

}
