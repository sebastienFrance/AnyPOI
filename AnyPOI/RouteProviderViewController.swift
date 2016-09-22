//
//  RouteProviderViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 24/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

protocol RouteProviderDelegate : class {
    func endRouteProvider()
}

class RouteProviderViewController: UIViewController {

    @IBOutlet weak var routeDescription: UILabel!
    @IBOutlet weak var appleMapTransportType: UISegmentedControl!
    @IBOutlet weak var googleTransportType: UISegmentedControl!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var rootStackView: UIStackView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    private var sourceCoordinate:CLLocationCoordinate2D!
    private var targetCoordinate:CLLocationCoordinate2D!
    
    private var sourceLabel:String!
    private var targetLabel:String!
    
    private weak var mapController:RouteProviderDelegate!

    func initializeWith(sourceCoordinate:CLLocationCoordinate2D, targetPoi:PointOfInterest, delegate:RouteProviderDelegate) {
        sourceLabel = NSLocalizedString("CurrentLocationRouteProviderViewController", comment: "")
        self.sourceCoordinate = sourceCoordinate
        targetCoordinate = targetPoi.coordinate
        targetLabel = targetPoi.poiDisplayName!
        mapController = delegate
    }
    
    func initializeWithPois(sourcePoi:PointOfInterest, targetPoi:PointOfInterest, delegate:RouteProviderDelegate) {
        sourceLabel = sourcePoi.poiDisplayName
        sourceCoordinate = sourcePoi.coordinate
        targetCoordinate = targetPoi.coordinate
        targetLabel = targetPoi.poiDisplayName!
        mapController = delegate        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        appleMapTransportType.selectedSegmentIndex = 0
        googleTransportType.selectedSegmentIndex = 0

        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.layer.masksToBounds = true;
        
        routeDescription.text = "\(sourceLabel) to \(targetLabel)"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       
      //  navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func endRouteController() {
        dismissViewControllerAnimated(true, completion: nil)
        mapController.endRouteProvider()
    }

    @IBAction func appleMapButtonPushed(sender: UIButton) {
        var transportType = MKDirectionsTransportType.Automobile
        if appleMapTransportType.selectedSegmentIndex == 1 {
            transportType = .Walking
        } else if appleMapTransportType.selectedSegmentIndex == 2 {
            transportType = .Transit
        }
        
        RouteUtilities.startAppleMap(sourceCoordinate, sourceName:sourceLabel,
                                     destinationCoordinate: targetCoordinate, destinationName:targetLabel,
                                     transportType: transportType)
        endRouteController()
    }
    
    @IBAction func googleMapButtonPushed(sender: UIButton) {
        var transportType = "driving"
        if googleTransportType.selectedSegmentIndex == 1 {
            transportType = "walking"
        } else if googleTransportType.selectedSegmentIndex == 2 {
            transportType = "transit"
        } else if googleTransportType.selectedSegmentIndex == 3{
            transportType = "bicycling"
        }
        
        RouteUtilities.startGoogleMap(sourceCoordinate, destinationCoordinate: targetCoordinate, transportType: transportType)
        endRouteController()
   }
    
    @IBAction func wazeButtonPushed(sender: UIButton) {
        RouteUtilities.startWaze(sourceCoordinate, destinationCoordinate: targetCoordinate)
        endRouteController()
   }
    
    @IBAction func cityMapperButtonPushed(sender: UIButton) {
        RouteUtilities.startCityMapper(sourceCoordinate, destinationCoordinate: targetCoordinate)
        endRouteController()
   }
    
    @IBAction func cancelButtonPushed(sender: UIButton) {
        endRouteController()
    }
    
}
