//
//  ViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 06/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation
import Alamofire
import LocalAuthentication
import SafariServices
import PKHUD
import Contacts

class MapViewController: UIViewController, SearchControllerDelegate, MapCameraAnimationsDelegate, RouteProviderDelegate, DismissModalViewController, RouteEditorDelegate, ContainerViewControllerDelegate {

    
    //MARK: var Information view
    @IBOutlet weak var thirdActionBarStackView: UIStackView!
    @IBOutlet weak var fromToLabel: UILabel!
    @IBOutlet weak var stackViewFromTo: UIStackView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var selectedTransportType: UISegmentedControl!
    @IBOutlet weak var userLocationButton: UIButton!
    
    @IBOutlet weak var exitRouteModeButton: UIButton!
    // Route
    private var isRouteMode:Bool {
        get {
            if let _ = routeManager {
                return true
            } else {
                return false
            }
        }
    }
    private var routeFromCurrentLocation : MKRoute? {
        get {
            return routeManager?.routeFromCurrentLocation ?? nil
        }
    }
    private var isRouteFromCurrentLocationDisplayed:Bool {
        get {
            return routeManager?.isRouteFromCurrentLocationDisplayed ?? false
        }
    }
    var routeDatasource:RouteDataSource? {
        get {
            if let routeMgr = routeManager {
                return routeMgr.routeDatasource
            } else {
                return nil
            }
        }
    }
    
    private var routeManager:RouteManager?
    
    // Flyover
    private var isFlyoverRunning = false
    private var routeDirectionCounter = 0
    private var flyover:FlyoverWayPoints?

    // Others
    private var mapAnimation:MapCameraAnimations!
    private var poiCalloutDelegate:PoiCalloutDelegateImpl!
    private(set) var hideStatusBar = false

    var theSearchController:UISearchController?

    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?

    private(set) static var instance:MapViewController?
    
     enum InsertPoiPostion {
        case head, tail, currentPosition
    }

    enum RouteSectionProgress {
        case forward, backward, all
    }

    //MARK: Other vars

    @IBOutlet weak var theMapView: MKMapView! {
        didSet {
            if let theMapView = theMapView {
                theMapView.mapType = UserPreferences.sharedInstance.mapMode
                theMapView.zoomEnabled = true
                theMapView.scrollEnabled = true
                theMapView.pitchEnabled = true
                theMapView.rotateEnabled = true
                theMapView.showsBuildings = UserPreferences.sharedInstance.mapShowBuildings
                theMapView.showsPointsOfInterest = false
                theMapView.showsCompass = UserPreferences.sharedInstance.mapShowCompass
                theMapView.showsScale = UserPreferences.sharedInstance.mapShowScale
                theMapView.showsTraffic = UserPreferences.sharedInstance.mapShowTraffic
                theMapView.showsUserLocation = true
                theMapView.delegate = self
            }
        }
    }
    
    @IBOutlet var theLongPressGesture: UILongPressGestureRecognizer! {
        didSet {
            if let theLongPressGesture = theLongPressGesture {
                theLongPressGesture.minimumPressDuration = 0.5 // default value
                theLongPressGesture.numberOfTapsRequired = 0
                theLongPressGesture.numberOfTouchesRequired = 1 // Only one finger
                theLongPressGesture.allowableMovement = 10 // default distance
            }
        }
    }
    
    @IBOutlet weak var routeStackView: UIStackView!
    
    struct MapNotifications {
        static let showPOI = "showPOI"
        static let showPOI_Parameter_POI = "POI"
        static let showPOIs = "showPOIs"
        static let showPOIs_Parameter_POIs = "POIs"
        static let showGroup = "showGroup"
        static let showWikipedia = "showWikipedia"
        static let showPOI_Parameter_Wikipedia = "Wikipedia"
        static let showMapLocation = "showMapLocation"
    }
    
    func enableGestureRecognizer(status:Bool) {
        theMapView.scrollEnabled = status
        theMapView.pitchEnabled = status
        theMapView.rotateEnabled = status
        theMapView.zoomEnabled = status
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        poiCalloutDelegate = PoiCalloutDelegateImpl(mapView: theMapView, sourceViewController: self)
        // Mandatory: Get default group just to make sure it exists at the first startup
        POIDataManager.sharedInstance.initDefaultGroups()
        
    
        MapViewController.instance = self
        
        
        //FIXEDME: 😡😡⚡️⚡️ Should be moved to ViewWillAppear()
        mapAnimation = MapCameraAnimations(mapView: theMapView, mapCameraDelegate: self)
        mapAnimation.fromCurrentMapLocationTo(UserPreferences.sharedInstance.mapLatestCoordinate, withAnimation: false)
        
        // Subscribe all notifications to update the MapView
        subscribeNotifications()
        
        displayGroupsOnMap(POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: true)
        displayRouteInterfaces(false)
 
    }
    
    private func displayGroupsOnMap(groups:[GroupOfInterest], withMonitoredOverlays:Bool) {
        for currentGroup in groups {
            theMapView.addAnnotations(currentGroup.pois)

            // Add overlays if the poi is monitored
           if withMonitoredOverlays {
                for currentPOI in currentGroup.pois {
                    if let monitoredRegionOverlay = currentPOI.getMonitordRegionOverlay() {
                        theMapView.addOverlay(monitoredRegionOverlay)
                    }
                }
            }
        }
    }
    
    private func subscribeNotifications() {
        subscribeMapNotifications()
        
        // Database notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                                         name: NSManagedObjectContextObjectsDidChangeNotification,
                                                         object: DatabaseAccess.sharedInstance.managedObjectContext)
    }
    
    private func subscribeMapNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.showPOIFromNotification(_:)),
                                                         name: MapNotifications.showPOI,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.showPOIsFromNotification(_:)),
                                                         name: MapNotifications.showPOIs,
                                                         object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.showWikipediaFromNotification(_:)),
                                                         name: MapNotifications.showWikipedia,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.showGroupFromNotification(_:)),
                                                         name: MapNotifications.showGroup,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MapViewController.showMapLocationFromNotification(_:)),
                                                         name: MapNotifications.showMapLocation,
                                                         object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func prepareViewFromNavigation() {
        stopDim(0.0)
        flyover?.urgentStop()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }

    @IBAction func leftMenuButtonPushed(sender: UIBarButtonItem) {
        container!.toggleLeftPanel()
    }
    
    @IBAction func userLocationButton(sender: UIButton) {
      //  theMapView.setCenterCoordinate((LocationManager.sharedInstance.locationManager?.location?.coordinate)! , animated: true)
        if let userCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate {
            mapAnimation.fromCurrentMapLocationTo(userCoordinate)
        }
    }
    
    @IBAction func exitRouteMode(sender: AnyObject) {
        disableRouteMode()
    }
    
     //MARK: Route navigation buttons
    // Go to the next WayPoint
    @IBAction func showNextWayPoint(sender: UIBarButtonItem) {
        routeManager?.displayRouteSection(.forward)
    }
    
    // Go the the previous WayPoint
    @IBAction func showPreviousWayPoint(sender: UIBarButtonItem) {
        routeManager?.displayRouteSection(.backward)
    }

    @IBAction func showAllRoute(sender: UIBarButtonItem) {
        routeManager?.displayRouteSection(.all)
    }

    //MARK: Actions from Information view
    @IBAction func routeWayPointsOnlyButtonPushed(sender: UIButton) {
        routeManager?.showOnlyRouteAnnotations()
    }
    
    @IBAction func editButtonPushed(sender: UIButton) {
        performSegueWithIdentifier(storyboard.routeDetailsEditorId, sender: nil)
    }

    // Display actions buttons
    // Buttons always displayed:
    // - Flyover and Navigation are always displayed
    //
    // Buttons displayed only when a route section is shown:
    // - Show/Hide route from current location
    // - Delete To/From WayPoint
    @IBAction func actionsButtonPushed(sender: UIButton) {
        routeManager?.showActions()
    }

    @IBAction func selectedTransportTypeHasChanged(sender: UISegmentedControl) {
        routeManager?.setTransportType(MapUtils.segmentIndexToTransportType(sender))
    }

    private func addMonitoredRegionOverlays() {
        // Add MonitoredRegion overlays for annotations displayed on the Map
        for currentAnnotation in theMapView.annotations {
            if let currentPOI =  currentAnnotation as? PointOfInterest {
                // Add overlays if the poi is monitored
                if let monitoredRegionOverlay = currentPOI.getMonitordRegionOverlay() {
                    theMapView.addOverlay(monitoredRegionOverlay)
                }
            }
        }
    }
    
    // Display all overlays which include:
    //  - Route overlays
    //  - Monitored regions
    private func addRouteAllOverlays() {
        routeManager?.addRouteOverlays()
        addMonitoredRegionOverlays()
    }
    
    // Remove from the map all overlays used to display the route
    private func removeAllOverlays() {
        var overlaysToRemove = [MKOverlay]()
        for currentOverlay in theMapView.overlays {
            if currentOverlay is MKPolyline {
                overlaysToRemove.append(currentOverlay)
            }
        }
        
        theMapView.removeOverlays(overlaysToRemove)
    }
    
    // MARK: Route API
    func moveWayPoint(sourceIndex: Int, destinationIndex:Int) {
        routeManager?.moveWayPoint(sourceIndex, destinationIndex:destinationIndex)
    }
    
    func deleteWayPointAt(index:Int) {
        routeManager?.deleteWayPointAt(index)
    }
    
    func removeSelectedPoi() {
        routeManager?.removeSelectedPoi()
    }
    
    func addSelectedPoi() {
        if theMapView.selectedAnnotations.count > 0 {
            let poi = theMapView.selectedAnnotations[0] as! PointOfInterest
            
            if isRouteMode {
                routeManager?.addPoiToTheRoute(poi)
            } else {
                RouteEditorController().createRouteWith(self, delegate: self, routeName: poi.poiDisplayName!, pois: [poi])
            }
        }
    }
    
    private func refreshPoiAnnotation(poi:PointOfInterest, withType:MapUtils.PinAnnotationType) {
        if let annotationView = theMapView.viewForAnnotation(poi) as? WayPointPinAnnotationView {
            MapUtils.refreshPin(annotationView, poi: poi, delegate: poiCalloutDelegate, type: withType)
        }
    }
    
    // MARK: Route toolbar
    private func displayRouteInterfaces(show:Bool) {
        routeStackView.hidden = !show
        exitRouteModeButton.hidden = !show


        for currentItem in navigationItem.rightBarButtonItems! {
            if show {
                currentItem.tintColor = view.tintColor
                currentItem.enabled = true
            } else {
                currentItem.tintColor = UIColor.clearColor()
                currentItem.enabled = false
            }
        }
    }
    
    
    //MARK: RouteProviderDelegate
    func endRouteProvider() {
        stopDim()
    }

    //MARK: Search Controller
    @IBAction func startSearchController(sender: UIBarButtonItem) {
        let mySearchController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SearchControllerId") as! SearchController
        
        theSearchController = UISearchController(searchResultsController: mySearchController)
        
        mySearchController.theSearchController = theSearchController
        mySearchController.delegate = self
        
        //FIXEDME: 😡😡⚡️⚡️
        mySearchController.displayRoutes = true
        
        // Configure the UISearchController
        theSearchController!.searchResultsUpdater = self
        theSearchController!.delegate = self
        
        theSearchController!.searchBar.sizeToFit()
        theSearchController!.searchBar.delegate = self
        theSearchController!.searchBar.placeholder = "Place, POI/Group name"
        theSearchController!.hidesNavigationBarDuringPresentation = true
        theSearchController!.dimsBackgroundDuringPresentation = true
        
        presentViewController(theSearchController!, animated: true, completion: nil)
    }

    //MARK: SearchControllerDelegate
    func showPOIOnMap(poi : PointOfInterest) {
        // Mandatory to hide the UISearchController
        theSearchController?.active = false
        
        // Make sure the Group is Displayed before to show the POI
        // and then add it to the Map and set the Camera
        if !poi.parentGroup!.isGroupDisplayed {
            poi.parentGroup!.isGroupDisplayed = true
            POIDataManager.sharedInstance.updatePOIGroup(poi.parentGroup!)
            POIDataManager.sharedInstance.commitDatabase()
        }
        
        theMapView.selectAnnotation(poi, animated: false)
        mapAnimation.fromCurrentMapLocationTo(poi.coordinate)
    }


    func showPOIsOnMap(pois : [PointOfInterest]) {
        // Mandatory to hide the UISearchController
        theSearchController?.active = false

        for currentPoi in pois {
            // Make sure the Group is Displayed before to show the POI
            // and then add it to the Map and set the Camera
            if !currentPoi.parentGroup!.isGroupDisplayed {
                currentPoi.parentGroup!.isGroupDisplayed = true
                POIDataManager.sharedInstance.updatePOIGroup(currentPoi.parentGroup!)
            }
        }
        POIDataManager.sharedInstance.commitDatabase()
        let region = MapUtils.boundingBoxForAnnotations(pois)
        theMapView.setRegion(region, animated: UserPreferences.sharedInstance.mapAnimations)
    }


    func showGroupOnMap(group : GroupOfInterest) {
        theSearchController?.active = false
        
        if !group.isGroupDisplayed {
            group.isGroupDisplayed = true
            POIDataManager.sharedInstance.updatePOIGroup(group)
            POIDataManager.sharedInstance.commitDatabase()
        }
        
        let region = MapUtils.boundingBoxForAnnotations(group.pois)
        theMapView.setRegion(region, animated: UserPreferences.sharedInstance.mapAnimations)
    }
    
    func showMapLocation(mapItem: MKMapItem) {
        theSearchController?.active = false
        mapAnimation.fromCurrentMapLocationTo(mapItem.placemark.coordinate)
    }
    
    func showWikipediaOnMap(wikipedia : Wikipedia) {
        // Mandatory to hide the UISearchController
        theSearchController?.active = false
        if theMapView.selectedAnnotations.count > 0 {
            theMapView.deselectAnnotation(theMapView.selectedAnnotations[0], animated: false)
        }
        
        if let wikipediaPoi = POIDataManager.sharedInstance.findPOIWith(wikipedia) {
            if wikipediaPoi.parentGroup!.isGroupDisplayed {
                theMapView.selectAnnotation(wikipediaPoi, animated: true)
            }
        }
        
        mapAnimation.fromCurrentMapLocationTo(wikipedia.coordinates)
    }
    
    private func showAlertMessage(title:String, message:String) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: message, preferredStyle: .Alert)
        let actionClose = UIAlertAction(title: "Close", style: .Cancel) { alertAction in
            alertView.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertView.addAction(actionClose)
        presentViewController(alertView, animated: true, completion: nil)
    }
    
    // MARK: unwind Segue
    @IBAction func backToMapView(segue:UIStoryboardSegue) {
    }
    
    @IBAction func showRoute(segue:UIStoryboardSegue) {
        let routeViewController = segue.sourceViewController as! RoutesViewController
        if let routeToDisplay = routeViewController.getSelectedRoute() {
            enableRouteModeWith(routeToDisplay)
            container!.goToMap()
        }
    }
    
    func enableRouteModeWith(routeToDisplay:Route) {
        routeManager = RouteManager(datasource:RouteDataSource(route:routeToDisplay), routeDisplay: self, mapView: theMapView)
        routeManager?.loadAndDisplayOnMap()
    }

    private func disableRouteMode() {
        routeManager?.cleanup()
        routeManager = nil
        
        displayGroupsOnMap(POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: true)
    }
    
    @IBAction func backToMapWayPoint(unwindSegue:UIStoryboardSegue) {
        if let routeDetailsVC = unwindSegue.sourceViewController as? RouteDetailsViewController {
            // Get the index of the selected WayPoint and go to the next one to display the appropriate
            // Route section because in RouteDataSource the WayPointIndex = 0 is to display the full route
            // and when > 1 it displays only the route section of the WayPoint.
            routeManager?.showWayPointIndex(routeDetailsVC.getSelectedWayPointIndex())
        }
    }
    
    @IBAction func backToMapWayPointHome(unwindSegue:UIStoryboardSegue) {
        routeManager?.displayRouteSection(.all)
    }

    //MARK: handling notifications
    func showPOIFromNotification(notification : NSNotification) {
        let poi = notification.userInfo![MapNotifications.showPOI_Parameter_POI] as? PointOfInterest
        if let thePoi = poi {
            showPOIOnMap(thePoi)
        }
     }

    func showPOIsFromNotification(notification : NSNotification) {
        let pois = notification.userInfo![MapNotifications.showPOIs_Parameter_POIs] as? [PointOfInterest]
        if let thePois = pois {
            showPOIsOnMap(thePois)
        }
    }


    func showWikipediaFromNotification(notification : NSNotification) {
        // Position the MapView and the camera to display the area around the Wikipedia
        if let wikipedia = notification.userInfo![MapNotifications.showPOI_Parameter_Wikipedia] as? Wikipedia {
            showWikipediaOnMap(wikipedia)
        }
    }

    func showGroupFromNotification(notification : NSNotification) {
        if let group = notification.object as? GroupOfInterest {
            showGroupOnMap(group)
        }
    }
    
    func showMapLocationFromNotification(notification : NSNotification) {
        if let mapItem = notification.object as? MKMapItem {
            showMapLocation(mapItem)
        }
    }
    
    //MARK: Database Notifications
    func ManagedObjectContextObjectsDidChangeNotification(notification : NSNotification) {
        PoiNotificationUserInfo.dumpUserInfo("MapViewController", userInfo:notification.userInfo)
        manageNotification(notification)
    }
    
    private func manageNotification(notification : NSNotification) {
        let notifContent = PoiNotificationUserInfo(userInfo: notification.userInfo)
        
        // Just added!
        for updatedGroup in notifContent.updatedGroupOfInterest {
            let changedValues = updatedGroup.changedValues()
            if changedValues[GroupOfInterest.properties.groupColor] != nil {
                theMapView.removeAnnotations(updatedGroup.pois)
                if updatedGroup.isGroupDisplayed {
                    theMapView.addAnnotations(updatedGroup.pois)
                }
            } else if changedValues[GroupOfInterest.properties.isGroupDisplayed] != nil {
                theMapView.removeAnnotations(updatedGroup.pois)
                if updatedGroup.isGroupDisplayed {
                    displayGroupsOnMap([updatedGroup], withMonitoredOverlays: true)
                } else {
                    for currentPoi in updatedGroup.pois {
                        if let monitoredRegionOverlay = currentPoi.getMonitordRegionOverlay() {
                            theMapView.removeOverlay(monitoredRegionOverlay)
                        }
                    }
                }
            }
        }

        
        for newPoi in notifContent.insertedPois {
            theMapView.addAnnotation(newPoi)
        }
        
        for deletedPoi in notifContent.deletedPois {
            theMapView.removeAnnotation(deletedPoi)
            if let monitoredRegionOverlay = deletedPoi.getMonitordRegionOverlay() {
                theMapView.removeOverlay(monitoredRegionOverlay)
            }
        }
        
        for updatedPoi in notifContent.updatedPois {
            let changedValues = updatedPoi.changedValues()
            
            if changedValues[PointOfInterest.properties.poiRegionNotifyEnter] != nil ||
                changedValues[PointOfInterest.properties.poiRegionNotifyExit] != nil  ||
                changedValues[PointOfInterest.properties.poiCategory] != nil ||
                changedValues[PointOfInterest.properties.poiPlacemark] != nil {
                if let annotationView = theMapView.viewForAnnotation(updatedPoi) {
                    MapUtils.refreshDetailCalloutAccessoryView(updatedPoi, annotationView: annotationView, delegate: poiCalloutDelegate)
                }
            }
            
            if changedValues[PointOfInterest.properties.poiLatitude] != nil ||
                changedValues[PointOfInterest.properties.poiLongitude] != nil ||
                changedValues[PointOfInterest.properties.parentGroup] != nil {
                var isSelected = false
                for currentSelectedAnnotation in theMapView.selectedAnnotations {
                    if currentSelectedAnnotation === updatedPoi {
                        isSelected = true
                        break
                    }
                }
                
                theMapView.removeAnnotation(updatedPoi)
                theMapView.addAnnotation(updatedPoi)
                
                if isSelected {
                    theMapView.selectAnnotation(updatedPoi, animated: false)
                }
                
            }
            updateMonitoredRegionOverlayForPoi(updatedPoi, changedValues: changedValues)
        }
        
        
        // When the first WayPoint in added, we display a message
        if notifContent.insertedWayPoints.count > 0,
            let theRouteDatasource = routeDatasource where theRouteDatasource.wayPoints.count == 1 {
            PKHUD.sharedHUD.dimsBackground = false
            HUD.flash(.Label("Route start added"), delay:1.0, completion: nil)
            if let startPoi = theRouteDatasource.theRoute.startWayPoint?.wayPointPoi {
                // The starting point must be refreshed in the map with the right color
                refreshPoiAnnotation(startPoi, withType: .routeStart)
            }
        } else {
            
            if isRouteMode && notifContent.deletedRoutes.count > 0 {
                for currentRoute in notifContent.deletedRoutes {
                    if currentRoute === routeDatasource!.theRoute {
                        disableRouteMode()
                    }
                }
            } else {
                if isRouteMode && notifContent.updatedRoutes.count > 0 {
                    for currentRoute in notifContent.updatedRoutes {
                        if currentRoute === routeDatasource!.theRoute {
                            routeManager?.displayRouteInfos()
                        }
                    }
                }
                
                // Reload the route only on:
                //  - WayPoint deletion
                //  - WayPoint creation
                //  - WayPoint updated (for example when the transport type has been changed
                //  - POI update because the placemark can be received lately
                if notifContent.insertedWayPoints.count > 0 ||
                    notifContent.deletedWayPoints.count > 0 ||
                    notifContent.updatedWayPoints.count > 0 ||
                    notifContent.updatedPois.count > 0  {
                    routeManager?.reloadDirections()
                }
            }
        }
    }
 
    // Check if the MonitoredRegion overlay for a POI must be removed, added or updated when its properties have 
    // changed (notifyEnter, notifyExit and radius)
    // Warning: changedValues contains the list of changed properties with their NEW VALUE
    // Warning: The updatedPoi contains also the new properties values
    // Warning: To get the old values we must get the changedValuesForCurrentEvent()
    private func updateMonitoredRegionOverlayForPoi(updatedPoi:PointOfInterest, changedValues:[String:AnyObject]) {
        if !updatedPoi.isMonitored {
            // when the POI is not monitored we just need to remove the overlay from the map (if displayed)
            if let monitoredRegionOverlay = updatedPoi.getMonitordRegionOverlay() {
                
                // SEB: Warning, it seems there's a bug in Apple library in HybridFlyover, overlays are not 
                // always correctly removed from the map. Workaround is to change to Normal Map mode and then 
                // go back to Flyover!!!!
                theMapView.removeOverlay(monitoredRegionOverlay)
                updatedPoi.resetMonitoredRegionOverlay()
            }
        } else {
            // MonitoredRegion must be displayed only when the group is displayed
            if updatedPoi.parentGroup!.isGroupDisplayed {
                // When the radius has changed we must removed the old overlay (if it was displayed) to display
                // it with the new radius
                if changedValues[PointOfInterest.properties.poiRegionRadius] != nil ||
                    changedValues[PointOfInterest.properties.poiLatitude] != nil ||
                    changedValues[PointOfInterest.properties.poiLongitude] != nil {
                    if let monitoredRegionOverlay = updatedPoi.getMonitordRegionOverlay() {
                        theMapView.removeOverlay(monitoredRegionOverlay)
                    }

                    if let monitoredRegionOverlay = updatedPoi.resetMonitoredRegionOverlay() {
                        theMapView.addOverlay(monitoredRegionOverlay)
                    }
                } else {
                    // Get old values to check if the Overlay was already displayed
                    let oldValues = updatedPoi.changedValuesForCurrentEvent()
                
                    var oldRegionNotifyEnter = false
                    if oldValues[PointOfInterest.properties.poiRegionNotifyEnter] != nil {
                        oldRegionNotifyEnter = oldValues[PointOfInterest.properties.poiRegionNotifyEnter] as! Bool
                    } else {
                        oldRegionNotifyEnter = updatedPoi.poiRegionNotifyEnter
                    }
 
                    var oldRegionNotifyExit = false
                    if oldValues[PointOfInterest.properties.poiRegionNotifyExit] != nil {
                        oldRegionNotifyExit = oldValues[PointOfInterest.properties.poiRegionNotifyExit] as! Bool
                    } else {
                        oldRegionNotifyExit = updatedPoi.poiRegionNotifyExit
                    }
                    
                    // if both enter & exit have been changed and they are both set to true
                    // it means the overlay was not displayed and we need to add it on the Map
                    if !oldRegionNotifyEnter && !oldRegionNotifyExit {
                        if let monitoredRegionOverlay = updatedPoi.getMonitordRegionOverlay() {
                            theMapView.addOverlay(monitoredRegionOverlay)
                        }
                    }
                }
            }
        }
    }

    // MARK: Map Gestures 
    @IBAction func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
        switch (sender.state) {
        case .Ended:
            // Add the new POI in database
            // The Poi will be added on the Map thanks to DB notifications
            let coordinates = theMapView.convertPoint(sender.locationInView(theMapView), toCoordinateFromView: theMapView)
            let addedPoi = POIDataManager.sharedInstance.addPOI(coordinates, camera:theMapView.camera)
            
            if isRouteMode {
                // Add the POI as a new WayPoint in the route
                routeManager?.addPoiToTheRoute(addedPoi)
            }
        default:
            break
        }
    }

    //MARK: RouteEditorDelegate
    func routeCreated(route:Route) {
        enableRouteModeWith(route)
    }
    
    func routeEditorCancelled() {
        // Nothing to do
    }
    
    func routeUpdated(route:Route) {
        // Nothing to do
    }
    
    //MARK: DismissModalViewController
    func didDismiss() {
        stopDim()
    }

    //MARK: MapCameraAnimationsDelegate
    func mapAnimationCompleted() {
        // Nothing to do
    }

    //MARK: Segue
    private struct storyboard {
        static let showPOIDetails = "ShowPOIDetailsId"
        static let showMapOptions = "ShowMapOptions"
        static let showGroupContent = "showGroupContent"
        static let editGroup = "editPOIGroup"
        static let routeDetailsEditorId = "routeDetailsEditorId"
        static let openPhonesId = "openPhones"
        static let openEmailsId = "openEmails"
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == storyboard.showPOIDetails {
            let poiController = segue.destinationViewController as! POIDetailsViewController
            poiController.poi = sender as? PointOfInterest
        } else if segue.identifier == storyboard.showMapOptions {
            let viewController = segue.destinationViewController as! OptionsViewController
            viewController.theMapView = theMapView
        } else if segue.identifier == storyboard.showGroupContent {
            let viewController = segue.destinationViewController as! POIsViewController
            let group = sender as! GroupOfInterest
            viewController.showGroup(group)
        } else if segue.identifier == storyboard.editGroup {
            startDim()
            let viewController = segue.destinationViewController as! GroupConfiguratorViewController
            viewController.group = sender as? GroupOfInterest
            viewController.delegate = self
        } else if segue.identifier == PoiCalloutDelegateImpl.storyboard.startRoute {
            let viewController = segue.destinationViewController as! RouteProviderViewController
            startRouteProvider(viewController, sender: sender)
        } else if segue.identifier == storyboard.routeDetailsEditorId {
            let viewController = segue.destinationViewController as! RouteDetailsViewController
            viewController.wayPointsDelegate = self
        } else if segue.identifier == storyboard.openPhonesId {
            let viewController = segue.destinationViewController as! ContactsViewController
            viewController.poi = sender as? PointOfInterest
            viewController.mode = .phone
        } else if segue.identifier == storyboard.openEmailsId {
            let viewController = segue.destinationViewController as! ContactsViewController
            viewController.poi = sender as? PointOfInterest
            viewController.mode = .email 
        }
       
    }
    
    private func startRouteProvider(viewController: RouteProviderViewController, sender: AnyObject?) {
        startDim()
        if isRouteMode {
            if let targetPoi = sender as? PointOfInterest {
                viewController.initializeWith(theMapView.userLocation.coordinate, targetPoi: targetPoi, delegate:self)
            } else {
                if isRouteFromCurrentLocationDisplayed {
                    viewController.initializeWith(theMapView.userLocation.coordinate, targetPoi: routeDatasource!.toPOI!, delegate:self)
                } else {
                    viewController.initializeWithPois(routeDatasource!.fromPOI!, targetPoi: routeDatasource!.toPOI!, delegate:self)
                }
            }
        } else {
            viewController.initializeWith(theMapView.userLocation.coordinate, targetPoi: sender as! PointOfInterest, delegate:self)
        }
    }
}

extension MapViewController : RouteDisplayInfos {
    
    func doFlyover(routeDatasource:RouteDataSource) {
        flyover = FlyoverWayPoints(mapView: theMapView, datasource: routeDatasource, delegate: self)
        flyover!.doFlyover(self.routeFromCurrentLocation)
    }

    func hideRouteDisplay() {
        displayRouteInterfaces(false)
    }
    
    func getViewController() -> UIViewController {
        return self
    }
    
    func getPoiCalloutDelegate() -> PoiCalloutDelegate {
        return poiCalloutDelegate
    }
    
    func displayNewGroupsOnMap(groups:[GroupOfInterest], withMonitoredOverlays:Bool) {
        displayGroupsOnMap(groups, withMonitoredOverlays: withMonitoredOverlays)
    }

    func displayRouteEmptyInfos() {
        displayRouteInterfaces(true)
        fromToLabel.text = "Add a new or existing POI to start your route"
        distanceLabel.text = ""
        thirdActionBarStackView.hidden = true
    }
    
    // Show the summary infos when we are displaying the full route
    func displayRouteSummaryInfos(datasource:RouteDataSource) {
        displayRouteInterfaces(true)
        fromToLabel.text = datasource.routeName
        fromToLabel.textColor = UIColor.magentaColor()
        distanceLabel.text = datasource.routeDistanceAndTime
        fromToLabel.sizeToFit()
        thirdActionBarStackView.hidden = true
    }
    
    // Show the infos about the route between the 2 wayPoints or between the current location and the To
    func displayRouteWayPointsInfos(datasource:RouteDataSource) {
        displayRouteInterfaces(true)
        let distanceFormatter = NSLengthFormatter()
        distanceFormatter.unitStyle = .Short
        if !isRouteFromCurrentLocationDisplayed {
            // Show information between the 2 wayPoints
            fromToLabel.textColor = UIColor.whiteColor()

            fromToLabel.text = datasource.routeName
            distanceLabel.text = datasource.routeDistanceAndTime
        } else {
            // Show information between the current location and the To
            fromToLabel.text = "Current location"
            fromToLabel.textColor = UIColor.magentaColor()
            let expectedTravelTime = Utilities.shortStringFromTimeInterval(routeFromCurrentLocation!.expectedTravelTime) as String
            distanceLabel.text = "\(distanceFormatter.stringFromMeters(routeFromCurrentLocation!.distance)) in \(expectedTravelTime)"
            if let toDisplayName = datasource.toPOI?.poiDisplayName {
                fromToLabel.text =  fromToLabel.text! + " ➔ \(toDisplayName)"
            }
        }

        selectedTransportType.selectedSegmentIndex = MapUtils.transportTypeToSegmentIndex(datasource.fromWayPoint!.transportType!)
        
        thirdActionBarStackView.hidden = false
    }

    //MARK: Route overlays
    func refreshRouteAllOverlays() {
        theMapView.removeOverlays(theMapView.overlays)
        addRouteAllOverlays()
    }
}

extension MapViewController : UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    //MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let mySearchController = searchController.searchResultsController as! SearchController
        if let text = searchController.searchBar.text,
            filter = SearchController.ScopeFilter(rawValue: searchController.searchBar.selectedScopeButtonIndex) {
            mySearchController.updateWithText(text, region: theMapView.region, filter:filter)
        }
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(searchController: UISearchController) {
        // Navigate to the appropriate ViewController if an action has been triggered by the user
        // in the SearchController
        if let viewController = searchController.searchResultsController as? SearchController {
            switch viewController.selectedAction {
            case .None: break
            case .editGroup:
                // Put in a dispatch async to make sure the dimmer will be displayed appropriately (on top
                // of all, including the SearchController)
                // I cannot explain why I need to do that, if not done the SearchBar is not covered by the Dimmer
                // because the Dimmer is behind the Search Bar...
                dispatch_async(dispatch_get_main_queue()) {
                    if let group = viewController.selectedGroup {
                        self.performSegueWithIdentifier(storyboard.editGroup, sender: group)
                    }
                }
            case .showGroupContent:
                if let group = viewController.selectedGroup {
                    performSegueWithIdentifier(storyboard.showGroupContent, sender: group)
                }
            case .showRoute:
                if let route = viewController.selectedRoute {
                    enableRouteModeWith(route)
                }
            case .editPoi:
                if let poi = viewController.selectedPoi {
                    performSegueWithIdentifier(storyboard.showPOIDetails, sender: poi)
                }
            }
        }
        theSearchController = nil
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        // Reset the selectedGroup to make sure we are not triggering an action not requested by the user
        // when the searchController is dismissed
        // Warning: Keep in mind the SearchController is never removed from memory, it's still here even
        // when it's not displayed
        if let viewController = searchController.searchResultsController as? SearchController {
            viewController.selectedGroup = nil
        }
    }
    
    //MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // Perform Geocoding to find places using the text provided by the user
        CLGeocoder().geocodeAddressString(searchBar.text!) { placemarks, error in
            // Mandatory to hide the UISearchController from the screen
            self.theSearchController?.active = false
            if let theError = error {
                self.showAlertMessage("GeoCoding", message: theError.localizedDescription)
            } else {
                if let thePlacemark = placemarks where thePlacemark.count > 0 {
                    if let coordinate = thePlacemark[0].location?.coordinate {
                        self.mapAnimation.fromCurrentMapLocationTo(coordinate)
                    }
                } else {
                    self.showAlertMessage("PlaceMark", message: "No placemark found")
                }
            }
            
        }
    }
}

extension MapViewController : FlyoverWayPointsDelegate {
    
    //MARK: FlyoverWayPointsDelegate
    func flyoverWillStartAnimation() {
        isFlyoverRunning = true
        hideStatusBar = true
        if isRouteMode  {
            displayRouteInterfaces(false)
        }
        userLocationButton.hidden = true
        setNeedsStatusBarAppearanceUpdate() // Request to hide the status bar (managed by the ContainerVC)
        view.layoutIfNeeded() // Make sure the status bar will be remove smoothly
        
        // self.transportTypeSegment.hidden = true
        navigationController?.navigationBarHidden = true
    }
    
    func flyoverWillEndAnimation(urgentStop:Bool) {
        isFlyoverRunning = false
        
        hideStatusBar = false
        navigationController?.navigationBarHidden = false

       displayRouteInterfaces(true)
        userLocationButton.hidden = false
        
        setNeedsStatusBarAppearanceUpdate() // Request to show the status bar
        view.layoutIfNeeded() // Make sure the status bar will be displayed smoothly
        
    }
    
    func flyoverDidEnd(flyoverUpdatedPois:[PointOfInterest], urgentStop:Bool) {
        if isRouteMode  {
            if routeDatasource!.isBeforeRouteSections {
                removeAllOverlays()
                routeManager?.addRouteOverlays()
            }
            routeManager?.displayRouteInfos()
       }
        
        if !urgentStop {
            routeManager?.displayRouteMapRegion()
        }
        
        for currentPoi in flyoverUpdatedPois {
            routeManager?.refreshPoiAnnotation(currentPoi)
        }
        
        flyover = nil
    }
    
    func flyoverGetPoiCalloutDelegate() -> PoiCalloutDelegateImpl {
        return poiCalloutDelegate
    }
}

extension MapViewController : MKMapViewDelegate {
    //MARK: MKMapViewDelegate
    
    private struct mapViewAnnotationId {
        static let POIAnnotationId = "POIAnnotationId"
    }
    
    func mapView(mapView: MKMapView, didFailToLocateUserWithError error: NSError) {
        print("\(#function): didFailToLocateUserWithError")
        
        if(CLLocationManager.locationServicesEnabled() == false ||
            !(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways)){
            //location services are disabled or
            //user has not authorized permissions to use their location.
            
            // SEB: TBC request again authorization
            
            mapView.userTrackingMode = MKUserTrackingMode.None
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let thePoi = annotation as! PointOfInterest
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(WayPointPinAnnotationView.AnnotationId.wayPointAnnotationId) as? WayPointPinAnnotationView ?? MapUtils.createPin(thePoi)
        
        MapUtils.refreshPin(annotationView,
                            poi: thePoi,
                            delegate: poiCalloutDelegate,
                            type: routeManager?.getPoiType(thePoi) ?? MapUtils.PinAnnotationType.normal,
                            isFlyover:isFlyoverRunning)
        
        return annotationView
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let poi = view.annotation as! PointOfInterest
        if view.rightCalloutAccessoryView === control {
            self.performSegueWithIdentifier(storyboard.showPOIDetails, sender: poi)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            return MapUtils.customizePolyLine(overlay as! MKPolyline)
        } else if overlay is MKCircle {
            return MapUtils.getRendererForMonitoringRegion(overlay)
        } else {
            return MKOverlayRenderer()
        }
    }
    
    
    // Save automatically the latest Map position in userPrefs
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if !isFlyoverRunning {
            UserPreferences.sharedInstance.mapLatestCoordinate = mapView.centerCoordinate
        }
    }
}


