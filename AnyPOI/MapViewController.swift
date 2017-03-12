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

class MapViewController: UIViewController, SearchControllerDelegate, ContainerViewControllerDelegate {

    static let MAX_POI_WITHOUT_LICENSE = 15

    //MARK: var Information view
    @IBOutlet weak var thirdActionBarStackView: UIStackView!
    @IBOutlet weak var fromToLabel: UILabel!
    @IBOutlet weak var stackViewFromTo: UIStackView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var navigationButton: UIButton!
    @IBOutlet weak var selectedTransportType: UISegmentedControl!
    @IBOutlet weak var userLocationButton: UIButton!
    
    @IBOutlet weak var mapFilterButton: UIButton!
    
    @IBOutlet weak var exitRouteModeButton: UIButton!
    
    
    
    // Route
    fileprivate var isRouteMode:Bool {
        get {
            return routeManager == nil ? false : true
        }
    }
    
    var routeDatasource:RouteDataSource? {
        get {
            return routeManager?.routeDatasource
        }
    }
    
    fileprivate(set) var routeManager:RouteManager?
    
    // Flyover
    fileprivate var isFlyoverAroundPoi = false
    fileprivate var isFlyoverRunning = false
    fileprivate var flyover:FlyoverWayPoints?
    fileprivate var mapRegionBeforeFlyover:MKCoordinateRegion?

    // Others
    fileprivate var mapAnimation:MapCameraAnimations!
    fileprivate(set) var poiCalloutDelegate:PoiCalloutDelegateImpl!
    fileprivate(set) var hideStatusBar = false

    var theSearchController:UISearchController?

    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?

    fileprivate(set) static var instance:MapViewController?
    
    fileprivate var isFirstInitialization = true
    

    
    //MARK: Filter Mgt
    fileprivate var categoryFilter = Set<CategoryUtils.Category>()
    fileprivate var filteredPOIs = Set<PointOfInterest>()
    fileprivate var filterPOIsNotInRoute = false

    //MARK: Other vars
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
    
    func enableGestureRecognizer(_ status:Bool) {
        theMapView.isScrollEnabled = status
        theMapView.isPitchEnabled = status
        theMapView.isRotateEnabled = status
        theMapView.isZoomEnabled = status
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateFilterStatus()

        
        poiCalloutDelegate = PoiCalloutDelegateImpl(mapView: theMapView, sourceViewController: self)
        // Mandatory: Get default group just to make sure it exists at the first startup
        POIDataManager.sharedInstance.initDefaultGroups()
        
    
        MapViewController.instance = self
        
        
        // Subscribe all notifications to update the MapView
        subscribeNotifications()
        
        displayGroupsOnMap(POIDataManager.sharedInstance.findDisplayableGroups(), withMonitoredOverlays: true)
        displayRouteInterfaces(false)
 
        mapAnimation = MapCameraAnimations(mapView: theMapView, mapCameraDelegate: self)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserPreferences.sharedInstance.isFirstStartup {
            UserPreferences.sharedInstance.isFirstStartup = false
            performSegue(withIdentifier: storyboard.showHelperId, sender: nil)
        }
    }
    
    func importFile(gpx:URL) {
        if UserPreferences.sharedInstance.isAnyPoiUnlimited {
            performSegue(withIdentifier: storyboard.showGPXImportId, sender: gpx)
        } else {
            Utilities.showAlertMessage(self, title: NSLocalizedString("GPXImport", comment: ""), message: NSLocalizedString("NeedInAppPurchaseToUseFeature", comment: ""))
        }
    }
    
    func flyoverAround(_ poi:PointOfInterest) {
        isFlyoverAroundPoi = true
        flyover = FlyoverWayPoints(mapView: theMapView, delegate: self)
        flyover!.doFlyover(poi)
    }
    
    func mapImage() -> UIImage? {
        UIGraphicsBeginImageContext(theMapView.frame.size)
        if let ctx = UIGraphicsGetCurrentContext() {
            theMapView.layer.render(in: ctx)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    func displayGroupsOnMap(_ groups:[GroupOfInterest], withMonitoredOverlays:Bool) {
        for currentGroup in groups {
            addOnMap(pois:currentGroup.pois, withMonitoredOverlays:withMonitoredOverlays)
        }
    }
    
    fileprivate func subscribeNotifications() {
        subscribeMapNotifications()
        subscribeMapNotificationsFilter()
        
        // Database notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.ManagedObjectContextObjectsDidChangeNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: DatabaseAccess.sharedInstance.managedObjectContext)
    }
    
    fileprivate func subscribeMapNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showPOIFromNotification(_:)),
                                               name: NSNotification.Name(rawValue: MapNotifications.showPOI),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showPOIsFromNotification(_:)),
                                               name: NSNotification.Name(rawValue: MapNotifications.showPOIs),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showWikipediaFromNotification(_:)),
                                               name: NSNotification.Name(rawValue: MapNotifications.showWikipedia),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showGroupFromNotification(_:)),
                                               name: NSNotification.Name(rawValue: MapNotifications.showGroup),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showMapLocationFromNotification(_:)),
                                               name: NSNotification.Name(rawValue: MapNotifications.showMapLocation),
                                               object: nil)
    }
    
    fileprivate func subscribeMapNotificationsFilter() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.addCategoryToFilter(_:)),
                                               name: NSNotification.Name(rawValue: MapFilterViewController.Notifications.addCategoryToFilter),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.removeCategoryFromFilter(_:)),
                                               name: NSNotification.Name(rawValue: MapFilterViewController.Notifications.removeCategoryFromFilter),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.showPOIsNotInRoute(_:)),
                                               name: NSNotification.Name(rawValue: MapFilterViewController.Notifications.showPOIsNotInRoute),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.hidePOIsNotInRoute(_:)),
                                               name: NSNotification.Name(rawValue: MapFilterViewController.Notifications.hidePOIsNotInRoute),
                                               object: nil)
   }

    // Called only once?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Restore latest position only when the app is started
        if isFirstInitialization {
            isFirstInitialization = false
            theMapView.setRegion(UserPreferences.sharedInstance.mapLatestMapRegion, animated: false)
        }
        
        // If an Action triggered during the startup has not yet been executed, we execute it!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.performActionOnStartup()
        
     }
    
    func prepareViewFromNavigation() {
        stopDim(0.0)
        flyover?.urgentStop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }

    @IBAction func leftMenuButtonPushed(_ sender: UIBarButtonItem) {
        container!.toggleLeftPanel()
    }
    
    @IBAction func userLocationButton(_ sender: UIButton) {
        showUserLocation()
    }
    
    func showUserLocation() {
        if let userCoordinate = LocationManager.sharedInstance.locationManager?.location?.coordinate {
            mapAnimation.fromCurrentMapLocationTo(userCoordinate)
        }
    }
    
    @IBAction func exitRouteMode(_ sender: AnyObject) {
        disableRouteMode()
    }
    
     //MARK: Route navigation buttons
    // Go to the next WayPoint
    @IBAction func showNextWayPoint(_ sender: UIBarButtonItem) {
        routeManager?.moveTo(direction:.forward)
    }
    
    // Go the the previous WayPoint
    @IBAction func showPreviousWayPoint(_ sender: UIBarButtonItem) {
        routeManager?.moveTo(direction:.backward)
    }

    @IBAction func showAllRoute(_ sender: UIBarButtonItem) {
        routeManager?.moveTo(direction:.all)
    }

    @IBAction func routeActionButtonPushed(_ sender: UIBarButtonItem) {
        if let routeDatasource = routeManager?.routeDatasource {
            let mailActivity = RouteMailActivityItemSource(datasource:routeDatasource)
            var activityItems:[UIActivityItemSource] = [mailActivity]

            if UserPreferences.sharedInstance.isAnyPoiUnlimited {
                activityItems.append(GPXActivityItemSource(route: [routeDatasource.theRoute]))
            }
            
            if let image = mapImage() {
                let imageActivity = ImageAcvitityItemSource(image: image)
                activityItems.append(imageActivity)
            }
            
            let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                        UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                        UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                        UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo, UIActivityType.message]
            
            present(activityController, animated: true, completion: nil)
        }
    }
    

    //MARK: Actions from Information view
    
    @IBAction func editButtonPushed(_ sender: UIButton) {
        performSegue(withIdentifier: storyboard.routeDetailsEditorId, sender: nil)
    }

    @IBAction func flyoverButtonPushed(_ sender: UIButton) {

        if let routeDatasource = routeManager?.routeDatasource, routeDatasource.wayPoints.count > 0 {
            self.flyover = FlyoverWayPoints(mapView: self.theMapView, delegate: self)
            self.flyover!.doFlyover(routeDatasource, routeFromCurrentLocation:self.routeManager?.fromCurrentLocation?.route)
        }
    }
    
    @IBAction func navigationButtonPushed(_ sender: UIButton) {
        if let routeDatasource = routeManager?.routeDatasource {
            self.performNavigation(routeDatasource:routeDatasource)
        }
    }
  
    
    fileprivate func performNavigation(routeDatasource:RouteDataSource) {
        if routeDatasource.isFullRouteMode {
            var items = [MKMapItem]()
            
            let mapAppOptions:[String : AnyObject] = [
                MKLaunchOptionsMapTypeKey : MKMapType.standard.rawValue as AnyObject,
                MKLaunchOptionsShowsTrafficKey: true as AnyObject]
            
            items = routeDatasource.theRoute.mapItems
            MKMapItem.openMaps(with: items, launchOptions: mapAppOptions)
        } else {
            performSegue(withIdentifier: PoiCalloutDelegateImpl.storyboard.startTableRouteId, sender: nil)
        }
    }


    @IBAction func selectedTransportTypeHasChanged(_ sender: UISegmentedControl) {
        routeManager?.set(transportType:MapUtils.segmentIndexToTransportType(sender))
    }

    fileprivate func addMonitoredRegionOverlays() {
        // Add MonitoredRegion overlays for annotations displayed on the Map
        for currentAnnotation in theMapView.annotations {
            if let currentPOI =  currentAnnotation as? PointOfInterest {
                // Add overlays if the poi is monitored
                if let monitoredRegionOverlay = currentPOI.getMonitordRegionOverlay() {
                    theMapView.add(monitoredRegionOverlay)
                }
            }
        }
    }
    
    
    
    // MARK: Route API
    func moveWayPoint(sourceIndex: Int, destinationIndex:Int) {
        routeManager?.moveWayPoint(sourceIndex: sourceIndex, destinationIndex:destinationIndex)
    }
    
    func deleteWayPointAt(_ index:Int) {
        routeManager?.deleteWayPointAt(index:index)
    }
    
    func removeSelectedPoiFromRoute() {
        if theMapView.selectedAnnotations.count > 0,
            let selectedPoi = theMapView.selectedAnnotations[0] as? PointOfInterest {            
            routeManager?.remove(poi:selectedPoi)
        }
    }
    
    func addSelectedPoiInRoute() {
        if theMapView.selectedAnnotations.count > 0 {
            let poi = theMapView.selectedAnnotations[0] as! PointOfInterest
            
            if isRouteMode {
                routeManager?.add(poi:poi)
            } else {
                RouteEditorController().createRouteWith(self, delegate: self, routeName: poi.poiDisplayName!, pois: [poi])
            }
        }
    }
    
    func showRouteFromCurrentLocation(_ targetPOI:PointOfInterest) {
        routeManager?.addRouteFromCurrentLocation(targetPOI:targetPOI, transportType:routeDatasource!.fromWayPoint!.transportType!)
    }
    
    func removeRouteFromCurrentLocation() {
        routeManager?.removeRouteFromCurrentLocation()
    }
    
    fileprivate func refreshPoiAnnotation(_ poi:PointOfInterest, withType:MapUtils.PinAnnotationType) {
        if let annotationView = theMapView.view(for: poi) as? WayPointPinAnnotationView {
            MapUtils.refreshPin(annotationView, poi: poi, delegate: poiCalloutDelegate, type: withType)
        }
    }
    
    // MARK: Route toolbar
    fileprivate func displayRouteInterfaces(_ show:Bool) {
        routeStackView.isHidden = !show
        exitRouteModeButton.isHidden = !show


        for currentItem in navigationItem.rightBarButtonItems! {
            if show {
                currentItem.tintColor = view.tintColor
                currentItem.isEnabled = true
            } else {
                currentItem.tintColor = UIColor.clear
                currentItem.isEnabled = false
            }
        }
    }
    
    

    //MARK: Search Controller
    @IBAction func startSearchController(_ sender: UIBarButtonItem) {
        showSearchController()
    }
    
    func showSearchController() {
        let mySearchController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchControllerId") as! SearchController
        
        theSearchController = UISearchController(searchResultsController: mySearchController)
        
        mySearchController.theSearchController = theSearchController
        mySearchController.delegate = self
        
        //FIXEDME: 😡😡⚡️⚡️
       // mySearchController.displayRoutes = true
        
        // Configure the UISearchController
        theSearchController!.searchResultsUpdater = self
        theSearchController!.delegate = self
        
        theSearchController!.searchBar.sizeToFit()
        theSearchController!.searchBar.delegate = self
        theSearchController!.searchBar.placeholder = NSLocalizedString("MapSearchPlaceHolder", comment: "")
        theSearchController!.hidesNavigationBarDuringPresentation = true
        theSearchController!.dimsBackgroundDuringPresentation = true
        
        present(theSearchController!, animated: true, completion: nil)

    }

    
    func showLocationOnMap(_ coordinate:CLLocationCoordinate2D) {
        mapAnimation.fromCurrentMapLocationTo(coordinate)
    }
    
    func addPoiOnOnMapLocation(_ coordinate:CLLocationCoordinate2D) -> PointOfInterest {
        return POIDataManager.sharedInstance.addPOI(coordinates: coordinate)
    }
    
    func selectPoiOnMap(_ poi:PointOfInterest) {
        theMapView.selectAnnotation(poi, animated: true)
    }
    
    //MARK: SearchControllerDelegate
    func showPOIOnMap(_ poi : PointOfInterest, isSelected:Bool = true) {
        // Mandatory to hide the UISearchController
        theSearchController?.isActive = false
        
        forceToShowPOIOnMap(poi: poi)
        
        if isSelected {
            if theMapView.selectedAnnotations.count > 0 {
                theMapView.deselectAnnotation(theMapView.selectedAnnotations[0], animated: false)
            }
            theMapView.selectAnnotation(poi, animated: false)
        }
        
        mapAnimation.fromCurrentMapLocationTo(poi.coordinate)
    }

    
    /// Force to how a POI on the Map. If filter configuration hide the given POI
    /// the filter is automatically reconfigured to display the POI
    ///
    /// - Parameter poi: POI that must be displayed on the Map
    fileprivate func forceToShowPOIOnMap(poi : PointOfInterest) {
        // Make sure the category of the POI is not filtered
        removeFromFilter(category:poi.category)
        
        // Make sure the POI is not hidden due to HidePOIsNotInRoute
        if let datasource = routeDatasource, filterPOIsNotInRoute, !datasource.contains(poi:poi) {
            showPOIsNotInRoute()
        }
        
        // Make sure the Group is Displayed before to show the POI
        // and then add it to the Map and set the Camera
        if !poi.parentGroup!.isGroupDisplayed {
            poi.parentGroup!.isGroupDisplayed = true
            POIDataManager.sharedInstance.updatePOIGroup(poi.parentGroup!)
            POIDataManager.sharedInstance.commitDatabase()
        }

    }

    
    /// Force a list a POIs to be displayed on the Map. The Filter will be changed if needed and 
    /// the map region will be changed to display the list of POIs
    ///
    /// - Parameter pois: List of POIs that must be displayed on the Map
    fileprivate func forceToShowPOIsOnMap(_ pois : [PointOfInterest]) {
        // Mandatory to hide the UISearchController
        theSearchController?.isActive = false

        for currentPoi in pois {
            forceToShowPOIOnMap(poi:currentPoi)
        }
        
        let region = MapUtils.boundingBoxForAnnotations(pois)
        theMapView.setRegion(region, animated: true)
    }


    func showGroupOnMap(_ group : GroupOfInterest) {
        theSearchController?.isActive = false
        
        if !group.isGroupDisplayed {
            group.isGroupDisplayed = true
            POIDataManager.sharedInstance.updatePOIGroup(group)
            POIDataManager.sharedInstance.commitDatabase()
        }
        
        let region = MapUtils.boundingBoxForAnnotations(group.pois)
        theMapView.setRegion(region, animated: true)
    }
    
    func showMapLocation(_ mapItem: MKMapItem) {
        theSearchController?.isActive = false
        mapAnimation.fromCurrentMapLocationTo(mapItem.placemark.coordinate)
    }
    
    func showWikipediaOnMap(_ wikipedia : Wikipedia) {
        if let wikipediaPoi = POIDataManager.sharedInstance.findPOIWith(wikipedia) {
            showPOIOnMap(wikipediaPoi)
        }
    }
    
    fileprivate func showAlertMessage(_ title:String, message:String) {
        // Show that nothing was found for this search
        let alertView = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let actionClose = UIAlertAction(title: "Close", style: .cancel) { alertAction in
            alertView.dismiss(animated: true, completion: nil)
        }
        
        alertView.addAction(actionClose)
        present(alertView, animated: true, completion: nil)
    }
    
    // MARK: unwind Segue
    @IBAction func backToMapView(_ segue:UIStoryboardSegue) {
    }
    
    @IBAction func showRoute(_ segue:UIStoryboardSegue) {
        let routeViewController = segue.source as! RoutesViewController
        if let routeToDisplay = routeViewController.getSelectedRoute() {
            enableRouteModeWith(routeToDisplay)
            container!.goToMap()
        }
    }
    
    func enableRouteModeWith(_ routeToDisplay:Route) {
        // Remove the old displayed route (if any)
        disableRouteMode()
        // Reset this flag before we display a route
        filterPOIsNotInRoute = false
        
        routeManager = RouteManager(route:routeToDisplay, routeDisplay: self)
        routeManager?.loadAndDisplayOnMap()
        
    }
    

    func disableRouteMode() {
        if isRouteMode {
            let poisToBeUpdated = routeDatasource?.pois
            routeManager?.cleanup()
            routeManager = nil
            
            // We must remove/add POIs that were used in the Route because their Pin color can be different
            // for source and target and the callout of these POIs are also different
            // Warning: it's important to do it after setting the routeManager to nil otherwise the POIs will be 
            // added as if the route was still enabled
            if let poisToUpdate = poisToBeUpdated {
                removeFromMap(pois: poisToUpdate)
                addOnMap(pois: poisToUpdate)
            }
            showPOIsNotInRoute() // If the filter was on we need to deactivate it
        }
    }
    
    func cleanup(withRoute:Route) {
        if isRouteMode && routeDatasource?.theRoute === withRoute {
            disableRouteMode()
        }
    }
    
    @IBAction func backToMapWayPoint(_ unwindSegue:UIStoryboardSegue) {
        if let routeDetailsVC = unwindSegue.source as? RouteDetailsViewController {
            // Get the index of the selected WayPoint and go to the next one to display the appropriate
            // Route section because in RouteDataSource the WayPointIndex = 0 is to display the full route
            // and when > 1 it displays only the route section of the WayPoint.
            routeManager?.showWayPointIndex(routeDetailsVC.getSelectedWayPointIndex())
        }
    }
    
    @IBAction func backToMapWayPointHome(_ unwindSegue:UIStoryboardSegue) {
        routeManager?.moveTo(direction:.all)
    }

    //MARK: handling notifications
    func showPOIFromNotification(_ notification : Notification) {
        let poi = (notification as NSNotification).userInfo![MapNotifications.showPOI_Parameter_POI] as? PointOfInterest
        if let thePoi = poi {
            showPOIOnMap(thePoi)
        }
     }

    func showPOIsFromNotification(_ notification : Notification) {
        let pois = (notification as NSNotification).userInfo![MapNotifications.showPOIs_Parameter_POIs] as? [PointOfInterest]
        if let thePois = pois {
            forceToShowPOIsOnMap(thePois)
        }
    }


    func showWikipediaFromNotification(_ notification : Notification) {
        // Position the MapView and the camera to display the area around the Wikipedia
        if let wikipedia = (notification as NSNotification).userInfo![MapNotifications.showPOI_Parameter_Wikipedia] as? Wikipedia {
            showWikipediaOnMap(wikipedia)
        }
    }

    func showGroupFromNotification(_ notification : Notification) {
        if let group = notification.object as? GroupOfInterest {
            showGroupOnMap(group)
        }
    }
    
    func showMapLocationFromNotification(_ notification : Notification) {
        if let mapItem = notification.object as? MKMapItem {
            showMapLocation(mapItem)
        }
    }
    
     func addCategoryToFilter(_ notification:Notification) {
        if let userInfo = notification.userInfo, let category = userInfo[MapFilterViewController.Notifications.categoryParameter.categoryName] as? CategoryUtils.Category {
            addToFilter(category: category)
        }
    }
    
     func removeCategoryFromFilter(_ notification:Notification) {
        if let userInfo = notification.userInfo, let category = userInfo[MapFilterViewController.Notifications.categoryParameter.categoryName] as? CategoryUtils.Category {
            removeFromFilter(category:category)
        }
    }
    
    func showPOIsNotInRoute(_ notification:Notification) {
        showPOIsNotInRoute()
    }
    
    
    func hidePOIsNotInRoute(_ notification:Notification) {
        hidePOIsNotInRoute()
    }
    
    /// Add POIs (and their overlays) on the Map. Only POIs that are not filtered
    /// are added in the Map, else they are put in the Filtered list
    ///
    /// - Parameters:
    ///   - pois: An array of POI
    ///   - withMonitoredOverlays: True to display the overlay (default value)
    func addOnMap(pois:[PointOfInterest], withMonitoredOverlays:Bool = true) {
        var newPoisToBeAddedOnMap = [PointOfInterest]()
        var newOverlaysToBeAddedOnMap = [MKOverlay]()
        for currentPoi in pois {
            if isFiltered(poi: currentPoi) {
                filteredPOIs.insert(currentPoi)
            } else {
                newPoisToBeAddedOnMap.append(currentPoi)
                if let monitoredRegionOverlay = currentPoi.getMonitordRegionOverlay() {
                    newOverlaysToBeAddedOnMap.append(monitoredRegionOverlay)
                }
            }
        }
        
        theMapView.addAnnotations(newPoisToBeAddedOnMap)
        
        if withMonitoredOverlays {
            theMapView.addOverlays(newOverlaysToBeAddedOnMap)
        }
    }
    
    func removeAllPOIsFromMap() {
        var poiToRemove = [PointOfInterest]()
        // We can have other MKAnnotation like MKUserLocation
        for currentAnnotation in theMapView.annotations {
            if let poi = currentAnnotation as? PointOfInterest {
                poiToRemove.append(poi)
            }
        }
        removeFromMap(pois: poiToRemove)
    }
    
    func removeFromMap(pois:[PointOfInterest]) {
        filteredPOIs = filteredPOIs.subtracting(pois)
        theMapView.removeAnnotations(pois)
        
        var overlaysToBeRemovedFromMap = [MKOverlay]()

        for currentPoi in pois {
            if let monitoredRegionOverlay = currentPoi.getMonitordRegionOverlay() {
                overlaysToBeRemovedFromMap.append(monitoredRegionOverlay)
            }
        }
        
        theMapView.removeOverlays(overlaysToBeRemovedFromMap)
    }

    //MARK: Database Notifications
    func ManagedObjectContextObjectsDidChangeNotification(_ notification : Notification) {
        let notifContent = PoiNotificationUserInfo(userInfo: (notification as NSNotification).userInfo as [NSObject : AnyObject]?)
        
        processNotificationsForGroupOfInterest(notificationsContent:notifContent)
        processNotificationsForPointOfInterest(notificationsContent:notifContent)
        processNotificationsForRouteAndWayPoint(notificationsContent:notifContent)
    }
    
    // Process notifications on GroupOfInterest
    // - Only update notification is process on Group and only for properties: colors & isDisplayed
    fileprivate func processNotificationsForGroupOfInterest(notificationsContent:PoiNotificationUserInfo) {
        for updatedGroup in notificationsContent.updatedGroupOfInterest {
            let changedValues = updatedGroup.changedValues()
            if changedValues[GroupOfInterest.properties.groupColor] != nil {
                removeFromMap(pois:updatedGroup.pois)
                if updatedGroup.isGroupDisplayed {
                    addOnMap(pois:updatedGroup.pois)
                }
            } else if changedValues[GroupOfInterest.properties.isGroupDisplayed] != nil {
                removeFromMap(pois:updatedGroup.pois)
                if updatedGroup.isGroupDisplayed {
                    displayGroupsOnMap([updatedGroup], withMonitoredOverlays: true)
                }
                
                updateFilterStatus()
            }
        }
    }
    
    // Process notification on POI
    // - Add POI notification to put a new POI on the Map
    // - Deleted POI, to remove the POI and its overlay from the Map
    // - Updated POI, to update its callout and position, color and overlay
    fileprivate func processNotificationsForPointOfInterest(notificationsContent:PoiNotificationUserInfo) {
        // Make sure added POIs will be displayed on the MAP even if its categor was filetered
        for addedPoi in notificationsContent.insertedPois {
            removeFromFilter(category:addedPoi.category)
        }
        addOnMap(pois: notificationsContent.insertedPois)
        removeFromMap(pois: notificationsContent.deletedPois)
        
        for updatedPoi in notificationsContent.updatedPois {
            let changedValues = updatedPoi.changedValues()
            
            if changedValues[PointOfInterest.properties.poiRegionNotifyEnter] != nil ||
                changedValues[PointOfInterest.properties.poiRegionNotifyExit] != nil  ||
                changedValues[PointOfInterest.properties.poiCategory] != nil ||
                changedValues[PointOfInterest.properties.poiAddress] != nil {
                if let annotationView = theMapView.view(for: updatedPoi) {
                    MapUtils.refreshDetailCalloutAccessoryView(updatedPoi, annotationView: annotationView, delegate: poiCalloutDelegate)
                }
            }
            
            // When the category has been changed maybe the POI must be added or removed from the 
            // Map. To make sure to phave the good status we remove it and add it again
            if  changedValues[PointOfInterest.properties.poiCategory] != nil {
                removeFromMap(pois: [updatedPoi])
                addOnMap(pois: [updatedPoi])
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
                
                removeFromMap(pois:[updatedPoi])
                addOnMap(pois: [updatedPoi])
                
                if isSelected {
                    theMapView.selectAnnotation(updatedPoi, animated: false)
                }
                
            }
            updateMonitoredRegionOverlayForPoi(updatedPoi, changedValues: changedValues as [String : AnyObject])
        }
    }
    
    // Process notifications for Route and WayPoints
    // - When a new route is created (its number of WayPoints == 1), the POI is refreshed to be displayed with the right color
    // - route deletion are ignored because everything is done when the user click Remove in the RoutesViewController
    // - when the current route is updated, the routeMode is updated with the latest data
    // - A reload of the route is triggered when the route mode is on
    fileprivate func processNotificationsForRouteAndWayPoint(notificationsContent:PoiNotificationUserInfo) {
        
        // If nothing has been changed, we just return
        if notificationsContent.insertedWayPoints.isEmpty &&
            notificationsContent.updatedWayPoints.isEmpty &&
            notificationsContent.deletedWayPoints.isEmpty &&
            notificationsContent.insertedRoutes.isEmpty &&
            notificationsContent.updatedRoutes.isEmpty &&
            notificationsContent.deletedRoutes.isEmpty {
            return
        }
        
        // When the first WayPoint in added, we display a message
        if !notificationsContent.insertedWayPoints.isEmpty,
            let theRouteDatasource = routeDatasource, theRouteDatasource.wayPoints.count == 1 {
            PKHUD.sharedHUD.dimsBackground = false
            HUD.flash(.label(NSLocalizedString("MapNotificationRouteStartAdded", comment: "")), delay:1.0, completion: nil)
            if let startPoi = theRouteDatasource.theRoute.startWayPoint?.wayPointPoi {
                // The starting point must be refreshed in the map with the right color
                refreshPoiAnnotation(startPoi, withType: .routeStart)
            }
        } else {
            if isRouteMode && !notificationsContent.updatedRoutes.isEmpty {
                for currentRoute in notificationsContent.updatedRoutes {
                    if currentRoute === routeDatasource!.theRoute {
                        routeManager?.refreshRouteInfosOverview()
                        break
                    }
                }
            }
            
            if isRouteMode {
                routeManager?.reloadDirections()
            }
        }
    }
    
 
    // Check if the MonitoredRegion overlay for a POI must be removed, added or updated when its properties have
    // changed (notifyEnter, notifyExit and radius)
    // Warning: changedValues contains the list of changed properties with their NEW VALUE
    // Warning: The updatedPoi contains also the new properties values
    // Warning: To get the old values we must get the changedValuesForCurrentEvent()
    fileprivate func updateMonitoredRegionOverlayForPoi(_ updatedPoi:PointOfInterest, changedValues:[String:AnyObject]) {
        if !updatedPoi.isMonitored {
            // when the POI is not monitored we just need to remove the overlay from the map (if displayed)
            if let monitoredRegionOverlay = updatedPoi.getMonitordRegionOverlay() {
                
                // SEB: Warning, it seems there's a bug in Apple library in HybridFlyover, overlays are not 
                // always correctly removed from the map. Workaround is to change to Normal Map mode and then 
                // go back to Flyover!!!!
                theMapView.remove(monitoredRegionOverlay)
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
                        theMapView.remove(monitoredRegionOverlay)
                    }

                    updatedPoi.resetMonitoredRegionOverlay()
                    if let monitoredRegionOverlay = updatedPoi.getMonitordRegionOverlay() {
                        theMapView.add(monitoredRegionOverlay)
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
                            theMapView.add(monitoredRegionOverlay)
                        }
                    }
                }
            }
        }
    }
    
    
    static func isAddPoiAuthorized() -> Bool {
        return UserPreferences.sharedInstance.isAnyPoiUnlimited || POIDataManager.sharedInstance.getAllPOI().count < MapViewController.MAX_POI_WITHOUT_LICENSE
    }

    // MARK: Map Gestures 
    @IBAction func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        switch (sender.state) {
        case .ended:
            if MapViewController.isAddPoiAuthorized() {
                
                if #available(iOS 10.0, *) {
                    let feedbackGenerator = UIImpactFeedbackGenerator.init(style: .medium)
                    feedbackGenerator.impactOccurred()
                } else {
                    // Fallback on earlier versions
                }
                
                // Add the new POI in database
                // The Poi will be added on the Map thanks to DB notifications
                let coordinates = theMapView.convert(sender.location(in: theMapView), toCoordinateFrom: theMapView)
                let addedPoi = POIDataManager.sharedInstance.addPOI(coordinates: coordinates)
                
                if isRouteMode {
                    // Add the POI as a new WayPoint in the route
                    routeManager?.add(poi:addedPoi)
                }
            } else {
                Utilities.showAlertMaxPOI(viewController:self)
            }
        default:
            break
        }
    }


    //MARK: Segue
    fileprivate struct storyboard {
        static let showPOIDetails = "ShowPOIDetailsId"
        static let showMapOptions = "ShowMapOptions"
        static let showGroupContent = "showGroupContent"
        static let editGroup = "editPOIGroup"
        static let routeDetailsEditorId = "routeDetailsEditorId"
        static let openPhonesId = "openPhones"
        static let openEmailsId = "openEmails"
        static let openMapFilterId = "openMapFilterId"
        static let showGPXImportId = "showGPXImportId"
        static let showHelperId = "showHelperId"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == storyboard.showPOIDetails {
            let poiController = segue.destination as! POIDetailsViewController
            poiController.poi = sender as? PointOfInterest
        } else if segue.identifier == storyboard.showMapOptions {
            let viewController = segue.destination as! OptionsViewController
            viewController.theMapView = theMapView
        } else if segue.identifier == storyboard.showGroupContent {
            let viewController = segue.destination as! POIsViewController
            let group = sender as! GroupOfInterest
            viewController.showGroup(group)
        } else if segue.identifier == storyboard.editGroup {
            startDim()
            let viewController = segue.destination as! GroupConfiguratorViewController
            viewController.group = sender as? GroupOfInterest
            viewController.delegate = self
        } else if segue.identifier == PoiCalloutDelegateImpl.storyboard.startTableRouteId {
            let viewController = segue.destination as! RouteProviderTableViewController
            startRouteProviderTable(viewController, sender: sender as AnyObject?)
        } else if segue.identifier == storyboard.routeDetailsEditorId {
            let viewController = segue.destination as! RouteDetailsViewController
            viewController.wayPointsDelegate = self
        } else if segue.identifier == storyboard.openPhonesId {
            startDim()
            let viewController = segue.destination as! ContactsViewController
            viewController.delegate = self
            viewController.poi = sender as? PointOfInterest
            viewController.mode = .phone
        } else if segue.identifier == storyboard.openEmailsId {
            startDim()
           let viewController = segue.destination as! ContactsViewController
            viewController.delegate = self
            viewController.poi = sender as? PointOfInterest
            viewController.mode = .email 
        } else if segue.identifier == storyboard.openMapFilterId {
            let viewController = segue.destination as! MapFilterViewController
            let mapFilter = MapCategoryFilter(initialFilter:categoryFilter)
            viewController.filter = mapFilter
            if isRouteMode {
                viewController.isRouteModeOn = true
                viewController.showPOIsNotInRoute = !filterPOIsNotInRoute
            }
        } else if segue.identifier == storyboard.showGPXImportId {
            let navController = segue.destination as! UINavigationController
            let viewController = navController.topViewController as! GPXImportViewController
            //let viewController = segue.destination as! GPXImportViewController
            viewController.gpxURL = sender as! URL
        } else if segue.identifier == storyboard.showHelperId {
            let helpViewController = segue.destination as! HelperViewController
            helpViewController.isStartedFomMap = true
        }
       
    }
    
    fileprivate func startRouteProviderTable(_ viewController: RouteProviderTableViewController, sender: AnyObject?) {
        startDim()
        if isRouteMode {
            if let targetPoi = sender as? PointOfInterest {
                viewController.initializeWith(theMapView.userLocation.coordinate, targetPoi: targetPoi, delegate:self)
            } else {
                if let _ = routeManager?.fromCurrentLocation {
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

extension MapViewController: MapCameraAnimationsDelegate, RouteProviderDelegate, DismissModalViewController, ContactsDelegate {
    //MARK: RouteProviderDelegate
    func endRouteProvider() {
        stopDim()
    }
    
    //MARK: ContactsDelegate
    func endContacts() {
        stopDim()
    }
    
    //MARK: DismissModalViewController
    func didDismiss() {
        stopDim()
    }
    
    //MARK: MapCameraAnimationsDelegate
    func mapAnimationCompleted() {
        // Nothing to do
    }
}

// MARK: RouteEditorDelegate
extension MapViewController: RouteEditorDelegate {
    //MARK: RouteEditorDelegate
    func routeCreated(_ route:Route) {
        enableRouteModeWith(route)
    }
    
    func routeEditorCancelled() {
        // Nothing to do
    }
    
    func routeUpdated(_ route:Route) {
        // Nothing to do
    }
}

// MARK: RouteDisplayInfos
extension MapViewController : RouteDisplayInfos {
    
    func hideRouteDisplay() {
        displayRouteInterfaces(false)
    }
    
    func refresh(datasource:RouteDataSource) {
        displayRouteInterfaces(true)
       if datasource.wayPoints.isEmpty {
            showEmptyRoute()
        } else if datasource.isFullRouteMode {
            showRouteSummary(datasource:datasource)
        } else {
            showRouteWayPoints(datasource:datasource)
        }
    }
    

    fileprivate func showEmptyRoute() {
        fromToLabel.text = NSLocalizedString("RouteDisplayInfosRouteIsEmpty", comment: "")
        fromToLabel.textColor = UIColor.red
        fromToLabel.sizeToFit()
        distanceLabel.text = " "
        thirdActionBarStackView.isHidden = true
        navigationButton.isHidden = true
    }
    
    // Show the summary infos when we are displaying the full route
    fileprivate func showRouteSummary(datasource:RouteDataSource) {
        fromToLabel.text = datasource.routeName
        fromToLabel.textColor = UIColor.red
        distanceLabel.text = datasource.routeDistanceAndTime
        fromToLabel.sizeToFit()
        thirdActionBarStackView.isHidden = true
        navigationButton.isHidden = true
   }
    
    // Show the infos about the route between the 2 wayPoints or between the current location and the To
    fileprivate func showRouteWayPoints(datasource:RouteDataSource) {
        let distanceFormatter = LengthFormatter()
        distanceFormatter.unitStyle = .short
        
        navigationButton.isHidden = false
        if let fromCurrentLocation = routeManager?.fromCurrentLocation {
            // Show information between the current location and the To
            fromToLabel.text = NSLocalizedString("FromCurrentLocationRouteManager", comment: "")
            fromToLabel.textColor = UIColor.red
            let expectedTravelTime = Utilities.shortStringFromTimeInterval(fromCurrentLocation.route.expectedTravelTime) as String
            distanceLabel.text = String(format: "\(NSLocalizedString("RouteDisplayInfos %@ in %@", comment:""))",
                distanceFormatter.string(fromMeters: fromCurrentLocation.route.distance),
                expectedTravelTime)

            if let toDisplayName = fromCurrentLocation.toPOI.poiDisplayName {
                fromToLabel.text = fromToLabel.text! + " ➔ \(toDisplayName)"
            }
            selectedTransportType.selectedSegmentIndex = MapUtils.transportTypeToSegmentIndex(fromCurrentLocation.transportType)
        } else {
            // Show information between the 2 wayPoints
            fromToLabel.textColor = UIColor.black
            fromToLabel.text = datasource.routeName
            distanceLabel.text = datasource.routeDistanceAndTime
            selectedTransportType.selectedSegmentIndex = MapUtils.transportTypeToSegmentIndex(datasource.fromWayPoint!.transportType!)
        }

        
        thirdActionBarStackView.isHidden = false
    }

}

extension MapViewController : UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    //MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        let mySearchController = searchController.searchResultsController as! SearchController
        mySearchController.currentRegion = theMapView.region
        mySearchController.updateSearch()
    }
    
    //MARK: UISearchControllerDelegate
    func didDismissSearchController(_ searchController: UISearchController) {
        // Navigate to the appropriate ViewController if an action has been triggered by the user
        // in the SearchController
        if let viewController = searchController.searchResultsController as? SearchController {
            switch viewController.selectedAction {
            case .none: break
            case .editGroup:
                // Put in a dispatch async to make sure the dimmer will be displayed appropriately (on top
                // of all, including the SearchController)
                // I cannot explain why I need to do that, if not done the SearchBar is not covered by the Dimmer
                // because the Dimmer is behind the Search Bar...
                DispatchQueue.main.async {
                    if let group = viewController.selectedGroup {
                        self.performSegue(withIdentifier: storyboard.editGroup, sender: group)
                    }
                }
            case .showGroupContent:
                if let group = viewController.selectedGroup {
                    performSegue(withIdentifier: storyboard.showGroupContent, sender: group)
                }
            case .showRoute:
                if let route = viewController.selectedRoute {
                    enableRouteModeWith(route)
                }
            case .editPoi:
                if let poi = viewController.selectedPoi {
                    performSegue(withIdentifier: storyboard.showPOIDetails, sender: poi)
                }
            }
        }
        theSearchController = nil
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        // Reset the selectedGroup to make sure we are not triggering an action not requested by the user
        // when the searchController is dismissed
        // Warning: Keep in mind the SearchController is never removed from memory, it's still here even
        // when it's not displayed
        if let viewController = searchController.searchResultsController as? SearchController {
            viewController.selectedGroup = nil
        }
    }
    
    //MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Perform Geocoding to find places using the text provided by the user
    }
}

extension MapViewController : FlyoverWayPointsDelegate {
    
    //MARK: FlyoverWayPointsDelegate
    func flyoverWillStartAnimation() {
        isFlyoverRunning = true
        
        // Disable to idleTimer during the flyover to avoid the screen dims
        UIApplication.shared.isIdleTimerDisabled = true
        
        //Hide route itf if it's displayed
        displayRouteInterfaces(false)
        
        // When the Flyover is around a POI we keep in mind the Map region
        // to restore it at the end of Flyover
        if isFlyoverAroundPoi {
            mapRegionBeforeFlyover = theMapView.region
        }
        
        userLocationButton.isHidden = true
        mapFilterButton.isHidden = true
        
        hideStatusBar = true
        setNeedsStatusBarAppearanceUpdate() // Request to hide the status bar (managed by the ContainerVC)
        view.layoutIfNeeded() // Make sure the status bar will be remove smoothly
        
        navigationController?.isNavigationBarHidden = true
    }
    
    func flyoverWillEndAnimation(_ urgentStop:Bool) {
        isFlyoverRunning = false
        
        // Restore the idleTimer
        UIApplication.shared.isIdleTimerDisabled = false
        hideStatusBar = false
        navigationController?.isNavigationBarHidden = false
        
        if isRouteMode {
            displayRouteInterfaces(true)
        }
        userLocationButton.isHidden = false
        mapFilterButton.isHidden = false
        
        if !urgentStop {
            if isFlyoverAroundPoi {
                theMapView.region = mapRegionBeforeFlyover!
            } else if let routeMgr = routeManager {
                routeMgr.displayRouteMapRegion()
            }
        }

        
        setNeedsStatusBarAppearanceUpdate() // Request to show the status bar
        view.layoutIfNeeded() // Make sure the status bar will be displayed smoothly
    }
    
    func flyoverDidEnd(_ flyoverUpdatedPois:[PointOfInterest], urgentStop:Bool) {
        if isRouteMode  {
            if routeDatasource!.isFullRouteMode {
                routeManager?.removeAllRouteOverlays()
                routeManager?.addRouteOverlays()
            }
            routeManager?.refreshRouteInfosOverview()
       }
        
        for currentPoi in flyoverUpdatedPois {
            if isRouteMode {
                routeManager?.refresh(poi:currentPoi)
            } else if let annotationView = theMapView.view(for: currentPoi) as? WayPointPinAnnotationView {
                annotationView.configureWith(currentPoi, delegate: poiCalloutDelegate, type: .normal)
            }
        }
        
        flyover = nil
        isFlyoverAroundPoi = false
    }
    
    func flyoverGetPoiCalloutDelegate() -> PoiCalloutDelegateImpl {
        return poiCalloutDelegate
    }
    
    func flyoverAddPoisOnMap(pois:[PointOfInterest]) {
        addOnMap(pois: pois, withMonitoredOverlays: true)
    }
    func flyoverRemovePoisFromMap(pois:[PointOfInterest]) {
        removeFromMap(pois: pois)
    }

}

// MARK: Map Filtering
extension MapViewController {
    
    func isFiltered(poi:PointOfInterest) -> Bool {
        if poi.parentGroup!.isGroupDisplayed && !categoryFilter.contains(poi.category) {
            if isRouteMode && filterPOIsNotInRoute {
                if let datasource = routeDatasource, datasource.contains(poi:poi) {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func showPOIsNotInRoute() {
        if filterPOIsNotInRoute {
            filterPOIsNotInRoute = false
            addOnMap(pois: Array(filteredPOIs), withMonitoredOverlays: true)
            updateFilterStatus()
        }
    }
    
    fileprivate func hidePOIsNotInRoute() {
        filterPOIsNotInRoute = true
        
        // Remove all annotations which are not used in the route
        var annotationsToRemove = [PointOfInterest]()
        var overlaysToRemove = [MKOverlay]()
        for currentAnnotation in theMapView.annotations {
            if let currentPoi = currentAnnotation as? PointOfInterest {
                if !routeDatasource!.contains(poi:currentPoi) {
                    annotationsToRemove.append(currentPoi)
                    if let overlay = (currentAnnotation as! PointOfInterest).getMonitordRegionOverlay() {
                        overlaysToRemove.append(overlay)
                    }
                }
            }
        }
        filteredPOIs = filteredPOIs.union(annotationsToRemove)
        theMapView.removeAnnotations(annotationsToRemove)
        theMapView.removeOverlays(overlaysToRemove)
        
        updateFilterStatus()
        
    }
    
    fileprivate func updateFilterStatus() {
        if categoryFilter.isEmpty && !filterPOIsNotInRoute {
            if POIDataManager.sharedInstance.hasFilteredGroups() {
                mapFilterButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("MapFilterIsOn", comment: ""),
                                                                      attributes: [NSForegroundColorAttributeName : UIColor.white,
                                                                                   NSBackgroundColorAttributeName : UIColor.red]),
                                                   for: .normal)
            } else {
                mapFilterButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("MapFilterIsOff", comment: ""),
                                                                      attributes: [NSForegroundColorAttributeName : UIColor.white,
                                                                                   NSBackgroundColorAttributeName : UIColor.blue]),
                                                   for: .normal)
                
            }
        } else {
            mapFilterButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("MapFilterIsOn", comment: ""),
                                                                  attributes: [NSForegroundColorAttributeName : UIColor.white,
                                                                               NSBackgroundColorAttributeName : UIColor.red]),
                                               for: .normal)
        }
    }
    
    
    fileprivate func addToFilter(category:CategoryUtils.Category) {
        categoryFilter.insert(category)
        var poiToRemove = [PointOfInterest]()
        var overlaysToRemove = [MKOverlay]()
        for currentAnnotation in theMapView.annotations  {
            if let currentPoi = currentAnnotation as? PointOfInterest {
                if currentPoi.category == category {
                    poiToRemove.append(currentPoi)
                    if let monitoredRegionOverlay = currentPoi.getMonitordRegionOverlay() {
                        overlaysToRemove.append(monitoredRegionOverlay)
                    }
                }
            }
        }
        
        theMapView.removeAnnotations(poiToRemove)
        theMapView.removeOverlays(overlaysToRemove)
        filteredPOIs = filteredPOIs.union(poiToRemove)
        
        updateFilterStatus()
    }
    
    fileprivate func removeFromFilter(category:CategoryUtils.Category) {
        categoryFilter.remove(category)
        
        // look into the filtered POIs if some matches the old category
        var poiToAdd = [PointOfInterest]()
        for currentPoi in filteredPOIs {
            if !isFiltered(poi: currentPoi) {
                poiToAdd.append(currentPoi)
                if let monitoredRegionOverlay = currentPoi.getMonitordRegionOverlay() {
                    theMapView.add(monitoredRegionOverlay)
                }
            }
        }
        
        theMapView.addAnnotations(poiToAdd)
        filteredPOIs = filteredPOIs.subtracting(poiToAdd)
        
        updateFilterStatus()
    }
}

extension MapViewController : MKMapViewDelegate {
    //MARK: MKMapViewDelegate
    
    fileprivate struct mapViewAnnotationId {
        static let POIAnnotationId = "POIAnnotationId"
    }
    
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        NSLog("\(#function): didFailToLocateUserWithError")
        
        if(CLLocationManager.locationServicesEnabled() == false ||
            !(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways)){
            //location services are disabled or
            //user has not authorized permissions to use their location.
            
            // SEB: TBC request again authorization
            
            mapView.userTrackingMode = MKUserTrackingMode.none
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let thePoi = annotation as! PointOfInterest
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: WayPointPinAnnotationView.AnnotationId.wayPointAnnotationId) as? WayPointPinAnnotationView ?? MapUtils.createPin(thePoi)
        
        MapUtils.refreshPin(annotationView,
                            poi: thePoi,
                            delegate: poiCalloutDelegate,
                            type: routeManager?.getPinType(poi:thePoi) ?? MapUtils.PinAnnotationType.normal,
                            isFlyover:isFlyoverRunning)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            return MapUtils.customizePolyLine(overlay as! MKPolyline)
        } else if overlay is MKCircle {
            return MapUtils.getRendererForMonitoringRegion(overlay)
        } else {
            return MKOverlayRenderer()
        }
    }
    
    
    // Save automatically the latest Map position in userPrefs
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if !isFlyoverRunning {
            UserPreferences.sharedInstance.mapLatestMapRegion = mapView.region
        }
    }
}


