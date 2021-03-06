//
//  InterfaceController.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 30/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import Foundation

import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    fileprivate(set) static var sharedInstance:InterfaceController?
    
    private var displayedWatchPOIs = [WatchPointOfInterest]()
    
    struct DebugInfos {
        static var sendMsgError = 0
        static var nothingToRefresh = 0
    }

    
    @IBOutlet var anyPOITable: WKInterfaceTable!
    
     override init() {
        super.init()
        NSLog("\(#function) called")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NSLog("\(#function) called")

        InterfaceController.sharedInstance = self
    }
    
    override func didAppear() {
        super.didAppear()
        NSLog("\(#function) called")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("\(#function) called")
        WatchSessionManager.sharedInstance.getPOIsAround()
        
        // While we are reloading we can still display what we have
        refreshTable()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NSLog("\(#function) called")

    }

    private struct Storyboard {
        static let poiRowId = "AnyPOIRow"
        static let emptyTableId = "EmptyPOITable"
    }
    
    private func refreshTableWith(error:CommonProps.MessageStatusCode, msg:String = "") {
        // when an error has occured, we must reset the content of the displayed POIs
        displayedWatchPOIs.removeAll()
        
        var message:String
        
        switch error {
        case .ok:
            NSLog("\(#function) Warning, this method should not be called when no error")
            return
        case .erroriPhoneLocationNotAuthorized:
            NSLog("\(#function) iPhone not authorized to get user location")
            message = NSLocalizedString("POIList_EnableLocation", comment: "")
        case .erroriPhoneLocationNotAvailable:
            NSLog("\(#function) user location not available on the iPhone")
            message = NSLocalizedString("POIList_LocationNotAvailable", comment: "")
        case .erroriPhoneCannotExtractCoordinatesFromMessage:
            NSLog("\(#function) iPhone cannot extract coordinates from Message")
            message = NSLocalizedString("POIList_internal", comment: "")
        case .errorWatchAppSendingMsgToiPhone:
            NSLog("\(#function) error when sending message from Watch -> iPhone")
            message = NSLocalizedString("POIList_cannotSentMsgToiPhone", comment: "")
        case .errorUnknown:
            NSLog("\(#function) unknown error")
            message = NSLocalizedString("POIList_UnknownError", comment: "")
        }

        var debugInfo = "\(Debug.showAll())\nMsgError: \(String(DebugInfos.sendMsgError)) NoUpd: \(String(DebugInfos.nothingToRefresh))"
        if msg != "" {
            debugInfo += "\nError cause: \(msg)"
        }
        
        // When there's no POI around the user, we just display a table with a message displaying there's no POI
        self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
        
        if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
            if CommonProps.isDebugEnabled {
                controller.titleLabel.setText("\(debugInfo)\n\(message)")
            } else {
                controller.titleLabel.setText("\(message)")
            }
        }
    }
    
    /// Refresh the table with a new set of POIs
    ///
    /// - Parameter newWatchPOIs: List of POIs to be displayed in the table
     func refreshTable() {
        
        if WatchDataSource.sharedInstance.status != CommonProps.MessageStatusCode.ok {
            refreshTableWith(error: WatchDataSource.sharedInstance.status, msg:WatchDataSource.sharedInstance.errorMsg)
            return
        }
        
       let newWatchPOIs = WatchDataSource.sharedInstance.pois

        
        NSLog("\(#function)")
        
        if newWatchPOIs.count == 0 {
            NSLog("\(#function) update with an empty list")

            // When there's no POI around the user, we just display a table with a message displaying there's no POI
            self.anyPOITable.setNumberOfRows(1, withRowType: Storyboard.emptyTableId)
            
            
            if let controller = self.anyPOITable.rowController(at: 0) as? EmptyRowController {
                if WatchSessionManager.sharedInstance.msgInProgress {
                    controller.titleLabel.setText(NSLocalizedString("POIList_Searching_POI", comment: ""))
                    controller.titleLabel.setTextColor(UIColor.white)
                } else {
                    controller.titleLabel.setText(NSLocalizedString("POIList_No_POI", comment: ""))
                    controller.titleLabel.setTextColor(UIColor.red)
                }
            }
        } else {
            // A list of POIs were already displayed and we need to display a new one
            // We want to change only what is needed
            
            if displayedWatchPOIs.count == 0 && anyPOITable.numberOfRows == 1 {
                // specific case when the previous content was empty (no POI) because we still have a row to show we have no POI around user location
                // => Replace table content with the new data
                anyPOITable.setNumberOfRows(newWatchPOIs.count, withRowType: Storyboard.poiRowId)
            } else {
                // Make the delta between two lists of POIs
                // Add or Remove rows when the new list of rows is greater or lower than the previous list
                if newWatchPOIs.count > displayedWatchPOIs.count {
                    var indexes = IndexSet()
                    for i in displayedWatchPOIs.count..<newWatchPOIs.count {
                        indexes.insert(i)
                    }
                    
                    anyPOITable.insertRows(at: indexes, withRowType: Storyboard.poiRowId)
                } else if newWatchPOIs.count < displayedWatchPOIs.count {
                    // Remove useless rows
                    var indexes = IndexSet()
                    for i in newWatchPOIs.count..<displayedWatchPOIs.count {
                        indexes.insert(i)
                    }
                    
                    anyPOITable.removeRows(at: indexes)
                }
            }
            
            
            // There is at least one POI to display, let's update the screen
            var hasUpdate = false
            for i in 0..<newWatchPOIs.count {
                if i < displayedWatchPOIs.count {
                    // Update the row only if it contains something different
                    if newWatchPOIs[i] != displayedWatchPOIs[i], let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: newWatchPOIs[i])
                        hasUpdate = true
                    }
                } else {
                    // It's a new row that need to be configured
                    if let controller = self.anyPOITable.rowController(at: i) as? AnyPOIRowController {
                        InterfaceController.updateRowWith(row: controller, watchPOI: newWatchPOIs[i])
                        hasUpdate = true
                    }
                }
            }
            
            if !hasUpdate {
                NSLog("\(#function) no update")
                DebugInfos.nothingToRefresh += 1
            } else {
                NSLog("\(#function) has update")
            }
        }
        
        displayedWatchPOIs = newWatchPOIs
    }
    
    static func updateRowWith(row:AnyPOIRowController, watchPOI:WatchPointOfInterest) {
        if CommonProps.isDebugEnabled {
            row.titleLabel.setText("(\(String(DebugInfos.sendMsgError)))(\(String(DebugInfos.nothingToRefresh)))\(watchPOI.poiTitle)\n\(watchPOI.distance)")
        } else {
            row.titleLabel.setText("\(watchPOI.poiTitle)\n\(watchPOI.distance)")
        }
        
        row.theCategory.setImage(watchPOI.category?.glyph)
        row.theCategory.setTintColor(UIColor.white)
        row.theGroupOfCategoryImage.setBackgroundColor(UIColor.clear)
        row.theSeparator.setColor(watchPOI.color)
        row.theGroupRow.setBackgroundColor(watchPOI.color.withAlphaComponent(0.3))
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return displayedWatchPOIs[rowIndex]
    }
    
}



