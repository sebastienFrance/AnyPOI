//
//  RouteBuilderViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 01/02/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class RouteBuilderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate  {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 122
                theTableView.rowHeight = UITableViewAutomaticDimension
            }
        }
    }
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    private var selectedPOIs = [PointOfInterest]()
    private var routeName = ""

    enum RouteBuilderMode {
        case newRoute, updateRoute
    }

    var mode = RouteBuilderMode.newRoute
    var theRoute:Route!

    var poisPerGroup:[GroupOfInterest:[PointOfInterest]]!
    var sortedGroups:[GroupOfInterest]!

    private var searchController:UISearchController!
    private var searchFilter = "" // Use to perform filtering on list of groups

    override func viewDidLoad() {
        super.viewDidLoad()

        reloadDataFromDatasource()
        if mode == .newRoute {
            saveButton.enabled = false
        }
        
        // Subscribe Keyboard notifications because when the keyboard is displayed we need to change the tableview insets
        // to make sure all rows of the table view can be correctly displayed (if not, then the latests rows are not visible)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POIsGroupListViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POIsGroupListViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        initSearchController()
    }
    
    private func reloadDataFromDatasource() {
        poisPerGroup = POIDataManager.sharedInstance.getAllPOISortedByGroup(searchFilter)
        sortedGroups = [GroupOfInterest](poisPerGroup.keys).sort {
            return $0.groupDisplayName! < $1.groupDisplayName!
        }

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove the search controller when moving to another view controller
        if searchController.active {
            searchController.dismissViewControllerAnimated(false, completion: nil)
        }
        
        if isMovingFromParentViewController() {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }

    }


    // Add a searchBar on top of the Navigation bar
    private func initSearchController() {
        // Open the search controller on itself
        searchController = UISearchController(searchResultsController: nil)
        
        // Configure the UISearchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Group name"
        searchController.obscuresBackgroundDuringPresentation = false // Mandatory when opening the search controller on itself
        // Don't hide the navigation bar, it will be just covered by the SearchController (it will avoid the tableview to slide below
        // the searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
    }

    @IBAction func searchButtonPushed(sender: UIBarButtonItem) {
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    //MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        // To be completed
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(searchController: UISearchController) {
        // to be completed -> nothing to do if we keep the filter!
        theTableView.reloadData()
    }
    
    
    //MARK: UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchFilter = searchText
        reloadDataFromDatasource()
        theTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.text = searchFilter
    }

    //MARK: Keyboard Mgt
    var contentInsetBeforeDisplayedKeyboard = UIEdgeInsetsZero
    
    // when the keyboard is displayed, we change the insets values of the tableView to take into account the size of
    // the keyboard (width or height depending on orientation)
    func keyboardWillShow(notification:NSNotification) {
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            //           let contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            var contentInsets:UIEdgeInsets
            if UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top, 0.0, keyboardSize.height, 0.0)
            } else {
                contentInsets = UIEdgeInsetsMake(theTableView.contentInset.top + 15, 0.0, keyboardSize.height, 0.0)
            }
            
            contentInsetBeforeDisplayedKeyboard = theTableView.contentInset
            theTableView.contentInset = contentInsets
            theTableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    
    func keyboardWillHide(notification:NSNotification) {
        theTableView.contentInset = contentInsetBeforeDisplayedKeyboard
        theTableView.scrollIndicatorInsets = contentInsetBeforeDisplayedKeyboard
    }


    // Update the database with the new route or update the existing route with the new
    // wayPoints
    @IBAction func savePushed(sender: UIBarButtonItem) {
        switch mode {
        case .newRoute:
            POIDataManager.sharedInstance.addRoute(routeName, routePath:selectedPOIs)
            POIDataManager.sharedInstance.commitDatabase()
        case .updateRoute:
            POIDataManager.sharedInstance.addWayPointToRoute(theRoute, pois:selectedPOIs)
            POIDataManager.sharedInstance.commitDatabase()
        break
        }

       dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelPushed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let length = textField.text!.characters.count - range.length + string.characters.count

        if length > 0 {
            let currentText = textField.text ?? ""
            routeName = (currentText as NSString).stringByReplacingCharactersInRange(range, withString: string)
        }
        saveButton.enabled = length > 0 ? true : false
        return true
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        saveButton.enabled = false
        textField.text = ""
        return true
    }

    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return mode == .newRoute ? sortedGroups.count + 1 : sortedGroups.count
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mode == .newRoute  && section == 0 {
            return 1
        } else {
            let group = getGroup(section)
            return poisPerGroup[group]!.count
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if mode == .newRoute && section == 0 {
            return nil
        } else {
            return getGroup(section).groupDisplayName
        }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if mode == .newRoute && section == 0 {
            let label = UILabel()
            label.text = "Route name"
            return label
        } else {
            let nib = UINib(nibName: "RouteBuilderSectionHeader", bundle: nil)
            let sectionHeaderView = nib.instantiateWithOwner(nil, options: nil)[0] as! RouteBuilderSectionHeader
            sectionHeaderView.sectionHeaderLabel.text = getGroup(section).groupDisplayName!
            DrawingUtils.insertCircleForGroup(sectionHeaderView.groupColor, fillColor:getGroup(section).color)

            return sectionHeaderView
        }
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }

    struct cellIdentifier {
        static let routeCellNameId = "routeCellNameId"
        static let routeBuilderPoiViewCellId = "RouteBuilderPoiViewCellId"
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if mode == .newRoute {
            if indexPath.section == 0 {
                let cell =  tableView.dequeueReusableCellWithIdentifier(cellIdentifier.routeCellNameId, forIndexPath: indexPath) as! RouteNameViewCell
                cell.routeName.text = routeName
                cell.routeName.delegate = self
                return cell
            } else {
                return cellWitPoi(indexPath)
            }
        } else {
            return cellWitPoi(indexPath)
        }
    }





    func getGroup(sectionIndex:Int) -> GroupOfInterest {
        return mode == .newRoute ? sortedGroups[sectionIndex - 1] : sortedGroups[sectionIndex]
    }

    func cellWitPoi(indexPath:NSIndexPath) -> UITableViewCell {
        let cell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.routeBuilderPoiViewCellId, forIndexPath: indexPath) as! RouteBuilderPoiViewCell


        let group = getGroup(indexPath.section)
        let poi = poisPerGroup[group]![indexPath.row]
        cell.initWith(poi, index: indexPath.row)

        if isPoiAlreadySelected(poi) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    func isPoiAlreadySelected(poi:PointOfInterest) -> Bool {
        for currentPoi in selectedPOIs {
            if currentPoi === poi {
                return true
            }
        }
        
        return false
    }

    // MARK: TableView datasource
    // Add or remove the selected WayPoint to/from the list
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (mode == .newRoute && indexPath.section >= 1) || (mode == .updateRoute) {
            let group = getGroup(indexPath.section)
            let poi = poisPerGroup[group]![indexPath.row]
            let theCell = tableView.cellForRowAtIndexPath(indexPath) as! RouteBuilderPoiViewCell

            for i in 0..<selectedPOIs.count {
                let currentPoi = selectedPOIs[i]
                if currentPoi === poi {
                    theCell.accessoryType = .None
                    selectedPOIs.removeAtIndex(i)
                    return
                }
            }
            
            selectedPOIs.append(poi)
            theCell.accessoryType = .Checkmark
        }
    }
    
    

}
