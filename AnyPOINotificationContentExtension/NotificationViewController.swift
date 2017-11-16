//
//  NotificationViewController.swift
//  AnyPOINotificationContentExtension
//
//  Created by Sébastien Brugalières on 13/11/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MapKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var theMapView: MKMapView! {
        didSet {
            if let theMapView = theMapView {
                theMapView.mapType = .standard
                theMapView.showsBuildings = true
                theMapView.showsPointsOfInterest = false
                theMapView.showsCompass = false
                theMapView.showsScale = true
                theMapView.showsTraffic = false
                theMapView.showsPointsOfInterest = false
                theMapView.showsUserLocation = true
                theMapView.delegate = self
            }
        }
    }
    @IBOutlet weak var theOtherLabel: UILabel!
    @IBOutlet weak var theCategoryImage: UIImageView!
    @IBOutlet weak var theAddress: UILabel!
    
    var poi:NotifPointOfInterest? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        
        //let size = view.bounds.size
       // preferredContentSize = CGSize(width: size.width, height: size.height)
    }
    
    func didReceive(_ notification: UNNotification) {
        topLabel.text = notification.request.content.body
        
        let userInfo = notification.request.content.userInfo
        
        if let pois = userInfo[CommonProps.singlePOI] as? [String:String] {
           
            poi = NotifPointOfInterest(properties:pois)
            theMapView.addAnnotation(poi!)
            theOtherLabel.text = poi!.category?.localizedString
            theCategoryImage.image = poi!.category?.glyph
            theAddress.text = poi!.address

            if let regionRadius = userInfo[CommonProps.regionRadius] as? Double {
                theMapView.setRegion(MKCoordinateRegionMakeWithDistance(poi!.coordinate, regionRadius * 2.2, regionRadius * 2.2), animated: false)
                theMapView.add(MKCircle(center: poi!.coordinate, radius: regionRadius))
            } else {
                theMapView.setRegion(MKCoordinateRegionMakeWithDistance(poi!.coordinate, 200, 200), animated: false)
            }
            
        }
    }

}

extension NotificationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "POINotifId")
        
        if let thePoi = poi {
            marker.markerTintColor = thePoi.color
            marker.glyphImage = thePoi.category?.glyph
        }
        
        return marker
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //return MapUtils.getRendererForMonitoringRegion(overlay)
        
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.green
        renderer.lineWidth = 1.0
        renderer.fillColor = UIColor.green.withAlphaComponent(0.3)
        return renderer

    }
}
