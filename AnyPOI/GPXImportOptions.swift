//
//  GPXImportOptions.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


struct GPXImportOptions {
    var merge = true
    var importNew = true
    var importUpdate = true
    var textFilter = ""
    
    //FIXEDME: Add string translations in I18N
    var textualDescription:NSAttributedString {
        get {
            var descriptionString:NSAttributedString
            if !merge {
                descriptionString = NSAttributedString(string: "All POIs and data will be imported as new.")
            } else {
                if importNew {
                    if importUpdate {
                        descriptionString = NSAttributedString(string: "Existing POIs will be merged and new ones will be created.")
                    } else {
                        descriptionString = NSAttributedString(string: "Only new POIs will be imported.")
                    }
                } else {
                    if importUpdate {
                        descriptionString = NSAttributedString(string: "Only Existing POIs will be merged.")
                    } else {
                        return NSAttributedString(string: "Warning, nothing will be imported!", attributes: [NSForegroundColorAttributeName : UIColor.red])
                    }
                }
            }
            
            if textFilter.isEmpty {
                return descriptionString
            } else {
                let allString = NSMutableAttributedString(attributedString: descriptionString)
                allString.append(NSAttributedString(string: "\nOnly POIs matching \(textFilter)", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
                return allString
            }
        }
    }
}

extension GPXImportOptions : Equatable {}

func ==(lhs:GPXImportOptions, rhs:GPXImportOptions) -> Bool {
    return lhs.merge == rhs.merge && lhs.importNew == rhs.importNew && lhs.importUpdate == rhs.importUpdate && lhs.textFilter == rhs.textFilter
}

