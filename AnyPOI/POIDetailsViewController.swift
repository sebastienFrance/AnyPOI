//
//  POIDetailsViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 07/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SafariServices
import CoreData
import PKHUD
import Contacts
import ContactsUI
import Photos
import AVKit
import EventKitUI
import MessageUI

class POIDetailsViewController: UIViewController, SFSafariViewControllerDelegate,  EKEventEditViewDelegate, ContactsDelegate, PHPhotoLibraryChangeObserver {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.dataSource = self
                tableView.delegate = self
                tableView.estimatedRowHeight = 150
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    fileprivate struct Cste {
        static let mapViewCellSize = CGFloat(170.0)
        static let photosCellHeight = CGFloat(120.0)
        static let mapLatitudeDelta = CLLocationDegrees(0.01)
        static let mapLongitudeDelta = CLLocationDegrees(0.01)
        static let radiusSearchImage = CLLocationDistance(500)
        static let maxImagesToDisplay = 30
        static let imageHeight = 100.0
        static let imageWidth = 100.0
    }

    // POI displayed in this view controller
    var poi: PointOfInterest!
    
    // Contact information related to the POI if it exists
    fileprivate var contact:CNContact?

    fileprivate var storedOffsets = CGFloat(0.0)
    
    // Image/Videos information
    fileprivate struct LocalImage {
        let image:UIImage
        let asset:PHAsset
        let distanceFrom:CLLocationDistance
    }
    
    // Images to be displayed in the collection view
    fileprivate var localImages = [LocalImage]()
    
    // Used to take a snapshot of the map to be displayed as a background of the cell displaying the POI information
    fileprivate var snapshotter:MKMapSnapshotter?
    fileprivate var snapshotMapImageView:UIImageView?
    fileprivate var snapshotAlreadyDisplayed = false
    fileprivate var mapSnapshot:MKMapSnapshot?
    
    fileprivate var photosFetchResult:PHFetchResult<PHAsset>!
    
    //MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()


        // If the POI has not yet an Address, then we launch a revere geocoding
        // It should happen only on POI that have been imported from a file
        if !poi.hasPlacemark {
            GeoCodeMgr.sharedInstance.getPlacemark(poi: poi)
        }
        
        // Subscribe a notification to update the table view displaying the Wikipedia article around the POI
        // We get this notification when the Wikipedia articles have been successfully downloaded (using the wiki REST API)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIDetailsViewController.wikipediaReady(_:)),
                                               name: NSNotification.Name(rawValue: PointOfInterest.Notifications.WikipediaReady),
                                               object: poi )
        
        // Subscribe notification to update the viewController when something related to the POI has been changed in database (like POI name,
        // color, description...)
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIDetailsViewController.contextDidSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: managedContext)
        
        
        title = poi.poiDisplayName
        
        // If the POI is attached to a contact then get the details
        if poi.poiIsContact, let contactId = poi.poiContactIdentifier {
            contact = ContactsUtilities.getContactForDetailedDescription(contactId)
        }
        
        poi.refreshIfNeeded()
        
        // Register changes and retreives all assets
        PHPhotoLibrary.shared().register(self)
        photosFetchResult = PHAsset.fetchAssets(with: nil)
        
        findSortedImagesAroundPoi()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initializeMapSnapshot()
    }
    // MARK: utils
    
    /// Recompute list of images when photolibrary has changed
    ///
    /// - Parameter changeInstance: Changes from PhotoLibrary
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let changeDetails = changeInstance.changeDetails(for: photosFetchResult) {
            photosFetchResult = changeDetails.fetchResultAfterChanges
            localImages.removeAll()
            
            DispatchQueue.main.sync {
                findSortedImagesAroundPoi()
                theTableView.reloadSections(IndexSet(arrayLiteral:0), with: .automatic)
            }
        }
    }
    
    
    /// extract images and videos from Photos and ordered them by date (most recent first) / distance
    fileprivate func findSortedImagesAroundPoi() {
        
        let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        
        // find all images located near the POI
        var filteredImages = [LocalImage]()
        for i in 0..<photosFetchResult.count {
            let currentObject = photosFetchResult.object(at: i) 
            if let imageLocation = currentObject.location {
                let distanceFromPoi = poiLocation.distance(from: imageLocation)
                if distanceFromPoi <= Cste.radiusSearchImage {
                    filteredImages.append(LocalImage(image: getAssetThumbnail(asset:currentObject),
                                                     asset: currentObject,
                                                     distanceFrom: distanceFromPoi))
                }
            }
        }
        // Filter the image to display only maxImagesToDisplay
        if filteredImages.count > Cste.maxImagesToDisplay {
            // Keep the nearest images and if two images are on the same location we keep the most recent
            filteredImages.sort() {
                if $0.distanceFrom < $1.distanceFrom {
                    return true
                } else if $0.distanceFrom == $1.distanceFrom {
                    if let firstDate = $0.asset.creationDate, let secondDate = $1.asset.creationDate {
                        switch firstDate.compare(secondDate) {
                        case .orderedAscending:
                            return false
                        case .orderedDescending:
                            return true
                        case .orderedSame:
                            return true
                        }
                    } else {
                        return false
                    }

                } else {
                    return false
                }
            }
            
            localImages = Array(filteredImages[0..<Cste.maxImagesToDisplay])
        } else {
            localImages = filteredImages
        }
        
        // Reorder by date to display first the most recent photos & videos
        localImages.sort() {
            if let firstDate = $0.asset.creationDate, let secondDate = $1.asset.creationDate {
                switch firstDate.compare(secondDate) {
                case .orderedAscending:
                    return false
                case .orderedDescending:
                    return true
                case .orderedSame:
                    return true
                }
            } else {
                return false
            }
        }
    }
    
    /// Get a thumbnail from an Image. It will be displayed in the UICollectionView
    fileprivate func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: Cste.imageWidth, height: Cste.imageHeight),
                                              contentMode: .aspectFit,
                                              options: option,
                                              resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
    /// Request a snapshot of the map around the POI (async)
    fileprivate func initializeMapSnapshot() {
        
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MKCoordinateRegionMake(poi.coordinate, MKCoordinateSpanMake(Cste.mapLatitudeDelta, Cste.mapLatitudeDelta))
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .standard ? .standard : .satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSize(width: view.bounds.width, height: Cste.mapViewCellSize)
        snapshotOptions.scale = 2.0
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
 
        snapshotter!.start(completionHandler: { mapSnapshot, error in
            if let error = error {
                NSLog("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                self.mapSnapshot = mapSnapshot
                self.refreshMapImage()
            }
        })
    }
    
    
    /// Display the Map snapshot as the background of the cell displaying POI information
    func refreshMapImage() {
        if let theMapSnapshot = mapSnapshot, let snapshotImage = MapUtils.configureMapImageFor(poi: poi, mapSnapshot: theMapSnapshot) {
            // Build the UIImageView only once for the tableView
            snapshotMapImageView = UIImageView(image: snapshotImage)
            snapshotMapImageView!.contentMode = .scaleAspectFill
            snapshotMapImageView!.clipsToBounds = true
            
            theTableView.reloadRows(at: [IndexPath(row: 0, section: Sections.mapViewAndPhotos)], with: .none)
        }
    }

    // MARK: Notifications
    
    
    /// Update the cell displaying the POI details when something has been changed (Category, Group, Title...)
    ///
    /// - Parameter notification: notification from the database
    @objc func contextDidSaveNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        
        for updatedPoi in notifContent.updatedPois {
            if updatedPoi === poi {
                let changedValues = updatedPoi.changedValues()
                
                // when something has changed we update the title and the content of the cell displaying the details
                if changedValues.count > 0 {
                    title = poi.poiDisplayName
                    theTableView.reloadRows(at: [IndexPath(row: 0, section: Sections.mapViewAndPhotos)], with: .none)
                }
                
                break
            }
        }
    }

    
    /// Update the section that displays Wikipedia articles. It's called when we get a notif that wikipedia articles are ready
    ///
    /// - Parameter notification: Notification
    @objc func wikipediaReady(_ notification : Notification) {
        theTableView.reloadSections(IndexSet(integer: Sections.wikipedia), with: .fade)
    }
    
    // MARK: ContactsDelegate
    func endContacts() {
        stopDim()
    }

    // MARK: Buttons

    
    /// Display an EKEventEditViewController to add an Event in the calendar
    /// The event is configured with the POI name, address, contact (if any) and url (if any)
    ///
    /// - Parameter sender: Button pushed by the user
    @IBAction func AddToCalendarPushed(_ sender: UIButton) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { result, error in
            if let theError = error {
                NSLog("\(#function) error has occured \(theError.localizedDescription)")
            } else {
                if result {
                    let addEvent = EKEvent(eventStore: eventStore)
                    addEvent.title = self.poi.poiDisplayName!
                    addEvent.location = self.poi.address
                    if let theContact = self.contact {
                        if let url = ContactsUtilities.extractURL(theContact) {
                            addEvent.url = URL(string: url)
                        }
                    } else {
                        if let url = self.poi.poiURL {
                            addEvent.url = URL(string: url)
                        }
                    }

                    let eventEditor = EKEventEditViewController()
                    eventEditor.editViewDelegate = self
                    eventEditor.eventStore = eventStore
                    eventEditor.event = addEvent
                    
                    self.present(eventEditor, animated: true, completion: nil)
              } else {
                    NSLog("\(#function) error with result")
                }
            }
       }
    }
    
    
    /// Launch a UIActivity to share a POI using email or SMS
    ///
    /// - Parameter sender: Bar button
    @IBAction func actionButtonPushed(_ sender: UIBarButtonItem) {
        let mailActivity = PoiMailActivityItemSource(poi:poi)
        let messageActivity = MessageActivityItemSource(messageContent: poi.toMessage())
        
        var activityItems = [mailActivity, messageActivity]
        
        // Get the Map image and attach it (useful for the email)
        if let theSnapshotter = snapshotter, !theSnapshotter.isLoading,
            let theMapSnapshot = mapSnapshot,
            let snapshotImage = MapUtils.configureMapImageFor(poi: poi, mapSnapshot: theMapSnapshot)  {
            let imageActivity = ImageAcvitityItemSource(image: snapshotImage)
            activityItems.append(imageActivity)
        }
        
        // Attach a GPX file containing the description of the POI
        if UserPreferences.sharedInstance.isAnyPoiUnlimited {
            activityItems.append(GPXActivityItemSource(pois: [poi]))
        }
        
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                    UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                    UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                    UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo]
        
        present(activityController, animated: true, completion: nil)
    }
    
    
    /// Open a Mail composer when there's only one email related to the POI. When several emails are available
    /// it opens a modal view and the user can select which one should be used to send an email.
    
    /// - Parameter sender: the Button
    @IBAction func startMail(_ sender: UIButton) {
        if poi.poiIsContact, let contactId = poi.poiContactIdentifier, let contact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            if contact.emailAddresses.count > 1 {
                performSegue(withIdentifier: storyboard.openEmailsId, sender: poi)
            } else {
                 if MFMailComposeViewController.canSendMail() {
                    let currentLabeledValue = contact.emailAddresses[0]
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.setToRecipients([currentLabeledValue.value as String])
                    mailComposer.mailComposeDelegate = self
                    present(mailComposer, animated: true, completion: nil)
                }
            }
        }
    }

    
    /// Start a phone call when there's only one phone number related to the POI. When there're several phone numbers
    /// available, it opens a modal view and the user can select which one should be used to start the phone call
    ///
    /// - Parameter sender: the Button
    @IBAction func startPhoneCall(_ sender: UIButton) {
        
        let phoneNumbers = poi.phoneNumbers
        if phoneNumbers.count > 1 {
            performSegue(withIdentifier: storyboard.openPhonesId, sender: nil)
        } else {
            Utilities.startPhoneCall(phoneNumbers[0].stringValue)
        }
    }

    
    /// Open a Safari view with the URL related to the POI.
    ///
    /// - Parameter sender: the Button
    @IBAction func showURL(_ sender: UIButton) {
        if let theContact = contact {
            Utilities.openSafariFrom(self, url: ContactsUtilities.extractURL(theContact), delegate: self)
        } else {
            Utilities.openSafariFrom(self, url: poi.poiURL, delegate: self)
        }
    }
    
    
    /// When a POI is related to a contact, it displays it details.
    ///
    /// - Parameter sender: the Button
    @IBAction func showContactDetails(_ sender: UIButton) {
        if let theContact = contact, let theFullContact = ContactsUtilities.getContactForCNContactViewController(theContact.identifier) {
            let viewController = CNContactViewController(for: theFullContact)
            show(viewController, sender: self)
        }
    }


    
    /// Open a Safari view with the URL of the wikipedia article related to the POI
    ///
    /// - Parameter sender: the button
    @IBAction func showWikipediaURL(_ sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        let wikiURL = WikipediaUtils.getMobileURLForPageId(wikipedia.pageId)
        Utilities.openSafariFrom(self, url: wikiURL, delegate: self)
    }
    
    
    /// When a Wikipedia article is selected we want to:
    ///  - Center the map on the Wikipedia location 
    ///  - Close this viewController to show the MapViewController
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func goToWikipedia(_ sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        
        // Sends the notification to update the mapView location
        NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showWikipedia),
                                                                  object: wikipedia,
                                                                  userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
        // Hide this view and display the mapViewController
        ContainerViewController.sharedInstance.goToMap()
    }

    //MARK: EKEventEditViewDelegate
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK: SFSafariViewControllerDelegate
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        HUD.hide()
    }

    fileprivate struct storyboard {
        static let showPoiEditor = "showPoiEditor"
        static let showImageCollectionId = "showImageCollectionId"
        static let openPhonesId = "openPhones"
        static let openEmailsId = "openEmails"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == storyboard.showPoiEditor {
            // Display the POI editor
            

            
            let poiController = segue.destination as! PoiEditorViewController
            poiController.thePoi = poi

        } else if segue.identifier == storyboard.showImageCollectionId {
            // Display the image / video details
            let viewController = segue.destination as! PoiImageCollectionViewController
            var assets = [PHAsset]()
            for currentLocalImages in localImages {
                assets.append(currentLocalImages.asset)
            }
            viewController.assets = assets
            viewController.startAssetIndex = sender as! Int
        } else if segue.identifier == storyboard.openPhonesId {
            // Display the list of Phones number related to the POI
            let viewController = segue.destination as! ContactsViewController
            viewController.delegate = self
            viewController.poi = poi
            viewController.mode = .phone
            startDim()
        } else if segue.identifier == storyboard.openEmailsId {
            // Display the list of emails related to the POI
            let viewController = segue.destination as! ContactsViewController
            viewController.delegate = self
            viewController.poi = poi
            viewController.mode = .email
            startDim()
        }
    }
}

extension POIDetailsViewController : UITableViewDataSource, UITableViewDelegate {

    fileprivate struct Sections {
        static let mapViewAndPhotos = 0
        static let wikipedia = 1
    }

    // MARK: UITableViewDataSource protocol
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.mapViewAndPhotos {
            return localImages.count > 0 ? 2 : 1
        } else {
            if poi.isWikipediaLoading {
                return 1
            } else {
                return poi.wikipedias.count == 0 ? 1 : poi.wikipedias.count
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == Sections.wikipedia ? NSLocalizedString("Wikipedia", comment: "") : nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Sections.mapViewAndPhotos && indexPath.row == 1 {
            // We want fixed height for the collectionView to display the list of images
            return Cste.photosCellHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    fileprivate struct cellIdentifier {
        static let locationCellId = "LocationCellId"
        static let mapCellId = "mapCellId"
        static let WikipediaCellId = "WikipediaCellId"
        static let PoiDetailsImagesCellId = "PoiDetailsImagesCellId"
        static let loadingCellId = "loadingCellId"
        static let NoWikipediaCellId = "NoWikipediaCellId"
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.mapViewAndPhotos {
            if indexPath.row == 0 {
                return configureMapAndPoiDetailsCell(indexPath)
            } else {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.PoiDetailsImagesCellId, for: indexPath) as! PoiDetailsImagesTableViewCell
                return theCell
            }
        } else {
            if poi.isWikipediaLoading {
                let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.loadingCellId, for: indexPath) as! LoadingTableViewCell
                theCell.theLabel.text = NSLocalizedString("LoadingWikipediaPOIDetailsVC", comment: "")
                theCell.theActivityIndicator.startAnimating()
                return theCell
            } else {
                if poi.wikipedias.count == 0 {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.NoWikipediaCellId, for: indexPath) as! NoWikipediaTableViewCell
                    return theCell
                } else {
                    let theCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier.WikipediaCellId, for: indexPath) as! WikipediaCell
                    theCell.initWith(poi.wikipedias[indexPath.row], poi: poi, index: indexPath.row)
                    return theCell
                }
            }
        }
    }
    
    fileprivate func configureMapAndPoiDetailsCell(_ indexPath:IndexPath) -> UITableViewCell {
        let theCell = theTableView.dequeueReusableCell(withIdentifier: cellIdentifier.locationCellId, for: indexPath) as! LocationCell
        
        refreshMapBackground(theCell)
        
        return theCell
    }
    
    fileprivate func refreshMapBackground(_ cell:LocationCell) {
        
        // Initialize the cell content with the POI and contact (if any)
        if let theContact = contact {
            cell.buildWith(poi, contact:theContact)
        } else {
            cell.buildWith(poi)
        }

        // When the map snapshot is available then we update the cell background with the map image
        if let theSnapshotter = snapshotter {
            if !theSnapshotter.isLoading  {
                // If it's the first time we display the map, we fade in
                if !snapshotAlreadyDisplayed {
                    snapshotAlreadyDisplayed = true
                    snapshotMapImageView!.alpha = 0.0
                    cell.backgroundView = snapshotMapImageView
                    UIView.animate(withDuration: 0.5, animations: {
                        self.snapshotMapImageView!.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.4
                    })
                } else {
                    // The map has been already display, we change it directly without animations
                    snapshotMapImageView!.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.4
                    cell.backgroundView = snapshotMapImageView
                }
            } else {
                // If a new image is loading but we still have one in memory, we display it
                if let imageView = snapshotMapImageView {
                    imageView.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.4
                    cell.backgroundView = imageView
                }
            }
        }
   
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        storedOffsets = tableViewCell.collectionViewOffset
    }
    
    
    /// When a Wikipedia article is selected in the table view it automatically create a new POI for it (if it doesn't already
    /// exist) and then we display the mapView centered on this new POI.
    /// When it's the POI's details row that has been selected we just display the mapView centered on it
    ///
    /// - Parameters:
    ///   - tableView: the tableView
    ///   - indexPath: index of the selected row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.wikipedia {
            if MapViewController.isAddPoiAuthorized() {
                let wikipedia = poi.wikipedias[indexPath.row]
                
                
                let poiOfWiki = POIDataManager.sharedInstance.findPOIWith(wikipedia)
                if poiOfWiki == nil {
                    _ = POIDataManager.sharedInstance.addPOI(wikipedia, group:poi.parentGroup!)
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showWikipedia),
                                                object: wikipedia,
                                                userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
                ContainerViewController.sharedInstance.goToMap()
            } else {
                Utilities.showAlertMaxPOI(viewController: self)
            }

        } else if indexPath.section == Sections.mapViewAndPhotos && indexPath.row == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showPOI),
                                                                      object: nil,
                                                                      userInfo: [MapViewController.MapNotifications.showPOI_Parameter_POI: poi])
            ContainerViewController.sharedInstance.goToMap()
        }
    }
    
    
    /// Manage the deletion of the POI (only on the cell displaying the POI's details)
    ///
    /// - Parameters:
    ///   - tableView: the tableView
    ///   - editingStyle: editing style
    ///   - indexPath: index path of the row
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.mapViewAndPhotos  && indexPath.row == 0 {
            
            // Cancel the async snapshotter request if not yet finished
            if let theSnapshotter = snapshotter, theSnapshotter.isLoading {
                theSnapshotter.cancel()
            }
            
            // Delete the POI from the database
            
            POIDataManager.sharedInstance.deletePOI(POI: self.poi)
            POIDataManager.sharedInstance.commitDatabase()
            _ = self.navigationController?.popViewController(animated: true)

        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == Sections.mapViewAndPhotos  && indexPath.row == 0 {
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if indexPath.section == Sections.mapViewAndPhotos  && indexPath.row == 0 {
            return NSLocalizedString("DeletePOIPoiDetailsVC", comment: "")
        }
        return nil
    }
    
}

extension POIDetailsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// UICollectionView is used only in the 1st section of the tableView to display the list of images / videos located near the POI
extension POIDetailsViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localImages.count
    }
    
    fileprivate struct CollectionViewCell {
        static let poiImageCellId = "poiImageCellId"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.poiImageCellId, for: indexPath) as! PoiDetailsImagesCollectionViewCell
        cell.PoiImageView.image = localImages[indexPath.row].image
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: storyboard.showImageCollectionId, sender: indexPath.row)
    }
}
