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

@objc(PointOfInterest)
class PointOfInterest : NSManagedObject, MKAnnotation, WikipediaRequestDelegate {
    
    struct Notifications {
        static let WikipediaReady = "WikipediaReady"
    }
    
    struct constants {
        static let emptyTitle  = "No Name"
        static let invalidWikipediaPage = Int64(-1)
    }

    struct properties {
        static let poiRegionRadius = "poiRegionRadius"
        static let poiRegionNotifyEnter = "poiRegionNotifyEnter"
        static let poiRegionNotifyExit = "poiRegionNotifyExit"
        static let parentGroup = "parentGroup"
        static let poiCategory = "poiCategory"
        static let poiGroupCategory = "poiGroupCategory"
        static let poiLatitude = "poiLatitude"
        static let poiLongitude = "poiLongitude"
        static let poiAddress = "poiAddress"
        static let poiContactIdentifier = "poiContactIdentifier"
    }
    
    var imageForType:UIImage {
        get {
            if poiIsContact {
                return #imageLiteral(resourceName: "Contact-70")
            } else if poiWikipediaPageId != constants.invalidWikipediaPage {
                return #imageLiteral(resourceName: "WikipediaBig-70")
            } else {
                return #imageLiteral(resourceName: "Pin-70")
            }
        }
    }
    
    var smallImageForType:UIImage {
        get {
            if poiIsContact {
                return #imageLiteral(resourceName: "Contacts-30")
            } else if poiWikipediaPageId != constants.invalidWikipediaPage {
                return #imageLiteral(resourceName: "Wikipedia-30")
            } else {
                return #imageLiteral(resourceName: "Pin-30")
            }
        }
    }

    var props:[String:String] {
        var theProps = [String:String]()
        
        theProps[CommonProps.POI.title] = title
        theProps[CommonProps.POI.address] = address
        theProps[CommonProps.POI.categoryId] = String(category.categoryId)
        theProps[CommonProps.POI.groupCategory] = String(category.groupCategory)
        theProps[CommonProps.POI.color] = ColorsUtils.getColor(color: parentGroup!.color)
        theProps[CommonProps.POI.latitude] = String(coordinate.latitude)
        theProps[CommonProps.POI.longitude] = String(coordinate.longitude)
        
        var phoneList = ""
        for phoneNumber in phoneNumbers {
            if phoneList.count > 0 {
                phoneList += ","
            }
            phoneList += phoneNumber.stringValue
        }
        
        theProps[CommonProps.POI.phones] = phoneList
        
        return theProps
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
            return address
        }
    }
    
    var phoneNumbers:[CNPhoneNumber] {
        if poiIsContact, let contactId = poiContactIdentifier, let contact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            return contact.phoneNumbers.map() {
                return $0.value
            }
        } else {
            if let phone = poiPhoneNumber {
                return [CNPhoneNumber(stringValue:phone)]
            } else {
                return []
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
    
    var category:CategoryUtils.Category! {
        get {
            return CategoryUtils.getCategory(groupCategory: poiGroupCategory, categoryId: poiCategory)
        }
        set {
            poiGroupCategory = newValue.groupCategory
            poiCategory = newValue.categoryId
        }
    }
    
   var categoryIcon:UIImage? {
        get {
            return category.icon
        }
    }
    
    var glyphImage:UIImage {
        return category.glyph
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
    
    fileprivate var wikiRequest:WikipediaRequest?
    
    var address:String {
        get {
            if let theAddress = poiAddress {
                return theAddress
            } else {
                return NSLocalizedString("NoAddressUtilities", comment: "")
            }
        }
    }
    
    var hasPlacemark:Bool {
        get {
            if let city = poiCity, !city.isEmpty {
                return true
            } else {
                return false
            }
        }
    }

    var isMonitored:Bool {
        get {
            return poiRegionNotifyEnter || poiRegionNotifyExit
        }
    }

    fileprivate var monitoredRegion:MKOverlay?
    
    
    func distanceFrom(location:CLLocation) -> CLLocationDistance {
        let poiLocation = CLLocation(latitude: poiLatitude , longitude: poiLongitude)
        return location.distance(from: poiLocation)
    }

    func distanceFrom(location:CLLocationCoordinate2D) -> CLLocationDistance {
        let poiLocation = CLLocation(latitude: poiLatitude , longitude: poiLongitude)
        let sourceLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return sourceLocation.distance(from: poiLocation)
    }

    func getMonitordRegionOverlay() -> MKOverlay? {
        if monitoredRegion == nil {
            updateMonitoredRegion()
        }
        return monitoredRegion
    }

    func resetMonitoredRegionOverlay() {
        monitoredRegion = nil
        updateMonitoredRegion()
    }
    
    fileprivate func updateMonitoredRegion() {
        if isMonitored {
            monitoredRegion = MKCircle(center: coordinate, radius: poiRegionRadius)
        }
    }
    
    // MARK: Initializers
    
    // Used when a new POI is directly added on the Map using Long touch
    func initializeWith(coordinates: CLLocationCoordinate2D) {
        
        poiIsContact = false
        
        category = CategoryUtils.defaultGroupCategory
        
        coordinate = coordinates
        title = constants.emptyTitle
        
        GeoCodeMgr.sharedInstance.getPlacemark(poi:self)
        
        poiWikipediaPageId = constants.invalidWikipediaPage
        findWikipedia()
        
        parentGroup = UserPreferences.sharedInstance.lastUsedGroupOfInterest
        //parentGroup = POIDataManager.sharedInstance.getDefaultGroup()
        initRegionMonitoring()
    }
    
    // Used when a new POI is directly added on the Map from the Import
    // Warning: Placemark is not initialized in this call and Wikipedia are not searched
    func importWith(coordinates: CLLocationCoordinate2D) {
        
        poiIsContact = false
        
        category = CategoryUtils.defaultGroupCategory
        
        coordinate = coordinates
        title = constants.emptyTitle
        
        poiWikipediaPageId = constants.invalidWikipediaPage
        
        parentGroup = POIDataManager.sharedInstance.getDefaultGroup()
        initRegionMonitoring()
    }

    
    func initializeWith(_ contact:CNContact, placemark:CLPlacemark) {
        
        poiIsContact = true
        poiContactIdentifier = contact.identifier
        
        category = CategoryUtils.contactCategory
        
        coordinate = placemark.location!.coordinate
        
        if let contactTitle = CNContactFormatter.string(from: contact, style: .fullName) {
            title = contactTitle
        } else {
            title = constants.emptyTitle
        }
        
        initializeWith(placemark:placemark)
        poiAddress = CNPostalAddressFormatter().string(from: contact.postalAddresses[0].value )
        poiWikipediaPageId = constants.invalidWikipediaPage
        
        parentGroup = POIDataManager.sharedInstance.getDefaultContactGroup()
        initRegionMonitoring()
        
    }
    
    
    // Used when a new POI is created from a Wikipedia article
    func initializeWith(_ wikipedia: Wikipedia, group:GroupOfInterest) {

        poiIsContact = false
        category = CategoryUtils.wikipediaCategory
        
        coordinate = wikipedia.coordinates
        
        title = wikipedia.title
        poiWikipediaPageId = Int64(wikipedia.pageId)
        
        poiURL = WikipediaUtils.getMobileURLForPageId(wikipedia.pageId)
        
        GeoCodeMgr.sharedInstance.getPlacemark(poi:self)
        findWikipedia()
        
        parentGroup = group
        
        initRegionMonitoring()
    }
    
    // Used when a new POI is created from a local search
    func initializeWith(_ mapItem:MKMapItem, category:CategoryUtils.Category?) {
        poiIsContact = false
        
        self.category = category ?? CategoryUtils.defaultGroupCategory
        
        coordinate = mapItem.placemark.coordinate
        title = mapItem.name
        
        if let phone = mapItem.phoneNumber {
            poiPhoneNumber = phone
        }
        
        if let url = mapItem.url {
            poiURL = url.absoluteString
        }
        
        
        initializeWith(placemark:mapItem.placemark)
        
        poiWikipediaPageId = constants.invalidWikipediaPage
        findWikipedia()
        
        
        parentGroup = UserPreferences.sharedInstance.lastUsedGroupOfInterest
        //parentGroup =   POIDataManager.sharedInstance.getDefaultGroup()
        initRegionMonitoring()
    }
    
    func updateWith(_ contact:CNContact) {
        title = CNContactFormatter.string(from: contact, style: .fullName)
    }
    
    func updateWith(_ contact:CNContact, placemark:CLPlacemark) {
        
        // Must be stopped before to change the coordinate
        var needToRestartMonitoring = false
        if isMonitored {
            _ = LocationManager.sharedInstance.stopMonitoringRegion(poi: self)
            needToRestartMonitoring = true
        }
        
        coordinate = placemark.location!.coordinate
        initializeWith(placemark:placemark)
        poiAddress = CNPostalAddressFormatter().string(from: contact.postalAddresses[0].value )
        title = CNContactFormatter.string(from: contact, style: .fullName)
        
        if needToRestartMonitoring {
            _ = LocationManager.sharedInstance.startMonitoringRegion(poi: self)
        }
        // SEB: A FAIRE, peut-etre qu'il faut reinitialiser completement le region monitoring pour ce POI et la camera
        // si les coordonnées geo ne sont pas identique (ca peut arriver si quelqu'un change d'adresse!)
    }

    
    fileprivate func initRegionMonitoring() {
        // Disable Region on startup
        poiRegionNotifyExit = false
        poiRegionNotifyEnter = false
        poiRegionRadius = 50
        poiRegionId = "\(poiDisplayName!)_\(Date().timeIntervalSinceReferenceDate)"
        
    }
    
    func initializeWith(placemark:CLPlacemark) {
        
        if poiDisplayName == constants.emptyTitle,
            let placemarkName = MapUtils.getNameFromPlacemark(placemark) {
            title = placemarkName
        }

        poiAddress = Utilities.getAddressFrom(placemark)
        
        if let locality = placemark.locality {
            poiCity = locality
        } else {
            poiCity = "Unknown city"
        }
        
        if let ISOCountryCode = placemark.isoCountryCode {
            poiISOCountryCode = ISOCountryCode
        } else {
            poiISOCountryCode = "Unknown country"
        }
    }
    
    // MARK: Utilities
    func refreshAll() {
        GeoCodeMgr.sharedInstance.getPlacemark(poi:self)
        findWikipedia()
    }
    
    func refreshIfNeeded() {
        if !isWikipediaLoading && wikipedias.count == 0  {
            findWikipedia()
        }
    }

    // Search Wikipedia Summary articles around POI location
    fileprivate func findWikipedia() {
        wikiRequest = WikipediaRequest(delegate: self)
        wikiRequest?.searchAround(coordinate)
    }
    
    func wikipediaLoadingDidFinished(_ wikipedias:[Wikipedia]) {
        self.wikipedias = wikipedias
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.WikipediaReady), object: self)
    }
    func wikipediaLoadingDidFailed() {
        self.wikipedias = [Wikipedia]()
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.WikipediaReady), object: self)
    }

    
    func startMonitoring(radius:Double = 100.0, notifyEnterRegion:Bool = true, notifyExitRegion:Bool = true) -> LocationManager.MonitoringStatus {
        if !isMonitored && LocationManager.sharedInstance.isMaxMonitoredRegionReached() {
            return LocationManager.MonitoringStatus.maxMonitoredRegionAlreadyReached
        }

        let isAlreadyMonitored = isMonitored
        
        poiRegionNotifyEnter = notifyEnterRegion
        poiRegionNotifyExit = notifyExitRegion
        poiRegionRadius = radius
        
        POIDataManager.sharedInstance.updatePOI(self)
        POIDataManager.sharedInstance.commitDatabase()
        
        if isAlreadyMonitored {
            return LocationManager.sharedInstance.updateMonitoringRegion(self)
        } else {
            return LocationManager.sharedInstance.startMonitoringRegion(poi: self)
        }
    }
    
    func stopMonitoring() {
        if isMonitored {
            
            poiRegionNotifyEnter = false
            poiRegionNotifyExit = false
            
            POIDataManager.sharedInstance.updatePOI(self)
            POIDataManager.sharedInstance.commitDatabase()
            
            _ = LocationManager.sharedInstance.stopMonitoringRegion(poi: self)
        }
    }
    
    
 }

//MARK: HTML and Message export
extension PointOfInterest {
    fileprivate static let tableHeaderForPois =
        "<table style=\"width:100%\">" +
            "<tr>" +
            "<th>\(NSLocalizedString("NamePOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("DescriptionPOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("CategoryPOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("AddressPOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("PhonePOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("URLPOIMail", comment: ""))</th>" +
            "<th>\(NSLocalizedString("MapPOIMail", comment: ""))</th>" +
    "</tr>"

    
    func toHTML() -> String {
        var htmlDescription = "<p><b>\(poiDisplayName!)</b></p>"
        if let description = poiDescription {
            htmlDescription += "<p>\(description)</p>"
        }
        
        htmlDescription += "<p>\(address)"
        
        var phoneNumber:String?
        var url:String?
        if poiIsContact, let contactId = poiContactIdentifier, let theContact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            // Get infos from the Contact
            phoneNumber = ContactsUtilities.extractPhoneNumber(theContact)?.stringValue
            url = ContactsUtilities.extractURL(theContact)
        } else {
            phoneNumber = poiPhoneNumber
            url = poiURL
        }

        if let thePhoneNumber = phoneNumber {
            htmlDescription += "<br>\(thePhoneNumber)"
        }
        
        if let theURL = url {
            htmlDescription += "<br><a href=\"\(theURL)\">\(NSLocalizedString("WebSiteMail", comment: ""))</a>"
        }
        htmlDescription += "</p><br>"
        
        htmlDescription += "<ul>"
        htmlDescription += "<li><a href=\"http://maps.apple.com/?q=\(poiDisplayName!)&ll=\(poiLatitude),\(poiLongitude)\">Apple Maps</a></li>"
        htmlDescription += "<li><a href=\"https://maps.google.com/?q=\(poiLatitude),\(poiLongitude)\">Google Maps</a></li>"
        htmlDescription += "<li>\(poiLatitude)°, \(poiLongitude)°</li>"
        htmlDescription += "</ul>"
        
        return htmlDescription
    }
    
    
    static func toHTML(pois:[PointOfInterest]) -> String {
        var html = PointOfInterest.tableHeaderForPois
        for currentPoi in pois {
            html += currentPoi.toHTMLForTable()
        }
        html += "</table>"
        return html
    }
    
    fileprivate func toHTMLForTable() -> String {
        var htmlDescription = "<tr>"
        htmlDescription += "<td>\(poiDisplayName!)</td>"
        htmlDescription += "<td>"
        if let description = poiDescription {
            htmlDescription += "\(description)"
        }
        htmlDescription += "</td>"

        htmlDescription += "<td>\(category.localizedString)</td>"
        htmlDescription += "<td>\(address)</td>"
        
        var phoneNumber:String?
        var url:String?
        if poiIsContact, let contactId = poiContactIdentifier, let theContact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            // Get infos from the Contact
            phoneNumber = ContactsUtilities.extractPhoneNumber(theContact)?.stringValue
            url = ContactsUtilities.extractURL(theContact)
        } else {
            phoneNumber = poiPhoneNumber
            url = poiURL
        }
        
        htmlDescription += "<td>"
        if let thePhoneNumber = phoneNumber {
            htmlDescription += "\(thePhoneNumber)"
        }
        htmlDescription += "</td>"
       
        htmlDescription += "<td>"
        if let theURL = url {
            htmlDescription += "<a href=\"\(theURL)\">\(NSLocalizedString("WebSiteMail", comment: ""))</a>"
        }
        htmlDescription += "</td>"
        htmlDescription += "<td>"
        
        htmlDescription += "<ul>"
        htmlDescription += "<li><a href=\"http://maps.apple.com/?q=\(poiDisplayName!)&ll=\(poiLatitude),\(poiLongitude)\">Apple Maps</a></li>"
        htmlDescription += "<li><a href=\"https://maps.google.com/?q=\(poiLatitude),\(poiLongitude)\">Google Maps</a></li>"
        htmlDescription += "<li>\(poiLatitude)°, \(poiLongitude)°</li>"
        htmlDescription += "</ul>"
        htmlDescription += "</td>"
        htmlDescription += "</tr>"
        
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
        if poiIsContact, let contactId = poiContactIdentifier, let theContact = ContactsUtilities.getContactForDetailedDescription(contactId) {
            // Get infos from the Contact
            let contactPhoneNumber = ContactsUtilities.extractPhoneNumber(theContact)
            if let number = contactPhoneNumber {
                phoneNumber = number.stringValue
            }

            url = ContactsUtilities.extractURL(theContact)
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

}

// Extension to support SpotLight
extension PointOfInterest {
    // This method is called at every commit (update, delete or create)
    override func didSave() {
        if isDeleted {
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
        if let thePoiDescription = poiDescription , thePoiDescription.count > 0 {
            attributeSet.contentDescription = thePoiDescription
        } else {
            // Put the address
            attributeSet.contentDescription = address
        }
        
        // Add keywords that will contains:
        // - All words from the display name
        // - The Category if not empty
        let subStringFromDisplayName = poiDisplayName!.split(separator: " ")
        var keywords = [String]()
        for currentString in subStringFromDisplayName {
            if currentString.count > 1 {
                keywords.append(String(currentString))
            }
        }
        
        if category != CategoryUtils.defaultGroupCategory {
            keywords.append(category.localizedString)
        }
        
        attributeSet.keywords = keywords
        
        
        // It Seems SupportsNavigation & supportsPhoneCall are mutually exclusives!
        
        // Set the Location
        attributeSet.supportsNavigation = 1
        attributeSet.latitude = coordinate.latitude as NSNumber?
        attributeSet.longitude = coordinate.longitude as NSNumber?
        
        // Set the PhoneNumber & Image
        // If the Poi is the contact we extract the PhoneNumber from the Contact sheet
        // else we get the one that is registered in the database (if any)
        //
        // Same is done for the Image
        if poiIsContact, let contactId = poiContactIdentifier {
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
    fileprivate func updateInSpotLight() {
        
        // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
        let item = CSSearchableItem(uniqueIdentifier: objectID.uriRepresentation().absoluteString, domainIdentifier: "POI", attributeSet: attributeSetForSearch)
        
        // Add the item to the on-device index.
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let theError = error {
                NSLog("\(#function) error with \(theError.localizedDescription)")
            }
        }
    }
    
    func removeFromSpotLight() {
        let URI = objectID.uriRepresentation().absoluteString
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [URI]) { error in
            if let theError = error {
                NSLog("\(#function) Error Poi \(self.poiDisplayName!) cannot be removed from Spotlightn, error: \(theError.localizedDescription)")
            }
        }
    }

}

extension PointOfInterest {
    
    
    func toGPXElement() -> XMLElement {
        
        let wptAttributes = [XSD.wptLatitudeAttr : "\(coordinate.latitude)",
            XSD.wptLongitudeAttr : "\(coordinate.longitude)"]
        
        var wptElement = XMLElement(elementName: XSD.GPX.Elements.WPT.name, attributes: wptAttributes)
        let nameElement = XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.name.name, withValue: poiDisplayName!)
        wptElement.addSub(element: nameElement)
        
        if let description = poiDescription {
            wptElement.addSub(element: XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.desc.name, withValue: description))
        }
        if let url = poiURL {
            wptElement.addSub(element: XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.link.name, withValue: url))
        }
        wptElement.addSub(element: XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.sym.name, withValue: category.localizedString))
        
        var extensionElement = XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.customExtension.name)
        
        extensionElement.addSub(element: addPoiToGPX())
        extensionElement.addSub(element: addRegionToGPX())
        extensionElement.addSub(element: parentGroup!.toGPXElement())
        
        wptElement.addSub(element: extensionElement)
        
        return wptElement
    }
    
    fileprivate func addPoiToGPX() -> XMLElement {
        var attributes = [ XSD.poiInternalUrlAttr : objectID.uriRepresentation().absoluteString,
                           XSD.poiGroupIdAttr : "\(poiGroupCategory)",
                           XSD.poiCategoryIdAttr : "\(poiCategory)",
                           XSD.poiIsContactAttr : "\(poiIsContact)",
                           XSD.poiWikipediaIdAttr : "\(poiWikipediaPageId)"]
        
        if let city = poiCity {
            attributes[XSD.poiCityAttr] = city
        }
        if let contactId = poiContactIdentifier {
            attributes[XSD.poiContactIdAttr] = contactId
        }
        if let contactAddress = poiAddress {
            attributes[XSD.poiAddressAttr] = contactAddress
        }
        
        if let countryCode = poiISOCountryCode {
            attributes[XSD.poiISOCountryCodeAttr] = countryCode
        }
        if let phoneNumber = poiPhoneNumber {
            attributes[XSD.poiPhoneNumberAttr] = phoneNumber
        }
        return XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.name, attributes: attributes)
    }
    
    fileprivate func addRegionToGPX() -> XMLElement {
        let attributes = [XSD.regionMonitoringNotifyEnterAttr : "\(poiRegionNotifyEnter)",
                          XSD.regionMonitoringNotifyExitAttr : "\(poiRegionNotifyExit)",
                          XSD.regionMonitoringRadiusAttr : "\(poiRegionRadius)"]
        
        return XMLElement(elementName: XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.name, attributes: attributes)
    }
}
