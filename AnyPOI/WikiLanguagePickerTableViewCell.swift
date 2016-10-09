//
//  WikiLanguagePickerTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class WikiLanguagePickerTableViewCell: UITableViewCell {

    var wikiUpdate:WikipediaLanguageUpdate!
    
    
    @IBOutlet weak var thePickerView: UIPickerView! {
        didSet {
            thePickerView.delegate = self
            thePickerView.dataSource = self
            
            // Set picker on the current selected language
            let languageISOcode = UserPreferences.sharedInstance.wikipediaLanguageISOcode
            let languageName = WikipediaLanguages.LanguageForISOcode(languageISOcode)
            var i = 0
            for currentLanguage in WikipediaLanguages.supportedLanguages {
                if currentLanguage == languageName {
                    thePickerView.selectRow(i, inComponent: 0, animated: false)
                    break
                }
                i += 1
            }
        }
    }
}



extension WikiLanguagePickerTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return WikipediaLanguages.supportedLanguages.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return WikipediaLanguages.supportedLanguages[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        wikiUpdate.wikiLanguageHasChanged(WikipediaLanguages.languageISOCodeForLanguage(WikipediaLanguages.supportedLanguages[row]))
    }
    
    
}
