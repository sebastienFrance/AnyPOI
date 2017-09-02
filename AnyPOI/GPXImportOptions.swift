//
//  GPXImportOptions.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit


/// Contains the options used to perform import of POIs and Route
/// It provides also a textual description (I18N) of the configured import options
struct GPXImportOptions {
    struct POI {
        var importAsNew = false // When set to true, all POIs will be imported as new otherwise it's a merge
        var importNew = true
        var importUpdate = true
        var textFilter = ""
    }
    
    struct Route {
        var importAsNew = false // When set to true, all routes will be imported as new otherwise it's a merge
        var importNew = true
        var importUpdate = true
    }
    
    var poiOptions = POI()
    var routeOptions = Route()
    
    var poiTextualDescription:NSAttributedString {
        get {
            let descriptionString = NSMutableAttributedString()
            if poiOptions.importAsNew {
                descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgAllPOIsAsNew", comment: "")))
            } else {
                if poiOptions.importNew {
                    if poiOptions.importUpdate {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgMergeAndCreate", comment: "")))
                    } else {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgOnlyNewPOIs", comment: "")))
                    }
                } else {
                    if poiOptions.importUpdate {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgOnlyUpdate", comment: "")))
                    } else {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgNoImport", comment: ""),
                                                                    attributes: [NSAttributedStringKey.foregroundColor : UIColor.red]))
                    }
                }
            }
            
            if !poiOptions.textFilter.isEmpty {
                descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgFilter", comment: "")))
                descriptionString.append(NSAttributedString(string: " \"\(poiOptions.textFilter)\"",
                    attributes: [NSAttributedStringKey.foregroundColor : UIColor.purple]))
            }
            
            return descriptionString
        }
    }
    
    var routeTextualDescription:NSAttributedString {
        get {
            let descriptionString = NSMutableAttributedString()
            if routeOptions.importAsNew {
                descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgRoutesAllAsNew", comment: "")))
            } else {
                if routeOptions.importNew {
                    if routeOptions.importUpdate {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgRoutesMergeAndCreate", comment: "")))
                    } else {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgRoutesOnlyNew", comment: "")))
                    }
                } else {
                    if routeOptions.importUpdate {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgRoutesOnlyUpdate", comment: "")))
                    } else {
                        descriptionString.append(NSAttributedString(string: NSLocalizedString("ImportMsgRoutesNoImport", comment: ""),
                                                                    attributes: [NSAttributedStringKey.foregroundColor : UIColor.red]))
                    }
                }
            }
            
            return descriptionString
        }
    }
}

extension GPXImportOptions : Equatable {}

func ==(lhs:GPXImportOptions, rhs:GPXImportOptions) -> Bool {
    return lhs.poiOptions.importAsNew == rhs.poiOptions.importAsNew &&
        lhs.poiOptions.importNew == rhs.poiOptions.importNew &&
        lhs.poiOptions.importUpdate == rhs.poiOptions.importUpdate &&
        lhs.poiOptions.textFilter == rhs.poiOptions.textFilter &&
        lhs.routeOptions.importAsNew == rhs.routeOptions.importAsNew &&
        lhs.routeOptions.importNew == rhs.routeOptions.importNew &&
        lhs.routeOptions.importUpdate == rhs.routeOptions.importUpdate
}

