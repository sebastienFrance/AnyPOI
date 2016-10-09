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

class POIDetailsViewController: UIViewController, SFSafariViewControllerDelegate,  EKEventEditViewDelegate, ContactsDelegate {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let theTableView = theTableView {
                theTableView.dataSource = self
                theTableView.delegate = self
                theTableView.estimatedRowHeight = 150
                theTableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
            }
        }
    }
    
    private struct Cste {
        static let mapViewCellSize = CGFloat(170.0)
        static let photosCellHeight = CGFloat(120.0)
        static let mapLatitudeDelta = CLLocationDegrees(0.01)
        static let mapLongitudeDelta = CLLocationDegrees(0.01)
        static let radiusSearchImage = CLLocationDistance(100)
        static let imageHeight = 100.0
        static let imageWidth = 100.0
    }

    var poi: PointOfInterest!
    private var contact:CNContact?

    private var storedOffsets = CGFloat(0.0)
    
    private struct LocalImage {
        let image:UIImage
        let asset:PHAsset
    }
    
    private var localImages = [LocalImage]()
    
    private var snapshotter:MKMapSnapshotter!
    private var snapshotImage:UIImage?
    private var snapshotMapImageView:UIImageView?
    private var snapshotAlreadyDisplayed = false
    private var mapSnapshot:MKMapSnapshot?


    //MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(POIDetailsViewController.wikipediaReady(_:)),
                                                         name: PointOfInterest.Notifications.WikipediaReady,
                                                         object: poi )
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        // FIXEDME: ⚡️😡 Check why this notifs doesn't report any changes in NSUpdateObjectKeys? What is the difference with NSManagedObjectContextObjectsDidChangeNotification?
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(POIDetailsViewController.contextDidSaveNotification(_:)),
                                                         name: NSManagedObjectContextObjectsDidChangeNotification,
                                                         // name: NSManagedObjectContextDidSaveNotification,
            object: managedContext)
        
        
        title = poi.poiDisplayName
        if poi.poiIsContact {
            contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!)
        }
        
        poi.refreshIfNeeded()
        findSortedImagesAroundPoi()
        getMapSnapshot()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true
    }
    
    // MARK: utils
    
    
    // extract images and videos from Photos and ordered them by date (most recent first)
    private func findSortedImagesAroundPoi() {
        let fetchResult = PHAsset.fetchAssetsWithOptions(nil)
        let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        
        for i in 0..<fetchResult.count {
            let currentObject = fetchResult.objectAtIndex(i) as! PHAsset
            if let imageLocation = currentObject.location {
                if poiLocation.distanceFromLocation(imageLocation) <= Cste.radiusSearchImage {
                    localImages.append(LocalImage(image: getAssetThumbnail(currentObject), asset: currentObject))
                }
            }
        }
        
        localImages.sortInPlace() {
            if let firstDate = $0.asset.creationDate, secondDate = $1.asset.creationDate {
                switch firstDate.compare(secondDate) {
                case .OrderedAscending:
                    return false
                case .OrderedDescending:
                    return true
                case .OrderedSame:
                    return true
                }
            } else {
                return false
            }
        }
    }
    
    private func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.synchronous = true
        PHImageManager.defaultManager().requestImageForAsset(asset,
                                                             targetSize: CGSize(width: Cste.imageWidth, height: Cste.imageHeight),
                                                             contentMode: .AspectFit,
                                                             options: option,
                                                             resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
    private func getMapSnapshot() {
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MKCoordinateRegionMake(poi.coordinate, MKCoordinateSpanMake(Cste.mapLatitudeDelta, Cste.mapLatitudeDelta))
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .Standard ? .Standard : .Satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = CGSizeMake(view.bounds.width, Cste.mapViewCellSize)
        snapshotOptions.scale = 2.0
        snapshotter = MKMapSnapshotter(options: snapshotOptions)
        snapshotter.startWithCompletionHandler() { mapSnapshot, error in
            if let error = error {
                print("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                self.mapSnapshot = mapSnapshot
                self.refreshMapImage()
            }
        }
    }
    
    func refreshMapImage() {
        if let mapImage = mapSnapshot?.image {
            
            UIGraphicsBeginImageContextWithOptions(mapImage.size, true, mapImage.scale)
            // Put the Map in the Graphic Context
            mapImage.drawAtPoint(CGPointMake(0, 0))
            
            if poi.poiRegionNotifyEnter || poi.poiRegionNotifyExit {
                MapUtils.addCircleInMapSnapshot(poi.coordinate, radius: poi.poiRegionRadius, mapSnapshot: mapSnapshot!)
            }
            
            MapUtils.addAnnotationInMapSnapshot(poi, tintColor: poi.parentGroup!.color, mapSnapshot: mapSnapshot!)
            
            snapshotImage  = UIGraphicsGetImageFromCurrentImageContext()
            
            // Build the UIImageView only once for the tableView
            snapshotMapImageView = UIImageView(image: snapshotImage)
            snapshotMapImageView!.contentMode = .ScaleAspectFill
            snapshotMapImageView!.clipsToBounds = true
            
           
            // Update the section 0 that display the Map as background
            if let cell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: Sections.mapViewAndPhotos)) as? LocationCell {
                refreshMapBackground(cell)
            }
        }
    }

    // MARK: Notifications
    func contextDidSaveNotification(notification : NSNotification) {
        let notifContent = PoiNotificationUserInfo(userInfo: notification.userInfo)
        PoiNotificationUserInfo.dumpUserInfo("POIDetailsViewController", userInfo: notification.userInfo)
        
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

    func wikipediaReady(notification : NSNotification) {
        theTableView.reloadSections(NSIndexSet(index: Sections.wikipedia), withRowAnimation: .Fade)
    }
    
    // MARK: ContactsDelegate
    func endContacts() {
        stopDim()
    }

    // MARK: Buttons
    @IBAction func deletePoiPushed(sender: UIButton) {
        let deleteConfirmationBox = UIAlertController(title: NSLocalizedString("Warning", comment: ""), message: "\(NSLocalizedString("Delete", comment: "")) \(poi.poiDisplayName!)?", preferredStyle: .Alert)
        deleteConfirmationBox.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil))
        deleteConfirmationBox.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default, handler: { alertAction in
            POIDataManager.sharedInstance.deletePOI(POI: self.poi)
            POIDataManager.sharedInstance.commitDatabase()
            self.navigationController?.popViewControllerAnimated(true)
        }))
    
        presentViewController(deleteConfirmationBox, animated: true, completion: nil)
    }

    @IBAction func AddToCalendarPushed(sender: UIButton) {
        let eventStore = EKEventStore()
        eventStore.requestAccessToEntityType(.Event) { result, error in
            if let theError = error {
                print("\(#function) error has occured \(theError.localizedDescription)")
            } else {
                if result {
                    let addEvent = EKEvent(eventStore: eventStore)
                    addEvent.title = self.poi.poiDisplayName!
                    addEvent.location = self.poi.address
                    if let theContact = self.contact {
                        if let url = ContactsUtilities.extractURL(theContact) {
                            addEvent.URL = NSURL(string: url)
                        }
                    } else {
                        if let url = self.poi.poiURL {
                            addEvent.URL = NSURL(string: url)
                        }
                    }

                    let eventEditor = EKEventEditViewController()
                    eventEditor.editViewDelegate = self
                    eventEditor.eventStore = eventStore
                    eventEditor.event = addEvent
                    
                    self.presentViewController(eventEditor, animated: true, completion: nil)
              } else {
                    print("\(#function) NOK")
                }
            }
       }
    }
    
    
    @IBAction func actionButtonPushed(sender: UIBarButtonItem) {
        var activityItems = [UIActivityItemSource]()
        let mailActivity = MailActivityItemSource(mailContent:"<html> \(poi.toHTML()) </html>")
        let messageActivity = MessageActivityItemSource(messageContent: poi.toMessage())
        
        activityItems.append(mailActivity)
        activityItems.append(messageActivity)
        
        if !snapshotter.loading {
            let imageActivity = ImageAcvitityItemSource(image: snapshotImage!)
            activityItems.append(imageActivity)
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeAirDrop, UIActivityTypePostToVimeo,
                                                    UIActivityTypePostToWeibo, UIActivityTypeOpenInIBooks, UIActivityTypePostToFlickr, UIActivityTypePostToFacebook,
                                                    UIActivityTypePostToTwitter, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeCopyToPasteboard,
                                                    UIActivityTypeSaveToCameraRoll, UIActivityTypePostToTencentWeibo]
        
        presentViewController(activityController, animated: true, completion: nil)
    }
    @IBAction func startMail(sender: UIButton) {
        if poi.poiIsContact {
            if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
                if contact.emailAddresses.count > 1 {
                    performSegueWithIdentifier(storyboard.openEmailsId, sender: poi)
                } else {
                    // To be completed, start a mail !
                    if MFMailComposeViewController.canSendMail() {
                        let currentLabeledValue = contact.emailAddresses[0]
                        if let email = currentLabeledValue.value as? String {
                            let mailComposer = MFMailComposeViewController()
                            mailComposer.setToRecipients([email])
                            mailComposer.mailComposeDelegate = self
                            presentViewController(mailComposer, animated: true, completion: nil)
                        }
                    }
                    
                }
            }
        }

    }

    @IBAction func startPhoneCall(sender: UIButton) {
        
        if let contact = ContactsUtilities.getContactForDetailedDescription(poi.poiContactIdentifier!) {
            if contact.phoneNumbers.count > 1 {
                performSegueWithIdentifier(storyboard.openPhonesId, sender: nil)
            } else {
                if let phoneNumber = ContactsUtilities.extractPhoneNumber(contact) {
                    Utilities.startPhoneCall(phoneNumber.stringValue)
                }
            }
        } else {
            Utilities.startPhoneCall(poi.poiPhoneNumber)
        }

    }

    @IBAction func showURL(sender: UIButton) {
        if let theContact = contact {
            Utilities.openSafariFrom(self, url: ContactsUtilities.extractURL(theContact), delegate: self)
        } else {
            Utilities.openSafariFrom(self, url: poi.poiURL, delegate: self)
        }
    }
    
    @IBAction func showContactDetails(sender: UIButton) {
        if let theContact = contact {
            if let theFullContact = ContactsUtilities.getContactForCNContactViewController(theContact.identifier) {
                let viewController = CNContactViewController(forContact: theFullContact)
                showViewController(viewController, sender: self)
            }
        }
    }
    
    
    @IBAction func showWikipediaURL(sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        let wikiURL = WikipediaUtils.getMobileURLForPageId(wikipedia.pageId)
        Utilities.openSafariFrom(self, url: wikiURL, delegate: self)
    }
    
    @IBAction func goToWikipedia(sender: UIButton) {
        let wikipedia = poi.wikipedias[sender.tag]
        
        NSNotificationCenter.defaultCenter().postNotificationName(MapViewController.MapNotifications.showWikipedia,
                                                                  object: wikipedia,
                                                                  userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
        ContainerViewController.sharedInstance.goToMap()
    }

    //MARK: EKEventEditViewDelegate
    func eventEditViewController(controller: EKEventEditViewController, didCompleteWithAction action: EKEventEditViewAction) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: SFSafariViewControllerDelegate
    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        HUD.hide()
    }

    private struct storyboard {
        static let showPoiEditor = "showPoiEditor"
        static let showImageDetailsId = "showImageDetailsId"
        static let openPhonesId = "openPhones"
        static let openEmailsId = "openEmails"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == storyboard.showPoiEditor {
            let poiController = segue.destinationViewController as! PoiEditorViewController
            poiController.thePoi = poi
        } else if segue.identifier == storyboard.showImageDetailsId {
            let viewController = segue.destinationViewController as! PoiDetailImageViewController
            viewController.initWithAsset(sender as! PHAsset)
        } else if segue.identifier == storyboard.openPhonesId {
            let viewController = segue.destinationViewController as! ContactsViewController
            viewController.delegate = self
            viewController.poi = poi
            viewController.mode = .phone
            startDim()
        } else if segue.identifier == storyboard.openEmailsId {
            let viewController = segue.destinationViewController as! ContactsViewController
            viewController.delegate = self
            viewController.poi = poi
            viewController.mode = .email
            startDim()
        }
    }
}

extension POIDetailsViewController : UITableViewDataSource, UITableViewDelegate {

    private struct Sections {
        static let mapViewAndPhotos = 0
        static let wikipedia = 1
    }

    // MARK: UITableViewDataSource protocol
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == Sections.wikipedia ? NSLocalizedString("Wikipedia", comment: "") : nil
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == Sections.mapViewAndPhotos && indexPath.row == 1 {
            return Cste.photosCellHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    private struct cellIdentifier {
        static let locationCellId = "LocationCellId"
        static let mapCellId = "mapCellId"
        static let WikipediaCellId = "WikipediaCellId"
        static let PoiDetailsImagesCellId = "PoiDetailsImagesCellId"
        static let loadingCellId = "loadingCellId"
        static let NoWikipediaCellId = "NoWikipediaCellId"
    }
   
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Sections.mapViewAndPhotos {
            if indexPath.row == 0 {
                return configureMapAndPoiDetailsCell(indexPath)
            } else {
                let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.PoiDetailsImagesCellId, forIndexPath: indexPath) as! PoiDetailsImagesTableViewCell
                return theCell
            }
        } else {
            if poi.isWikipediaLoading {
                let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.loadingCellId, forIndexPath: indexPath) as! LoadingTableViewCell
                theCell.theLabel.text = NSLocalizedString("LoadingWikipediaPOIDetailsVC", comment: "")
                theCell.theActivityIndicator.startAnimating()
                return theCell
            } else {
                if poi.wikipedias.count == 0 {
                    let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.NoWikipediaCellId, forIndexPath: indexPath) as! NoWikipediaTableViewCell
                    return theCell
                } else {
                    let theCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier.WikipediaCellId, forIndexPath: indexPath) as! WikipediaCell
                    theCell.initWith(poi.wikipedias[indexPath.row], poi: poi, index: indexPath.row)
                    return theCell
                }
            }
        }
    }
    
    private func configureMapAndPoiDetailsCell(indexPath:NSIndexPath) -> UITableViewCell {
        let theCell = theTableView.dequeueReusableCellWithIdentifier(cellIdentifier.locationCellId, forIndexPath: indexPath) as! LocationCell
        
        refreshMapBackground(theCell)
        
        return theCell
    }
    
    private func refreshMapBackground(cell:LocationCell) {
        if let theContact = contact {
            cell.buildWith(poi, contact:theContact)
        } else {
            cell.buildWith(poi)
        }

        if !snapshotter.loading  {
            // If it's the first time we display the map, we fade in
            if !snapshotAlreadyDisplayed {
                snapshotAlreadyDisplayed = true
                snapshotMapImageView!.alpha = 0.0
                cell.backgroundView = snapshotMapImageView
                UIView.animateWithDuration(0.5, animations: {
                    self.snapshotMapImageView!.alpha = UserPreferences.sharedInstance.mapMode == .Standard ? 0.3 : 0.4
                })
            } else {
                // The map has been already display, we change it directly withoyt animations
                snapshotMapImageView!.alpha = UserPreferences.sharedInstance.mapMode == .Standard ? 0.3 : 0.4
                cell.backgroundView = snapshotMapImageView
            }
        } else {
            // If a new image is loading but we still have one in memory, we display it
            if let imageView = snapshotMapImageView {
                imageView.alpha = UserPreferences.sharedInstance.mapMode == .Standard ? 0.3 : 0.4
                cell.backgroundView = imageView
            }
        }
   
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? PoiDetailsImagesTableViewCell else { return }
        storedOffsets = tableViewCell.collectionViewOffset
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Sections.wikipedia {
            
            let wikipedia = poi.wikipedias[indexPath.row]
            
            
            let poiOfWiki = POIDataManager.sharedInstance.findPOIWith(wikipedia)
            if poiOfWiki == nil {
                POIDataManager.sharedInstance.addPOI(wikipedia, group:poi.parentGroup!)
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(MapViewController.MapNotifications.showWikipedia,
                                                                      object: wikipedia,
                                                                      userInfo: [MapViewController.MapNotifications.showPOI_Parameter_Wikipedia: wikipedia])
            ContainerViewController.sharedInstance.goToMap()
        } else if indexPath.section == Sections.mapViewAndPhotos && indexPath.row == 0 {
            NSNotificationCenter.defaultCenter().postNotificationName(MapViewController.MapNotifications.showPOI,
                                                                      object: nil,
                                                                      userInfo: [MapViewController.MapNotifications.showPOI_Parameter_POI: poi])
            ContainerViewController.sharedInstance.goToMap()
        }
    }
}

extension POIDetailsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}


extension POIDetailsViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localImages.count
    }
    
    private struct CollectionViewCell {
        static let poiImageCellId = "poiImageCellId"
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CollectionViewCell.poiImageCellId, forIndexPath: indexPath) as! PoiDetailsImagesCollectionViewCell
        cell.PoiImageView.image = localImages[indexPath.row].image
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if localImages[indexPath.row].asset.mediaType == .Video {
            PHImageManager.defaultManager().requestAVAssetForVideo(localImages[indexPath.row].asset, options: nil, resultHandler: { avAsset, audioMix, info in
                let playerItem = AVPlayerItem(asset: avAsset!)
                let avPlayer = AVPlayer(playerItem: playerItem)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = avPlayer
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(playerViewController, animated: true) {
                        playerViewController.player?.play()
                    }
                }
            })
        } else {
            performSegueWithIdentifier(storyboard.showImageDetailsId, sender: localImages[indexPath.row].asset)
        }
    }
}
