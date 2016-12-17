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
                descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgAllPOIsAsNew", comment: ""))
            } else {
                if importNew {
                    if importUpdate {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgMergeAndCreate", comment: ""))
                    } else {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgOnlyNewPOIs", comment: ""))
                    }
                } else {
                    if importUpdate {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgOnlyUpdate", comment: ""))
                    } else {
                        return NSAttributedString(string: NSLocalizedString("ImportMsgNoImport", comment: ""), attributes: [NSForegroundColorAttributeName : UIColor.red])
                    }
                }
            }
            
            if textFilter.isEmpty {
                return descriptionString
            } else {
                let allString = NSMutableAttributedString(attributedString: descriptionString)
                
                allString.append(NSAttributedString(string: NSLocalizedString("ImportMsgFilter", comment: "") + " \(textFilter)", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
                return allString
            }
        }
    }
}

extension GPXImportOptions : Equatable {}

func ==(lhs:GPXImportOptions, rhs:GPXImportOptions) -> Bool {
    return lhs.merge == rhs.merge && lhs.importNew == rhs.importNew && lhs.importUpdate == rhs.importUpdate && lhs.textFilter == rhs.textFilter
}

