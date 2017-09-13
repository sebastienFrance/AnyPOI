//
//  TestViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
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

class TestViewController: UIViewController, PHPhotoLibraryChangeObserver {

    
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

    var poi:PointOfInterest!
    
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
    fileprivate var snapshotter:MKMapSnapshotter!
    fileprivate var snapshotMapImageView:UIImageView?
    fileprivate var snapshotAlreadyDisplayed = false
    fileprivate var mapSnapshot:MKMapSnapshot?
    
    fileprivate var photosFetchResult:PHFetchResult<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // If the POI has not yet an Address, then we launch a revere geocoding
        // It should happen only on POI that have been imported from a file
        if !poi.hasPlacemark {
            GeoCodeMgr.sharedInstance.getPlacemark(poi: poi)
        }
        
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
        initializeMapSnapshot()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        poi.title = "Test4"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        snapshotter.start(completionHandler: { mapSnapshot, error in
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
//            snapshotMapImageView = UIImageView(image: snapshotImage)
//            snapshotMapImageView!.contentMode = .scaleAspectFill
//            snapshotMapImageView!.clipsToBounds = true

            //theTableView.reloadRows(at: [IndexPath(row: 0, section: Sections.mapViewAndPhotos)], with: .none)
        }
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
                //theTableView.reloadSections(IndexSet(arrayLiteral:0), with: .automatic)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
