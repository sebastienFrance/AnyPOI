//
//  RouteProviderTableViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 02/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
//import UberRides
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
            theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
        }
    }

    fileprivate var sourceCoordinate:CLLocationCoordinate2D!
    fileprivate var targetCoordinate:CLLocationCoordinate2D!
    
    fileprivate var sourceLabel:String!
    fileprivate var targetLabel:String!
    
    // uber
    // SEB: Swift3 put in comments uber
    //let ridesClient = RidesClient()
    //let uberButton = RideRequestButton()

    
    fileprivate weak var mapController:RouteProviderDelegate!

    func initializeWith(_ sourceCoordinate:CLLocationCoordinate2D, targetPoi:PointOfInterest, delegate:RouteProviderDelegate) {
        sourceLabel = NSLocalizedString("CurrentLocationRouteProviderViewController", comment: "")
        self.sourceCoordinate = sourceCoordinate
        targetCoordinate = targetPoi.coordinate
        targetLabel = targetPoi.poiDisplayName!
        mapController = delegate
    }
    
    func initializeWithPois(_ sourcePoi:PointOfInterest, targetPoi:PointOfInterest, delegate:RouteProviderDelegate) {
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
  
        // SEB: Swift3 put in comments uber
//        createUberButton()
        
        theTableView.reloadData()
    }
    
    // SEB: Swift3 put in comments uber
//    fileprivate func createUberButton() {
//        let targetLocation = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
//        let sourceLocation = CLLocation(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude)
//        var builder = RideParametersBuilder()
//        builder.setPickupLocation(sourceLocation, nickname: "\(sourceLabel)")
//        builder.setDropoffLocation(targetLocation, nickname: "\(targetLabel)")
//        uberButton.rideParameters = builder.build()
//        
//        // use the same pickupLocation to get the estimate
//        ridesClient.fetchCheapestProduct(pickupLocation: sourceLocation, completion: {
//            product, response in
//            if let productID = product?.productID { //check if the productID exists
//                builder = builder.setProductID(productID)
//                self.uberButton.rideParameters = builder.build()
//                
//                // show estimates in the button
//                self.uberButton.loadRideInformation()
//            }
//        })
//    }

    @IBAction func closeButtonPushed(_ sender: UIButton) {
        endRouteController()
    }
    
    @IBAction func navigationButtonPushed(_ sender: UIButton) {
        if let cell = theTableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? RouteProviderWithTransportTypeTableViewCell {
            switch sender.tag {
            case appIndex.AppleMaps:
                appleMapButtonPushed(cell.transportTypeSegment.selectedSegmentIndex)
            case appIndex.GoogleMaps:
                googleMapButtonPushed(cell.transportTypeSegment.selectedSegmentIndex)
            case appIndex.HereMaps:
                hereMapButtonPushed(cell.transportTypeSegment.selectedSegmentIndex)
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
    
    
    func appleMapButtonPushed(_ selectedSegmentIndex:Int) {
        var transportType = MKDirectionsTransportType.automobile
        if selectedSegmentIndex == 1 {
            transportType = .walking
        } else if selectedSegmentIndex == 2 {
            transportType = .transit
        }
        
        RouteUtilities.startAppleMap(sourceCoordinate, sourceName:sourceLabel,
                                     destinationCoordinate: targetCoordinate, destinationName:targetLabel,
                                     transportType: transportType)
        endRouteController()
    }
    
    
    func googleMapButtonPushed(_ selectedSegmentIndex:Int) {
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
    
    func hereMapButtonPushed(_ selectedSegmentIndex:Int) {
        if RouteUtilities.hasHereMap {
            var transportType = "d"
            if selectedSegmentIndex == 1 {
                transportType = "w"
            } 
            
            RouteUtilities.startHereMap(sourceCoordinate, destinationCoordinate: targetCoordinate, transportType: transportType)
            endRouteController()
        } else {
            openAppStoreFor(RouteUtilities.hereMapProductId)
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
    
    fileprivate func openAppStoreFor(_ appId:Int) {
        let store = SKStoreProductViewController()
        store.delegate = self
        store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier : appId], completionBlock: nil)
        present(store, animated: true, completion: nil)
    }

    
    func endRouteController() {
        dismiss(animated: true, completion: nil)
        mapController.endRouteProvider()
    }

}

extension RouteProviderTableViewController : SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}


extension RouteProviderTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return  "\(sourceLabel!) ➜ \(targetLabel!)"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // SEB: Swift3 put 5 instead of 6 due to uber
        return 5
    }
    
    fileprivate struct appIndex {
        static let AppleMaps = 0
        static let GoogleMaps = 1
        static let HereMaps = 2
        static let Waze = 3
        static let CityMapper = 4
        static let Uber = 5
    }
    
    fileprivate struct storyboard {
        static let routeProviderWithTransportTypeCellId = "routeProviderWithTransportTypeCellId"
        static let uberCellId = "uberCellId"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == appIndex.Uber {
//            let cell = tableView.dequeueReusableCell(withIdentifier: storyboard.uberCellId, for: indexPath) as! RouteProviderUberTableViewCell
//            cell.uberView.addSubview(uberButton)
//            
//            return cell
              return UITableViewCell()
         } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: RouteProviderTableViewController.storyboard.routeProviderWithTransportTypeCellId, for: indexPath) as! RouteProviderWithTransportTypeTableViewCell
            
            switch indexPath.row {
            case appIndex.AppleMaps:
                cell.initForAppleMaps(appIndex.AppleMaps)
            case appIndex.GoogleMaps:
                cell.initForGoogleMaps(appIndex.GoogleMaps)
            case appIndex.HereMaps:
                cell.initForHereMaps(appIndex.HereMaps)
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
