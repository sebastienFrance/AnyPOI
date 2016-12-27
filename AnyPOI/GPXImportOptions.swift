//
//  GPXImportOptions.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


struct GPXImportOptions {
    struct POI {
        var importAsNew = false
        var importNew = true
        var importUpdate = true
        var textFilter = ""
    }
    
    struct Route {
        var importAsNew = false
    }
    
    var poiOptions = POI()
    var routeOptions = Route()
    
    //FIXEDME: Add string translations in I18N
    var textualDescription:NSAttributedString {
        get {
            var descriptionString:NSAttributedString
            if poiOptions.importAsNew {
                descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgAllPOIsAsNew", comment: ""))
            } else {
                if poiOptions.importNew {
                    if poiOptions.importUpdate {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgMergeAndCreate", comment: ""))
                    } else {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgOnlyNewPOIs", comment: ""))
                    }
                } else {
                    if poiOptions.importUpdate {
                        descriptionString = NSAttributedString(string: NSLocalizedString("ImportMsgOnlyUpdate", comment: ""))
                    } else {
                        return NSAttributedString(string: NSLocalizedString("ImportMsgNoImport", comment: ""), attributes: [NSForegroundColorAttributeName : UIColor.red])
                    }
                }
            }
            
            if poiOptions.textFilter.isEmpty {
                return descriptionString
            } else {
                let allString = NSMutableAttributedString(attributedString: descriptionString)
                
                allString.append(NSAttributedString(string: NSLocalizedString("ImportMsgFilter", comment: "") + " \(poiOptions.textFilter)", attributes: [NSForegroundColorAttributeName : UIColor.blue]))
                return allString
            }
        }
    }
}

extension GPXImportOptions : Equatable {}

func ==(lhs:GPXImportOptions, rhs:GPXImportOptions) -> Bool {
    return lhs.poiOptions.importAsNew == rhs.poiOptions.importAsNew &&
        lhs.poiOptions.importNew == rhs.poiOptions.importNew &&
        lhs.poiOptions.importUpdate == rhs.poiOptions.importUpdate &&
        lhs.poiOptions.textFilter == rhs.poiOptions.textFilter &&
        lhs.routeOptions.importAsNew == rhs.routeOptions.importAsNew
}

