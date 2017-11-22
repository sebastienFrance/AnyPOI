//
//  DailyTravelViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 19/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class DailyTravelViewController: UIViewController {

    @IBOutlet weak var theMapView: MKMapView! {
        didSet {
            if let theMapView = theMapView {
                theMapView.mapType = UserPreferences.sharedInstance.mapMode
                theMapView.isZoomEnabled = true
                theMapView.isScrollEnabled = true
                theMapView.isPitchEnabled = true
                theMapView.isRotateEnabled = true
                theMapView.showsBuildings = true
                theMapView.showsPointsOfInterest = false
                theMapView.showsCompass = true
                theMapView.showsScale = true
                theMapView.showsTraffic = UserPreferences.sharedInstance.mapShowTraffic
                theMapView.showsPointsOfInterest = UserPreferences.sharedInstance.mapShowPointsOfInterest
                theMapView.showsUserLocation = true
                theMapView.delegate = self
            }

        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

       addLocationUpdateOnMap()
        // Do any additional setup after loading the view.
    }

    private func addLocationUpdateOnMap() {
        var index = 0
        var annotations = [DailyTravelAnnotation]()
        for currentLocation in LocationManager.sharedInstance.debugLocationUpdates {
            let newAnnotation = DailyTravelAnnotation(location: currentLocation.locationInfos, title: "\(index)")

            annotations.append(newAnnotation)
            index += 1
        }

        theMapView.addAnnotations(annotations)


        if annotations.count > 0 {
            theMapView.setRegion(MapUtils.boundingBoxForAnnotations(annotations), animated: false)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DailyTravelViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }


        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "DailyTravel") ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "DailyTravel")

        let marker = annotationView as! MKMarkerAnnotationView
        if let title = annotation.title {
            marker.glyphText = title
        }


        return annotationView
    }


}


