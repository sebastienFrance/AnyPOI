//
//  PickerViewCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 16/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class PickerViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var thePickerView: UIPickerView! {
        didSet {
            if let pickerView = thePickerView {
                pickerView.dataSource = self
                pickerView.delegate = self
            }
        }
    }
    
    var values = [String]()
    weak var delegate:PoiEditorViewController!

    func setInitialValue(_ value:String) {
        for index in 0..<values.count {
            if value == values[index] {
                thePickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }

    func getSelectedValue() -> String {
        let index = thePickerView.selectedRow(inComponent: 0)
        return values[index]
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
        delegate.pickerViewUpdated(self, selectedRowIndex:row)
    }
    
    fileprivate struct Storyboard {
        static let pickerCategoryView = "PickerCategoryView"
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var categoryView = view as? PickerCategoryView
        if categoryView == nil {
            let nib = UINib(nibName: Storyboard.pickerCategoryView, bundle: nil)
            categoryView = nib.instantiate(withOwner: nil, options: nil)[0] as? PickerCategoryView
            (categoryView!.categoryImage.image, categoryView!.categoryLabel.text) = CategoryUtils.getIconAndLabel(index:row)
        }
        return categoryView!
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 29
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.bounds.width
    }

}
