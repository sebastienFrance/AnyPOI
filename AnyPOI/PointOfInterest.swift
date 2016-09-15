//
//  PointOfInterest.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 06/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import AddressBookUI
import Contacts
import CoreSpotlight
import MobileCoreServices // for kUTTypeData

class PointOfInterest : NSManagedObject, MKAnnotation, WikipediaRequestDelegate {
    
    struct Notifications {
        static let WikipediaReady = "WikipediaReady"
    }
    
    struct constants {
        static let emptyTitle  = "No Name"
    }

    struct properties {
        static let poiRegionRadius = "poiRegionRadius"
        static let poiRegionNotifyEnter = "poiRegionNotifyEnter"
        static let poiRegionNotifyExit = "poiRegionNotifyExit"
        static let parentGroup = "parentGroup"
        static let poiPlacemark = "poiPlacemark"
        static let poiCategory = "poiCategory"
        static let poiLatitude = "poiLatitude"
        static let poiLongitude = "poiLongitude"
        static let poiContactIdentifier = "poiContactIdentifier"
    }
    
    // Title is always equals to poiDisplayName stored in Database
    dynamic var title: String? {
        get {
            return poiDisplayName
        }
        set {
            poiDisplayName = newValue
        }
    }
    
    dynamic var subtitle: String? {
        get {
            if let placemark = placemarks {
                return Utilities.getAddressFrom(placemark)
            } else {
                return nil
            }
        }
    }

    var coordinate:CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(poiLatitude, poiLongitude)
        }
        set {
            poiLatitude = newValue.latitude
            poiLongitude = newValue.longitude
        }
    }
    
    // PlaceMark can be empty
    var placemarks: CLPlacemark? {
        get {
            if let thePlacemark = poiPlacemark as? NSData {
                return NSKeyedUnarchiver.unarchiveObjectWithData(thePlacemark) as? CLPlacemark
            } else {
                return nil
            }
        }
        set {
            if let newPlacemark = newValue {
                poiPlacemark = NSKeyedArchiver.archivedDataWithRootObject(newPlacemark)
                if self.poiDisplayName == constants.emptyTitle,
                    let placemarkName = MapUtils.getNameFromPlacemark(newPlacemark) {
                    self.title = placemarkName
                }
            }
        }
    }
    
    var camera: MKMapCamera! {
        get {
            if let theCamera = poiCamera as? NSData {
                return NSKeyedUnarchiver.unarchiveObjectWithData(theCamera) as? MKMapCamera
            } else {
                return MKMapCamera(lookingAtCenterCoordinate: coordinate, fromDistance: 300, pitch:0, heading: 0)
            }
        }
        set {
            if let newCamera = newValue {
                poiCamera = NSKeyedArchiver.archivedDataWithRootObject(newCamera)
            }
        }
    }
    
    var categoryIcon:UIImage? {
        get {
            if CategoryUtils.EmptyCategoryIndex != Int(poiCategory) {
                return CategoryUtils.getIconCategoryForIndex(Int(poiCategory))
            } else {
                return nil
            }
        }
    }
    
    // Wikipedia articles are not stored in database
    // only the reference article is stored in database when the POI has
    // been created from a Wikipedia article
    
    var wikipedias = [Wikipedia]()
    var isWikipediaLoading:Bool {
        get {
            if let request = wikiRequest {
                return request.isWikipediaLoading
            } else {
                return false
            }
        }
    }
    
    private var wikiRequest:WikipediaRequest?
    
    // Currently not used...
    var imageMap: UIImage?
    var isImageLoading = false
    
    var address:String {
        get {
            if let placemark = placemarks {
                return Utilities.getAddressFrom(placemark)
            } else {
                return "No address"
            }
        }
    }

    var isMonitored:Bool {
        get {
            return poiRegionNotifyEnter || poiRegionNotifyExit
        }
    }

    private var monitoredRegion:MKOverlay?
    
    func toJSON() -> [String:AnyObject] {
        let poiToJSON :[String:AnyObject] = [
            "poiCategory" : Int(poiCategory),
            "poiCity" : poiCity ?? "",
            "poiDescription": poiDescription ?? "",
            "poiDisplayName" : poiDisplayName ?? ""]
        
        let headerPoiJSON:[String:AnyObject] = [
        "POI": poiToJSON]
       
        return headerPoiJSON
    }
    
    func toHTML() -> String {
        var htmlDescription = "<p><b>\(poiDisplayName!)</b></p>"
        if let description = poiDescription {
            htmlDescription = "\(htmlDescription)<p>\(description)</p>"
        }
        
        htmlDescription = "\(htmlDescription)<p>\(address)"
        
        var phoneNumber:String?
        var url:String?
        if poiIsContact {
            // Get infos from the Contact
            if let theContact = ContactsUtilities.getContactForDetailedDescription(poiContactIdentifier!) {
                
                let contactPhoneNumber = ContactsUtilities.extractPhoneNumber(theContact)
                if let number = contactPhoneNumber {
                    phoneNumber = number.stringValue
                }
                
                url = ContactsUtilities.extractURL(theContact)
            }
        } else {
            phoneNumber = poiPhoneNumber
            url = poiURL
        }
        
        if let thePhoneNumber = phoneNumber {
            htmlDescription = "\(htmlDescription)<br>\(thePhoneNumber)"
        }
        
        if let theURL = url {
            htmlDescription = "\(htmlDescription)<br><a href=\"\(theURL)\">Web site</a>"
        }
        htmlDescription = "\(htmlDescription)</p><br>"
        
        htmlDescription = "\(htmlDescription)Show on map with:"
        htmlDescription = "\(htmlDescription)<ul>"
        htmlDescription = "\(htmlDescription)<li><a href=\"http://maps.apple.com/?q=\(poiDisplayName!)&ll=\(poiLatitude),\(poiLongitude)\">Apple Maps</a></li>"
        htmlDescription = "\(htmlDescription)<li><a href=\"https://maps.google.com/?q=\(poiLatitude),\(poiLongitude)\">Google Maps</a></li>"
        htmlDescription = "\(htmlDescription)<li>\(poiLatitude)°, \(poiLongitude)°</li>"
        htmlDescription = "\(htmlDescription)</ul>"
      
        
        return htmlDescription
    }
    
    func toMessage() -> String {
        var stringDescription = "\(poiDisplayName!)\n"
        if let description = poiDescription {
            stringDescription = "\(stringDescription)\(description)\n"
        }
        stringDescription = "\(stringDescription)\(address)\n"
        
        
        var phoneNumber:String?
        var url:String?
        if poiIsContact {
            // Get infos from the Contact
            if let theContact = ContactsUtilities.getContactForDetailedDescription(poiContactIdentifier!) {
                
                let contactPhoneNumber = ContactsUtilities.extractPhoneNumber(theContact)
                if let number = contactPhoneNumber {
                    phoneNumber = number.stringValue
                }
                
                url = ContactsUtilities.extractURL(theContact)
            }
        } else {
            phoneNumber = poiPhoneNumber
            url = poiURL
        }

        if let thePhoneNumber = phoneNumber {
            stringDescription = "\(stringDescription)\(thePhoneNumber)\n"
        }
        
        if let theURL = url {
            stringDescription = "\(stringDescription)\(theURL)\n"
        }

        
        return stringDescription
    }
    
    // This method is called at every commit (update, delete or create)
    override func didSave() {
        if deleted {
            // Poi is deleted, we must unregister it from Spotlight
            removeFromSpotLight()
        } else {
            // Poi is updated or created, we need to update its properties in Spotlight
            updateInSpotLight()
        }
    }
    
    var attributeSetForSearch : CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
        // Add metadata that supplies details about the item.
        attributeSet.title = poiDisplayName!
        
        // The contentDescription is set with the Poi description if configured
        // otherwise it's configured with the Poi Address
        if let thePoiDescription = poiDescription where thePoiDescription.characters.count > 0 {
            attributeSet.contentDescription = thePoiDescription
        } else {
            // Put the address
            attributeSet.contentDescription = address
        }
        
        // Add keywords that will contains:
        // - All words from the display name
        // - The Category if not empty
        let subStringFromDisplayName = poiDisplayName!.characters.split(" ")
        var keywords = [String]()
        for currentString in subStringFromDisplayName {
            if currentString.count > 1 {
                keywords.append(String(currentString))
            }
        }
        
        let categoryIndex = Int(poiCategory)
        if categoryIndex != CategoryUtils.EmptyCategoryIndex {
            keywords.append(CategoryUtils.getLabelCategoryForIndex(Int(categoryIndex)))
        }
        
        attributeSet.keywords = keywords
        
        
        // It Seems SupportsNavigation & supportsPhoneCall are mutually exclusives!
        
        // Set the Location
        attributeSet.supportsNavigation = 1
        attributeSet.latitude = coordinate.latitude
        attributeSet.longitude = coordinate.longitude
        
        // Set the PhoneNumber & Image
        // If the Poi is the contact we extract the PhoneNumber from the Contact sheet
        // else we get the one that is registered in the database (if any)
        //
        // Same is done for the Image
        if poiIsContact,
            let contactId = poiContactIdentifier {
            if let contact = ContactsUtilities.getContactForDetailedDescription(contactId) {
                
                if let phoneNumber = ContactsUtilities.extractPhoneNumber(contact) {
                    attributeSet.supportsPhoneCall = 1
                    attributeSet.phoneNumbers = [phoneNumber.stringValue]
                }
                attributeSet.thumbnailData = ContactsUtilities.getThumbailImageDataFor(contactId)
            }
        } else {
            if let phoneNumber = poiPhoneNumber {
                attributeSet.supportsPhoneCall = 1
                attributeSet.phoneNumbers = [phoneNumber]
            }
            if let icon = categoryIcon {
                attributeSet.thumbnailData = UIImagePNGRepresentation(icon)
            }
        }
        return attributeSet
    }
    
    // Add or Update the Poi in Spotlight
    private func updateInSpotLight() {
    
        // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
        let item = CSSearchableItem(uniqueIdentifier: objectID.URIRepresentation().absoluteString, domainIdentifier: "POI", attributeSet: attributeSetForSearch)
        
        // Add the item to the on-device index.
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { error in
            if let theError = error {
                print("\(#function) error with \(theError.localizedDescription)")
            }
        }
    }
    
    func removeFromSpotLight() {
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([objectID.URIRepresentation().absoluteString]) { error in
            if let theError = error {
                print("\(#function) Error Poi \(self.poiDisplayName!) cannot be removed from Spotlightn, error: \(theError.localizedDescription)")
            }
        }
    }
    
    

    func getMonitordRegionOverlay() -> MKOverlay? {
        if monitoredRegion != nil {
            return monitoredRegion
        } else if isMonitored {
            monitoredRegion = MKCircle(centerCoordinate: coordinate, radius: poiRegionRadius)
            return monitoredRegion
        } else {
            return nil
        }
    }

    func resetMonitoredRegionOverlay() -> MKOverlay? {
        monitoredRegion = nil
        return getMonitordRegionOverlay()
    }
    
    // MARK: Initializers
    
    // Used when a new POI is directly added on the Map using Long touch
    func initializeWith(coordinates: CLLocationCoordinate2D, camera theCamera:MKMapCamera) {
        isPrivate = false
        
        poiIsContact = false
        poiCategory = Int16(CategoryUtils.EmptyCategoryIndex)
       
        coordinate = coordinates
        title = constants.emptyTitle
        camera = theCamera
        
        getPlacemark()
        
        poiWikipediaPageId = -1
        findWikipedia()
        
        parentGroup = POIDataManager.sharedInstance.getDefaultGroup()
        initRegionMonitoring()
    }
    
    func initializeWith(contact:CNContact, placemark:CLPlacemark) {
        initDefaultCamera(placemark.location!.coordinate)
        
        poiIsContact = true
        poiContactIdentifier = contact.identifier
        poiContactLatestAddress = CNPostalAddressFormatter().stringFromPostalAddress(contact.postalAddresses[0].value as! CNPostalAddress)
        
        isPrivate = false
        poiCategory  = Int16(CategoryUtils.EmptyCategoryIndex)
        
        coordinate = placemark.location!.coordinate
        
        title = CNContactFormatter.stringFromContact(contact, style: .FullName)
        
        initializePlacemarks(placemark)
        poiWikipediaPageId = -1
       // findWikipedia()
        
        parentGroup = POIDataManager.sharedInstance.getDefaultContactGroup()
        initRegionMonitoring()
        
    }
    
    func updateWith(contact:CNContact) {
        title = CNContactFormatter.stringFromContact(contact, style: .FullName)
    }
    
    func updateWith(contact:CNContact, placemark:CLPlacemark) {
        
        // Must be stopped before to change the coordinate
        var needToRestartMonitoring = false
        if isMonitored {
            LocationManager.sharedInstance.stopMonitoringRegion(self)
            needToRestartMonitoring = true
        }
        
        coordinate = placemark.location!.coordinate
        poiContactLatestAddress = CNPostalAddressFormatter().stringFromPostalAddress(contact.postalAddresses[0].value as! CNPostalAddress)
        title = CNContactFormatter.stringFromContact(contact, style: .FullName)
        initializePlacemarks(placemark)
        
        if needToRestartMonitoring {
            LocationManager.sharedInstance.startMonitoringRegion(self)
        }
        // SEB: A FAIRE, peut-etre qu'il faut reinitialiser completement le region monitoring pour ce POI et la camera
        // si les coordonnées geo ne sont pas identique (ca peut arriver si quelqu'un change d'adresse!)
    }
    
    // Used when a new POI is created from a Wikipedia article
    func initializeWith(wikipedia: Wikipedia, group:GroupOfInterest) {

        initDefaultCamera(wikipedia.coordinates)
        
        isPrivate = false
        poiIsContact = false
        poiCategory = Int16(CategoryUtils.WikipediaCategoryIndex)
        
        coordinate = wikipedia.coordinates
        
        title = wikipedia.title
        poiWikipediaPageId = Int64(wikipedia.pageId)
        
        poiURL = WikipediaUtils.getMobileURLForPageId(wikipedia.pageId)
        
        getPlacemark()
        findWikipedia()
        
        parentGroup = group
        initRegionMonitoring()
    }
    
    // Used when a new POI is created from a local search
    func initializeWith(mapItem:MKMapItem, categoryIndex:Int) {
        initDefaultCamera(mapItem.placemark.coordinate)

        isPrivate = false
        poiIsContact = false
        poiCategory = Int16(categoryIndex)
        
        coordinate = mapItem.placemark.coordinate
        title = mapItem.name
        
        if let phone = mapItem.phoneNumber {
            poiPhoneNumber = phone
        }
        
        if let url = mapItem.url {
            poiURL = url.absoluteString
        }
        
        
        initializePlacemarks(mapItem.placemark)
        
        poiWikipediaPageId = -1
        findWikipedia()
        
        parentGroup = POIDataManager.sharedInstance.getDefaultGroup()
        initRegionMonitoring()
    }
    
    private func initDefaultCamera(coordinate:CLLocationCoordinate2D) {
        camera = MKMapCamera(lookingAtCenterCoordinate: coordinate, fromDistance: 150, pitch: 45, heading: 0)
    }
    
    private func initRegionMonitoring() {
        // Disable Region on startup
        poiRegionNotifyExit = false
        poiRegionNotifyEnter = false
        poiRegionRadius = 50
        poiRegionId = "\(poiDisplayName!)_\(NSDate().timeIntervalSinceReferenceDate)"
        
    }
    
    private func initializePlacemarks(placemark:CLPlacemark) {
        placemarks = placemark
        if let locality = self.placemarks?.locality {
            self.poiCity = locality
        } else {
            self.poiCity = "Unknown city"
        }
        
        if let ISOCountryCode = self.placemarks?.ISOcountryCode {
            self.poiISOCountryCode = ISOCountryCode
        } else {
            self.poiISOCountryCode = "Unknown country"
        }
    }
    
    // MARK: Utilities
    func refreshAll() {
        getPlacemark()
        findWikipedia()
    }
    
    func refreshIfNeeded() {
        if !isWikipediaLoading && wikipedias.count == 0  {
            findWikipedia()
        }
    }

    // Perform reverse geocoding to find address of the coordinates
    private func getPlacemark() {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            if let errorReverseGeocode = error {
                print("Reverse geocoder failed with error" + errorReverseGeocode.localizedDescription)
                return
            }
            
            if let placemarksResults = placemarks {
                if placemarksResults.count > 0 {
                    self.initializePlacemarks(placemarksResults[0])
                    POIDataManager.sharedInstance.updatePOI(self)
                    POIDataManager.sharedInstance.commitDatabase()
                } else {
                    print("Empty data received")
                }
                
            } else {
                print("No received data")
            }
         })
    }
    
    // Search Wikipedia Summary articles around POI location
    private func findWikipedia() {
        wikiRequest = WikipediaRequest(delegate: self)
        wikiRequest?.searchAround(coordinate)
    }
    
    func wikipediaLoadingDidFinished(wikipedias:[Wikipedia]) {
        self.wikipedias = wikipedias
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.WikipediaReady, object: self)
    }
    func wikipediaLoadingDidFailed() {
        self.wikipedias = [Wikipedia]()
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.WikipediaReady, object: self)
    }

    
    func startOrStopMonitoring(sender: UIButton) {
        if isMonitored {
            poiRegionNotifyEnter = false
            poiRegionNotifyExit = false
            
            POIDataManager.sharedInstance.updatePOI(self)
            POIDataManager.sharedInstance.commitDatabase()
            
            LocationManager.sharedInstance.stopMonitoringRegion(self)
        } else {
            poiRegionNotifyEnter = true
            poiRegionNotifyExit = true
            poiRegionRadius = 100.0
            
            POIDataManager.sharedInstance.updatePOI(self)
            POIDataManager.sharedInstance.commitDatabase()
            
            LocationManager.sharedInstance.startMonitoringRegion(self)
        }
    }
 }