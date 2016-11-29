//
//  POIDetailsViewController.swift
//  SimplePOI
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
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 150
                theTableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    
    fileprivate struct Cste {
        static let mapViewCellSize = CGFloat(170.0)
        static let photosCellHeight = CGFloat(120.0)
        static let mapLatitudeDelta = CLLocationDegrees(0.01)
        static let mapLongitudeDelta = CLLocationDegrees(0.01)
        static let radiusSearchImage = CLLocationDistance(100)
        static let imageHeight = 100.0
        static let imageWidth = 100.0
    }

    var poi: PointOfInterest!
    fileprivate var contact:CNContact?

    fileprivate var storedOffsets = CGFloat(0.0)
    
    fileprivate struct LocalImage {
        let image:UIImage
        let asset:PHAsset
    }
    
    fileprivate var localImages = [LocalImage]()
    
    fileprivate var snapshotter:MKMapSnapshotter!
    fileprivate var snapshotImage:UIImage?
    fileprivate var snapshotMapImageView:UIImageView?
    fileprivate var snapshotAlreadyDisplayed = false
    fileprivate var mapSnapshot:MKMapSnapshot?

    var photosFetchResult:PHFetchResult<PHAsset>!
    
    //MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXEDME: Reload placemark because imported POIs have no Placemark! 
        if poi.placemarks == nil {
            poi.getPlacemark()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIDetailsViewController.wikipediaReady(_:)),
                                               name: NSNotification.Name(rawValue: PointOfInterest.Notifications.WikipediaReady),
                                               object: poi )
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        // FIXEDME: ⚡️😡 Check why this notifs doesn't report any changes in NSUpdateObjectKeys? What is the difference with NSManagedObjectContextObjectsDidChangeNotification?
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(POIDetailsViewController.contextDidSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               // name: NSManagedObjectContextDidSaveNotification,
            object: managedContext)
        
        
        title = poi.poiDisplayName
        if poi.poiIsContact {
            contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!)
        }
        
        poi.refreshIfNeeded()
        PHPhotoLibrary.shared().register(self)
        photosFetchResult = PHAsset.fetchAssets(with: nil)
        findSortedImagesAroundPoi()
        getMapSnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: utils
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
    
    
    // extract images and videos from Photos and ordered them by date (most recent first)
    fileprivate func findSortedImagesAroundPoi() {
        
        let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        
        for i in 0..<photosFetchResult.count {
            let currentObject = photosFetchResult.object(at: i) 
            if let imageLocation = currentObject.location {
                if poiLocation.distance(from: imageLocation) <= Cste.radiusSearchImage {
                    localImages.append(LocalImage(image: getAssetThumbnail(asset:currentObject), asset: currentObject))
                }
            }
        }
        
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
    
    fileprivate func getMapSnapshot() {
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MKCoordinateRegionMake(poi.coordinate, MKCoordinateSpanMake(Cste.mapLatitudeDelta, Cste.mapLatitudeDelta))
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .standard ? .standard : .satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSize(width: view.bounds.width, height: Cste.mapViewCellSize)
        snapshotOptions.scale = 2.0
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter.start(completionHandler: { mapSnapshot, error in
            if let error = error {
                print("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                self.mapSnapshot = mapSnapshot
                self.refreshMapImage()
            }
        })
    }
    
    func refreshMapImage() {
        if let mapImage = mapSnapshot?.image {
            
            UIGraphicsBeginImageContextWithOptions(mapImage.size, true, mapImage.scale)
            // Put the Map in the Graphic Context
            mapImage.draw(at: CGPoint(x: 0, y: 0))
            
            if poi.poiRegionNotifyEnter || poi.poiRegionNotifyExit {
                MapUtils.addCircleInMapSnapshot(poi.coordinate, radius: poi.poiRegionRadius, mapSnapshot: mapSnapshot!)
            }
            
            MapUtils.addAnnotationInMapSnapshot(poi, tintColor: poi.parentGroup!.color, mapSnapshot: mapSnapshot!)
            
            snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
            
            // Build the UIImageView only once for the tableView
            snapshotMapImageView = UIImageView(image: snapshotImage)
            snapshotMapImageView!.contentMode = .scaleAspectFill
            snapshotMapImageView!.clipsToBounds = true
            
           
            // Update the section 0 that display the Map as background
            if let cell = theTableView.cellForRow(at: IndexPath(row: 0, section: Sections.mapViewAndPhotos)) as? LocationCell {
                refreshMapBackground(cell)
            }
        }
    }

    // MARK: Notifications
    func contextDidSaveNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        PoiNotificationUserInfo.dumpUserInfo("POIDetailsViewController", userInfo: (notification as NSNotification).userInfo)
        
        for updatedPoi in notifContent.updatedPois {
            if updatedPoi === poi {
                let changedValues = updatedPoi.changedValues()
                
                if changedValues.count > 0 {
                    refreshMapImage()
                    title = poi.poiDisplayName
                }
                
                break
            }
        }
    }

    func wikipediaReady(_ notification : Notification) {
        theTableView.reloadSections(IndexSet(integer: Sections.wikipedia), with: .fade)
    }
    
    // MARK: ContactsDelegate
    func endContacts() {
        stopDim()
    }

    // MARK: Buttons

    @IBAction func AddToCalendarPushed(_ sender: UIButton) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { result, error in
            if let theError = error {
                print("\(#function) error has occured \(theError.localizedDescription)")
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
                    print("\(#function) NOK")
                }
            }
       }
    }
    
    
    @IBAction func actionButtonPushed(_ sender: UIBarButtonItem) {
        let mailActivity = PoiMailActivityItemSource(poi:poi)
        let messageActivity = MessageActivityItemSource(messageContent: poi.toMessage())
        
        var activityItems = [mailActivity, messageActivity]
        
        if !snapshotter.isLoading {
            let imageActivity = ImageAcvitityItemSource(image: snapshotImage!)
            activityItems.append(imageActivity)
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                    UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                    UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                    UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo]
        
        present(activityController, animated: true, completion: nil)
    }
    @IBAction func startMail(_ sender: UIButton) {
        if poi.poiIsContact {
            if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
                if contact.emailAddresses.count > 1 {
                    performSegue(withIdentifier: storyboard.openEmailsId, sender: poi)
                } else {
                    // To be completed, start a mail !
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

    }

    @IBAction func startPhoneCall(_ sender: UIButton) {
        
        if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
            if contact.phoneNumbers.count > 1 {
                performSegue(withIdentifier: storyboard.openPhonesId, sender: nil)
            } else {
                if let phoneNumber = ContactsUtilities.extractPhoneNumber(contact) {
                    Utilities.startPhoneCall(phoneNumber.stringValue)
                }
            }
        } else {
            Utilities.startPhoneCall(poi.poiPhoneNumber)
        }

    }

    @IBAction func showURL(_ sender: UIButton) {
        if let theContact = contact {
            Utilities.openSafariFrom(self, url: ContactsUtilities.extractURL(theContact), delegate: self)
        } else {
            Utilities.openSafariFrom(self, url: poi.poiURL, delegate: self)
        }
    }
    
    @IBAction func showContactDetails(_ sender: UIButton) {
        if let theContact = contact {
            if let theFullContact = ContactsUtilities.getContactForCNContactViewController(theContact.identifier) {
                let viewController = CNContactViewController(for: theFullContact)
                show(viewController, sender: self)
            }
        }
    }
    
    
    @IBAction func showWikipediaURL(_ sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        let wikiURL = WikipediaUtils.getMobileURLForPageId(wikipedia.pageId)
        Utilities.openSafariFrom(self, url: wikiURL, delegate: self)
    }
    
    @IBAction func goToWikipedia(_ sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showWikipedia),
                                                                  object: wikipedia,
                                                                  userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
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
            let poiController = segue.destination as! PoiEditorViewController
            poiController.thePoi = poi
        } else if segue.identifier == storyboard.showImageCollectionId {
            let viewController = segue.destination as! PoiImageCollectionViewController
            var assets = [PHAsset]()
            for currentLocalImages in localImages {
                assets.append(currentLocalImages.asset)
            }
            viewController.assets = assets
            viewController.startAssetIndex = sender as! Int
        } else if segue.identifier == storyboard.openPhonesId {
            let viewController = segue.destination as! ContactsViewController
            viewController.delegate = self
            viewController.poi = poi
            viewController.mode = .phone
            startDim()
        } else if segue.identifier == storyboard.openEmailsId {
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
        if let theContact = contact {
            cell.buildWith(poi, contact:theContact)
        } else {
            cell.buildWith(poi)
        }

        if !snapshotter.isLoading  {
            // If it's the first time we display the map, we fade in
            if !snapshotAlreadyDisplayed {
                snapshotAlreadyDisplayed = true
                snapshotMapImageView!.alpha = 0.0
                cell.backgroundView = snapshotMapImageView
                UIView.animate(withDuration: 0.5, animations: {
                    self.snapshotMapImageView!.alpha = UserPreferences.sharedInstance.mapMode == .standard ? 0.3 : 0.4
                })
            } else {
                // The map has been already display, we change it directly withoyt animations
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        storedOffsets = tableViewCell.collectionViewOffset
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.wikipedia {
            
            let wikipedia = poi.wikipedias[indexPath.row]
            
            
            let poiOfWiki = POIDataManager.sharedInstance.findPOIWith(wikipedia)
            if poiOfWiki == nil {
                _ = POIDataManager.sharedInstance.addPOI(wikipedia, group:poi.parentGroup!)
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showWikipedia),
                                                                      object: wikipedia,
                                                                      userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
            ContainerViewController.sharedInstance.goToMap()
        } else if indexPath.section == Sections.mapViewAndPhotos && indexPath.row == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MapViewController.MapNotifications.showPOI),
                                                                      object: nil,
                                                                      userInfo: [MapViewController.MapNotifications.showPOI_Parameter_POI: poi])
            ContainerViewController.sharedInstance.goToMap()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.mapViewAndPhotos  && indexPath.row == 0 {
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
