//
//  WikipediaOptionsViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol WikipediaLanguageUpdate : class {
    func wikiLanguageHasChanged(languageISOCode:String)
}

class WikipediaOptionsViewController: UIViewController  {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            theTableView.dataSource = self
            theTableView.delegate = self
            theTableView.estimatedRowHeight = 110
            theTableView.rowHeight = UITableViewAutomaticDimension
            theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
        }
    }
    
    private let initialLanguageISOCode = UserPreferences.sharedInstance.wikipediaLanguageISOcode
    private let initialMaxResults = UserPreferences.sharedInstance.wikipediaMaxResults
    private let initialNearByDistance = UserPreferences.sharedInstance.wikipediaNearByDistance
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Cleanup wikipedia cache if something has been changed
        if initialLanguageISOCode != UserPreferences.sharedInstance.wikipediaLanguageISOcode ||
            initialMaxResults != UserPreferences.sharedInstance.wikipediaMaxResults ||
            initialNearByDistance != UserPreferences.sharedInstance.wikipediaNearByDistance {
            for currentPoi in POIDataManager.sharedInstance.getAllPOI() {
                currentPoi.wikipedias.removeAll()
            }
        }
    }
    
    @IBAction func sliderHasChanged(sender: UISlider) {
        let cell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0)) as! WikipediaSliderTableViewCell
        if sender.tag == rowIndex.NearByDistance {
            updateWikiNearByDistance(sender, cell:cell)
        } else {
            updateWikiMaxResults(sender, cell:cell)
        }
    }
    
    func updateWikiNearByDistance(sender: UISlider, cell:WikipediaSliderTableViewCell) {
        let newValue = (Int(sender.value) / 100) * 100
        UserPreferences.sharedInstance.wikipediaNearByDistance = newValue
        let distanceFormatter = NSLengthFormatter()
        distanceFormatter.unitStyle = .Short
        cell.theLabel.text = "\(NSLocalizedString("NearByWikipediaOptions",comment:"")) \(distanceFormatter.stringFromMeters(Double(newValue)))"
    }
    
    func updateWikiMaxResults(sender: UISlider, cell:WikipediaSliderTableViewCell) {
        UserPreferences.sharedInstance.wikipediaMaxResults = Int(sender.value)
        cell.theLabel.text = "\(NSLocalizedString("MaxResultsWikipediaOptions",comment:"")) \(Int(sender.value))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WikipediaOptionsViewController: WikipediaLanguageUpdate {
    func wikiLanguageHasChanged(languageISOCode:String) {
        UserPreferences.sharedInstance.wikipediaLanguageISOcode = languageISOCode
        theTableView.reloadData()
    }
}

extension WikipediaOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    struct rowIndex {
        static let Language = 0
        static let LanguagePicker = 1
        static let NearByDistance = 2
        static let MaxResults = 3
    }
    
    struct storyboard {
        static let WikipediaSliderCellId = "WikipediaSliderCellId"
        static let WikiLanguagesCellId = "WikiLanguagesCellId"
        static let WikiSelectedLanguage = "WikiSelectedLanguage"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case rowIndex.Language:
            let cell = theTableView.dequeueReusableCellWithIdentifier(storyboard.WikiSelectedLanguage, forIndexPath: indexPath) as! WikiSelectedLanguageTableViewCell
            cell.theLabel.text = String.localizedStringWithFormat(NSLocalizedString("Wikipedia Language: %@", comment: ""), WikipediaLanguages.LanguageForISOcode(UserPreferences.sharedInstance.wikipediaLanguageISOcode))
            return cell
        case rowIndex.LanguagePicker:
            let cell = theTableView.dequeueReusableCellWithIdentifier(storyboard.WikiLanguagesCellId, forIndexPath: indexPath) as! WikiLanguagePickerTableViewCell
            cell.wikiUpdate = self
            return cell
        case rowIndex.MaxResults:
            let cell = theTableView.dequeueReusableCellWithIdentifier(storyboard.WikipediaSliderCellId, forIndexPath: indexPath) as! WikipediaSliderTableViewCell
            cell.theLabel.text = NSLocalizedString("MaxResultsWikipediaOptions", comment: "")
            cell.theSlider.continuous = true
            cell.theSlider.minimumValue = 10
            cell.theSlider.maximumValue = 100
            cell.theLabel.text = "\(NSLocalizedString("MaxResultsWikipediaOptions",comment:"")) \(UserPreferences.sharedInstance.wikipediaMaxResults)"
            cell.theSlider.setValue(Float(UserPreferences.sharedInstance.wikipediaMaxResults), animated: false)
            cell.theSlider.tag = indexPath.row
            return cell
       case rowIndex.NearByDistance:
            let cell = theTableView.dequeueReusableCellWithIdentifier(storyboard.WikipediaSliderCellId, forIndexPath: indexPath) as! WikipediaSliderTableViewCell
            cell.theSlider.continuous = true
            cell.theSlider.minimumValue = 100 // 100 meters
            cell.theSlider.maximumValue = 10000 // 10 km
            cell.theSlider.setValue(Float(UserPreferences.sharedInstance.wikipediaNearByDistance), animated: false)
            let distanceFormatter = NSLengthFormatter()
            distanceFormatter.unitStyle = .Short
            cell.theLabel.text = "\(NSLocalizedString("NearByWikipediaOptions",comment:"")) \(distanceFormatter.stringFromMeters(Double(UserPreferences.sharedInstance.wikipediaNearByDistance)))"
            cell.theSlider.tag = indexPath.row
            return cell
       default:
            return UITableViewCell()
        }
    }
}
