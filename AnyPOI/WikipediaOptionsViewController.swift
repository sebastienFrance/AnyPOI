//
//  WikipediaOptionsViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 08/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol WikipediaLanguageUpdate : class {
    func wikiLanguageHasChanged(_ languageISOCode:String)
}

class WikipediaOptionsViewController: UIViewController  {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            theTableView.dataSource = self
            theTableView.delegate = self
            theTableView.estimatedRowHeight = 110
            theTableView.rowHeight = UITableViewAutomaticDimension
            theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
        }
    }
    
    fileprivate let initialLanguageISOCode = UserPreferences.sharedInstance.wikipediaLanguageISOcode
    fileprivate let initialMaxResults = UserPreferences.sharedInstance.wikipediaMaxResults
    fileprivate let initialNearByDistance = UserPreferences.sharedInstance.wikipediaNearByDistance
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
    
    @IBAction func sliderHasChanged(_ sender: UISlider) {
        let cell = theTableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as! WikipediaSliderTableViewCell
        if sender.tag == rowIndex.NearByDistance {
            updateWikiNearByDistance(sender, cell:cell)
        } else {
            updateWikiMaxResults(sender, cell:cell)
        }
    }
    
    func updateWikiNearByDistance(_ sender: UISlider, cell:WikipediaSliderTableViewCell) {
        let newValue = (Int(sender.value) / 100) * 100
        UserPreferences.sharedInstance.wikipediaNearByDistance = newValue
        let distanceFormatter = LengthFormatter()
        distanceFormatter.unitStyle = .short
        cell.theLabel.text = "\(NSLocalizedString("NearByWikipediaOptions",comment:"")) \(distanceFormatter.string(fromMeters: Double(newValue)))"
    }
    
    func updateWikiMaxResults(_ sender: UISlider, cell:WikipediaSliderTableViewCell) {
        UserPreferences.sharedInstance.wikipediaMaxResults = Int(sender.value)
        cell.theLabel.text = "\(NSLocalizedString("MaxResultsWikipediaOptions",comment:"")) \(Int(sender.value))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WikipediaOptionsViewController: WikipediaLanguageUpdate {
    func wikiLanguageHasChanged(_ languageISOCode:String) {
        UserPreferences.sharedInstance.wikipediaLanguageISOcode = languageISOCode
        theTableView.reloadData()
    }
}

extension WikipediaOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case rowIndex.Language:
            let cell = theTableView.dequeueReusableCell(withIdentifier: WikipediaOptionsViewController.storyboard.WikiSelectedLanguage, for: indexPath) as! WikiSelectedLanguageTableViewCell
            cell.theLabel.text = String.localizedStringWithFormat(NSLocalizedString("Wikipedia Language: %@", comment: ""), WikipediaLanguages.LanguageForISOcode(UserPreferences.sharedInstance.wikipediaLanguageISOcode))
            return cell
        case rowIndex.LanguagePicker:
            let cell = theTableView.dequeueReusableCell(withIdentifier: WikipediaOptionsViewController.storyboard.WikiLanguagesCellId, for: indexPath) as! WikiLanguagePickerTableViewCell
            cell.wikiUpdate = self
            return cell
        case rowIndex.MaxResults:
            let cell = theTableView.dequeueReusableCell(withIdentifier: WikipediaOptionsViewController.storyboard.WikipediaSliderCellId, for: indexPath) as! WikipediaSliderTableViewCell
            cell.theLabel.text = NSLocalizedString("MaxResultsWikipediaOptions", comment: "")
            cell.theSlider.isContinuous = true
            cell.theSlider.minimumValue = 10
            cell.theSlider.maximumValue = 100
            cell.theLabel.text = "\(NSLocalizedString("MaxResultsWikipediaOptions",comment:"")) \(UserPreferences.sharedInstance.wikipediaMaxResults)"
            cell.theSlider.setValue(Float(UserPreferences.sharedInstance.wikipediaMaxResults), animated: false)
            cell.theSlider.tag = indexPath.row
            return cell
       case rowIndex.NearByDistance:
            let cell = theTableView.dequeueReusableCell(withIdentifier: WikipediaOptionsViewController.storyboard.WikipediaSliderCellId, for: indexPath) as! WikipediaSliderTableViewCell
            cell.theSlider.isContinuous = true
            cell.theSlider.minimumValue = 100 // 100 meters
            cell.theSlider.maximumValue = 10000 // 10 km
            cell.theSlider.setValue(Float(UserPreferences.sharedInstance.wikipediaNearByDistance), animated: false)
            let distanceFormatter = LengthFormatter()
            distanceFormatter.unitStyle = .short
            cell.theLabel.text = "\(NSLocalizedString("NearByWikipediaOptions",comment:"")) \(distanceFormatter.string(fromMeters: Double(UserPreferences.sharedInstance.wikipediaNearByDistance)))"
            cell.theSlider.tag = indexPath.row
            return cell
       default:
            return UITableViewCell()
        }
    }
}
