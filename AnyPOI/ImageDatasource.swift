//
//  ImageDatasource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 15/07/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import Foundation
import Photos
import CoreLocation

protocol ImageDatasourceDelegate: class {
    func imageSourceDidChange(datasource:ImageDatasource)
}

class ImageDatasource: NSObject {
    
    private struct Cste {
        static let radiusSearchImage = CLLocationDistance(500)
        static let maxImagesToDisplay = 30
        static let imageHeight = 100.0
        static let imageWidth = 100.0
    }
    
    private var photosFetchResult:PHFetchResult<PHAsset>!
    private var assetCache = PHCachingImageManager()
    
    // Image/Videos information
    private struct LocalImage {
        let asset:PHAsset
        let distanceFrom:CLLocationDistance
    }
    
    // Images to be displayed in the collection view
    private var localImages = [LocalImage]()
    private var centerCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

    var assets:[PHAsset] {
        return localImages.map() { return $0.asset }
    }
    
    var matchingImagesCount:Int { return localImages.count }
    weak var delegate:ImageDatasourceDelegate?
    
    
    override init() {
        super.init()
        
        // Register changes and retreives all assets
        PHPhotoLibrary.shared().register(self)
        photosFetchResult = PHAsset.fetchAssets(with: nil)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        assetCache.stopCachingImagesForAllAssets()
    }
    
    func searchImageAround(coordinate:CLLocationCoordinate2D) {
        centerCoordinate = coordinate
        findSortedImagesAroundPoi()
    }
    
    func getImage(index: Int) -> UIImage? {
        return getThumbnailFromCache(asset: localImages[index].asset)
    }
    
    /// extract images and videos from Photos and ordered them by date (most recent first) / distance
    private func findSortedImagesAroundPoi() {
        
        let poiLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        
        // find all images located near the POI
        var filteredImages = [LocalImage]()
        
        
        for i in 0..<photosFetchResult.count {
            let currentObject = photosFetchResult.object(at: i)
            if let imageLocation = currentObject.location {
                let distanceFromPoi = poiLocation.distance(from: imageLocation)
                if distanceFromPoi <= Cste.radiusSearchImage {
                    filteredImages.append(LocalImage(asset: currentObject,
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
        
        var allAssetsForCache = [PHAsset]()
        for currentLocalImage in localImages {
            allAssetsForCache.append(currentLocalImage.asset)
        }
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        assetCache.startCachingImages(for: allAssetsForCache,
                                      targetSize: CGSize(width: Cste.imageWidth, height: Cste.imageHeight),
                                      contentMode: .aspectFit,
                                      options: options)
    }
    
    /// Get a thumbnail from an Image. It will be displayed in the UICollectionView
    private func getThumbnailFromCache(asset: PHAsset) -> UIImage? {
        let option = PHImageRequestOptions()
        var thumbnail:UIImage?
        option.isSynchronous = true
        assetCache.requestImage(for: asset,
                                targetSize: CGSize(width: Cste.imageWidth, height: Cste.imageHeight),
                                contentMode: .aspectFit,
                                options: option,
                                resultHandler: {(result, info)->Void in
                                    thumbnail = result
        })
        return thumbnail
    }
    
}

extension ImageDatasource : PHPhotoLibraryChangeObserver {
    /// Recompute list of images when photolibrary has changed
    ///
    /// - Parameter changeInstance: Changes from PhotoLibrary
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let changeDetails = changeInstance.changeDetails(for: photosFetchResult) {
            photosFetchResult = changeDetails.fetchResultAfterChanges
            localImages.removeAll()
            
            DispatchQueue.main.sync {
                findSortedImagesAroundPoi()
                delegate?.imageSourceDidChange(datasource:self)
            }
        }
    }
}
