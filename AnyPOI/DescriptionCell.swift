//
//  DescriptionCell.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 08/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
//, UIPickerViewDataSource, UIPickerViewDelegate
class DescriptionCell: UITableViewCell {

    @IBOutlet weak var POIDescription: UITextField!
    
    @IBOutlet weak var POITitle: UITextField!
//    @IBOutlet weak var groupPicker: UIPickerView! {
//        didSet {
//            if let groupPicker = groupPicker {
//            groupPicker.dataSource = self;
//            groupPicker.delegate = self;
//            }
//        }
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

//    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
//        return 1
//    }
//    
//    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return POIDataManager.sharedInstance.groups.count
//    }
//    
//    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return POIDataManager.sharedInstance.groups[row].groupName
//    }
}
