//
//  MapBackground.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 15/07/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

protocol MapBackgroundDelegate: class {
    func mapBackgroundDidLoad(mapBackground:MapBackground, mapImage:UIImage?)
}

class MapBackground {
    
    private struct Cste {
        static let mapViewCellSize = CGFloat(170.0)
        static let mapLatitudeDelta = CLLocationDegrees(0.01)
        static let mapLongitudeDelta = CLLocationDegrees(0.01)
        static let POISizeInMapView = CGFloat(10.0)
    }
    
    private var snapshotter:MKMapSnapshotter?
    private var mapSnapshot:MKMapSnapshot?
    
    // Returns an image of the Map with the POI(s). When the image is not yet ready it returns nil
    var mapImage:UIImage? {
        guard let pois = poisToShowOnMap, pois.count > 0, let theMapSnapshot = mapSnapshot else { return nil }
        
        // If there's only one POI, we put on the map the POI with its annotation and the monitoring circle if enabled
        // If there're more than one POI, we just put a small circle for each POI on the map
        if pois.count == 1 {
            return MapUtils.mapImageWithAnnotationFor(poi: pois[0],
                                                      mapSnapshot: theMapSnapshot,
                                                      withColor:pois[0].parentGroup!.color,
                                                      withMonitoringCircle:withMonitoringCircle,
                                                      radius:monitoringRadius,
                                                      isAlwaysLocation: LocationManager.sharedInstance.isAlwaysLocationAuthorized)
        } else {
            return MapUtils.mapImageFor(pois:pois,
                                        mapSnapshot:theMapSnapshot,
                                        poiSizeInMap:Cste.POISizeInMapView)
        }
    }
    
    // True when a Map is loading
    var isLoading:Bool {
        return snapshotter?.isLoading ?? false
    }
    
    private var poisToShowOnMap:[PointOfInterest]?
    
    weak var delegate:MapBackgroundDelegate?
    
    // Use it to configure the size of the Map image
    var imageSize = CGSize(width: 100, height: 100)
    
    // Configure it when the MonitoringCircle must be displayed
    // It can be used only when at most 1 Point of Interest is displayed on the map
    var withMonitoringCircle = false
    var monitoringRadius = Double(0.0)
    
    // Create an Image showing the POI in a Map with its annotation
    func loadFor(POI:PointOfInterest) {
        loadFor(POIs:[POI])
    }
    
    // Create an Image showing all the POIs in a Map with a small circle for each POI
    func loadFor(POIs:[PointOfInterest]) {
        poisToShowOnMap = POIs
        downloadMapSnapshot()
    }
    
    func cancel() {
        snapshotter?.cancel()
    }
    
    private func downloadMapSnapshot() {
        guard let pois = poisToShowOnMap, pois.count > 0 else { return }
        
        if let oldSnapshotter = snapshotter, oldSnapshotter.isLoading {
            oldSnapshotter.cancel()
        }
        
        mapSnapshot = nil
        snapshotter = MKMapSnapshotter(options: MapBackground.mapSnapshotOptionFrom(pois: pois, withImageSize: imageSize))
        
        snapshotter!.start(completionHandler: { mapSnapshot, error in
            if let error = error {
                NSLog("\(#function) Error when loading Map image with Snapshotter \(error.localizedDescription)")
            } else {
                // Get the image and update the cell displaying the map
                self.mapSnapshot = mapSnapshot
                if let _ = mapSnapshot {
                    self.delegate?.mapBackgroundDidLoad(mapBackground: self,
                                                        mapImage: self.mapImage)
                }
            }
        })

    }
    
    // This method is used to configure a MKSnapshotOptions to request a map to show one or several POIs.
    // When several POIs are provided, it computes the bounding box of the map to show all POIs
    // When only one POI is provided, it requests a map that is centered on the POI
    private static func mapSnapshotOptionFrom(pois:[PointOfInterest], withImageSize:CGSize) -> MKMapSnapshotOptions {
        let snapshotOptions = MKMapSnapshotOptions()
        
        if pois.count == 1 {
            snapshotOptions.region = MKCoordinateRegionMake(pois.first!.coordinate, MKCoordinateSpanMake(Cste.mapLatitudeDelta, Cste.mapLatitudeDelta))
        } else if pois.count > 1 {
            snapshotOptions.region = MapUtils.boundingBoxForAnnotations(pois)
        } else {
            return snapshotOptions
        }
        
        snapshotOptions.mapType = UserPreferences.sharedInstance.mapMode == .standard ? .standard : .satellite
        snapshotOptions.showsBuildings = false
        snapshotOptions.showsPointsOfInterest = false
        snapshotOptions.size = withImageSize
        snapshotOptions.scale = 2.0
        
        return snapshotOptions
    }
}
