//
//  RouteProviderTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 02/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import UberRides
import StoreKit

protocol RouteProviderDelegate : class {
    func endRouteProvider()
}


class RouteProviderTableViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            theTableView.delegate = self
            theTableView.dataSource = self
            theTableView.estimatedRowHeight = 102
            theTableView.rowHeight = UITableViewAutomaticDimension
            theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
        }
    }

    private var sourceCoordinate:CLLocationCoordinate2D!
    private var targetCoordinate:CLLocationCoordinate2D!
    
    private var sourceLabel:String!
    private var targetLabel:String!
    
    // uber
    let ridesClient = RidesClient()
    let uberButton = RideRequestButton()

    
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

        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.layer.masksToBounds = true;
        
        createUberButton()
        
        theTableView.reloadData()
    }
    
    private func createUberButton() {
        let targetLocation = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
        let sourceLocation = CLLocation(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude)
        var builder = RideParametersBuilder()
        builder.setPickupLocation(sourceLocation, nickname: "\(sourceLabel)")
        builder.setDropoffLocation(targetLocation, nickname: "\(targetLabel)")
        uberButton.rideParameters = builder.build()
        
        // use the same pickupLocation to get the estimate
        ridesClient.fetchCheapestProduct(pickupLocation: sourceLocation, completion: {
            product, response in
            if let productID = product?.productID { //check if the productID exists
                builder = builder.setProductID(productID)
                self.uberButton.rideParameters = builder.build()
                
                // show estimates in the button
                self.uberButton.loadRideInformation()
            }
        })
    }

    @IBAction func closeButtonPushed(sender: UIButton) {
        endRouteController()
    }
    
    @IBAction func navigationButtonPushed(sender: UIButton) {
        if let cell = theTableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0)) as? RouteProviderWithTransportTypeTableViewCell {
            switch sender.tag {
            case appIndex.AppleMaps:
                appleMapButtonPushed(cell.transportTypeSegment.selectedSegmentIndex)
            case appIndex.GoogleMaps:
                googleMapButtonPushed(cell.transportTypeSegment.selectedSegmentIndex)
            case appIndex.Waze:
                wazeButtonPushed()
            case appIndex.CityMapper:
                cityMapperButtonPushed()
            //        case appIndex.Uber:
            default:
                break
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func appleMapButtonPushed(selectedSegmentIndex:Int) {
        var transportType = MKDirectionsTransportType.Automobile
        if selectedSegmentIndex == 1 {
            transportType = .Walking
        } else if selectedSegmentIndex == 2 {
            transportType = .Transit
        }
        
        RouteUtilities.startAppleMap(sourceCoordinate, sourceName:sourceLabel,
                                     destinationCoordinate: targetCoordinate, destinationName:targetLabel,
                                     transportType: transportType)
        endRouteController()
    }
    
    
    func googleMapButtonPushed(selectedSegmentIndex:Int) {
        if RouteUtilities.hasGoogleMap() {
            var transportType = "driving"
            if selectedSegmentIndex == 1 {
                transportType = "walking"
            } else if selectedSegmentIndex == 2 {
                transportType = "transit"
            } else if selectedSegmentIndex == 3{
                transportType = "bicycling"
            }
            
            RouteUtilities.startGoogleMap(sourceCoordinate, destinationCoordinate: targetCoordinate, transportType: transportType)
            endRouteController()
        } else {
            openAppStoreFor(RouteUtilities.googleMapsProductId)
        }
    }
    
    
    func wazeButtonPushed() {
        if RouteUtilities.hasWaze() {
            RouteUtilities.startWaze(sourceCoordinate, destinationCoordinate: targetCoordinate)
            endRouteController()
        } else {
            openAppStoreFor(RouteUtilities.wazeProductId)
        }
    }
    
   func cityMapperButtonPushed() {
        if RouteUtilities.hasCityMapper() {
            RouteUtilities.startCityMapper(sourceCoordinate, destinationCoordinate: targetCoordinate)
            endRouteController()
        } else {
            openAppStoreFor(RouteUtilities.cityMapperProductId)
        }
    }
    
    private func openAppStoreFor(appId:Int) {
        let store = SKStoreProductViewController()
        store.delegate = self
        store.loadProductWithParameters([SKStoreProductParameterITunesItemIdentifier : appId], completionBlock: nil)
        presentViewController(store, animated: true, completion: nil)
    }

    
    func endRouteController() {
        dismissViewControllerAnimated(true, completion: nil)
        mapController.endRouteProvider()
    }

}

extension RouteProviderTableViewController : SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
}


extension RouteProviderTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return  "\(sourceLabel) to \(targetLabel)"
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    private struct appIndex {
        static let AppleMaps = 0
        static let GoogleMaps = 1
        static let Waze = 2
        static let CityMapper = 3
        static let Uber = 4
    }
    
    private struct storyboard {
        static let routeProviderWithTransportTypeCellId = "routeProviderWithTransportTypeCellId"
        static let uberCellId = "uberCellId"
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == appIndex.Uber {
            let cell = tableView.dequeueReusableCellWithIdentifier(storyboard.uberCellId, forIndexPath: indexPath) as! RouteProviderUberTableViewCell
            cell.uberView.addSubview(uberButton)
            
            return cell

         } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(storyboard.routeProviderWithTransportTypeCellId, forIndexPath: indexPath) as! RouteProviderWithTransportTypeTableViewCell
            
            switch indexPath.row {
            case appIndex.AppleMaps:
                cell.initForAppleMaps(appIndex.AppleMaps)
            case appIndex.GoogleMaps:
                cell.initForGoogleMaps(appIndex.GoogleMaps)
            case appIndex.Waze:
                cell.initForWaze(appIndex.Waze)
            case appIndex.CityMapper:
                cell.initForCityMapper(appIndex.CityMapper)
            case appIndex.Uber:
                cell.initForUber(appIndex.Uber)
            default:
                break
            }
            return cell
        }
    }
    
    
}
