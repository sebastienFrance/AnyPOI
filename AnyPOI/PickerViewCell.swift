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

    func setInitialValue(value:String) {
        for index in 0..<values.count {
            if value == values[index] {
                thePickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }

    func getSelectedValue() -> String {
        let index = thePickerView.selectedRowInComponent(0)
        return values[index]
    }
    
    //MARK: UIPickerViewDataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    
    //MARK: UIPickerViewDelegate
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate.pickerViewUpdated(self, selectedRowIndex:row)
    }
    
    private struct Storyboard {
        static let pickerCategoryView = "PickerCategoryView"
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        if let categoryView = view as? PickerCategoryView {
            (categoryView.categoryImage.image, categoryView.categoryLabel.text) = CategoryUtils.getCategoryForIndex(row)
            
            return categoryView
        } else {
            let nib = UINib(nibName: Storyboard.pickerCategoryView, bundle: nil)
            let categoryView = nib.instantiateWithOwner(nil, options: nil)[0] as! PickerCategoryView
            (categoryView.categoryImage.image, categoryView.categoryLabel.text) = CategoryUtils.getCategoryForIndex(row)

            return categoryView
        }
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 29
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.bounds.width
    }

}
