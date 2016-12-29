//
//  GPXParser.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 26/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class GPXParser: NSObject, XMLParserDelegate {
    
    fileprivate let theParser:XMLParser?
    
    fileprivate var importedPOICounter = 0
    fileprivate var importedRouteCounter = 0

    fileprivate var creator = "unknown"
    
     struct XSD {
        struct GPX {
            static let name = "gpx"
            struct Attributes {
                static let creator = "creator"
            }
            struct Elements {
                struct WPT {
                    static let name = "wpt"
                    struct Attributes {
                        static let latitude = "lat"
                        static let longitude = "lon"
                    }
                    struct Elements {
                        struct name {
                            static let name = "name"
                        }
                        struct desc {
                            static let name = "desc"
                        }
                        struct link {
                            static let name = "link"
                        }
                        struct sym {
                            static let name = "sym"
                        }
                        struct customExtension {
                            static let name = "extension"
                            struct Elements {
                                struct poi {
                                    static let name = "poi"
                                    struct Attributes {
                                        static let internalUrl = "internalUrl"
                                        static let groupId = "groupId"
                                        static let categoryId = "categoryId"
                                        static let isContact = "isContact"
                                        static let wikipediaId = "wikipediaId"
                                        static let city = "city"
                                        static let contactId = "contactId"
                                        static let address = "address"
                                        static let ISOCountryCode = "ISOCountryCode"
                                        static let phoneNumber = "phoneNumber"
                                    }
                                    struct Elements {
                                        struct regionMonitoring {
                                            static let name = "regionMonitoring"
                                            struct Attributes {
                                                static let notifyEnter = "notifyEnter"
                                                static let notifyExit = "notifyExit"
                                                static let regionRadius = "regionRadius"
                                            }
                                        }
                                        struct group {
                                            static let name = "group"
                                            struct Attributes {
                                                static let name = "name"
                                                static let internalUrlAttr = "internalUrlAttr"
                                                static let groupId = "groupId"
                                                static let isDisplayed = "isDisplayed"
                                                static let groupDescription = "description"
                                                static let groupColor = "groupColor"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                struct RTE {
                    static let name = "rte"
                    struct Elements {
                        struct name {
                            static let name = "name"
                        }
                        struct rtept {
                            static let name = "rtept"
                            struct Elements {
                                struct WPT {
                                    static let name = "wpt"
                                    struct Attributes {
                                        static let latitude = "lat"
                                        static let longitude = "lon"
                                    }
                                    struct Elements {
                                        struct name {
                                            static let name = "name"
                                        }
                                        struct customExtension {
                                            static let name = "extension"
                                            struct Elements {
                                                struct wayPoint {
                                                    static let name = "wayPoint"
                                                    struct Attributes {
                                                        static let internalUrl = "internalUrl"
                                                        static let poiInternalUrl = "poiInternalUrl"
                                                        static let transportType = "transportType"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        struct customExtension {
                            static let name = "extension"
                            struct Elements {
                                struct route {
                                    static let name = "route"
                                    struct Attributes {
                                        static let internalUrlAttr = "internalUrlAttr"
                                        static let latestTotalDistance = "latestTotalDistance"
                                        static let latestTotalDuration = "latestTotalDuration"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // WPT Attributes
    static let wptLatitudeAttr = GPXParser.XSD.GPX.Elements.WPT.Attributes.latitude
    static let wptLongitudeAttr = GPXParser.XSD.GPX.Elements.WPT.Attributes.longitude

    // POI Attributes
    static let poiCityAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.city
    static let poiISOCountryCodeAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.ISOCountryCode
    static let poiPhoneNumberAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.phoneNumber
    static let poiWikipediaIdAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.wikipediaId
    static let poiCategoryIdAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.categoryId
    static let poiGroupIdAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.groupId
    static let poiIsContactAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.isContact
    static let poiContactIdAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.contactId
    static let poiAddressAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.address
    static let poiInternalUrlAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.internalUrl
    
    // RegionMonitoring Attributes
    static let regionMonitoringNotifyEnterAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyEnter
    static let regionMonitoringNotifyExitAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyExit
    static let regionMonitoringRadiusAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.regionRadius

    // Group Attributes
    static let groupInternalUrlAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.internalUrlAttr
    static let groupGroupIdAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupId
    static let groupNameAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.name
    static let groupDescriptionAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupDescription
    static let groupIsDisplayedAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.isDisplayed
    static let groupColorAttr = GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupColor
    
    // Route Attributes
    static let routeTotalDistanceAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDistance
    static let routeTotalDurationAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDuration
    static let routeInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.internalUrlAttr

    // WayPoint Attributes
    static let wayPointTransportTypeAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.transportType
    static let wayPointPoiInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.poiInternalUrl
    static let wayPointInternalUrlAttr = GPXParser.XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.internalUrl

    
    var elementHierarchy = ""
    
    init(url:URL) {
        theParser = XMLParser(contentsOf: url)
        
        super.init()
        theParser?.delegate = self
    }
    
    func parse() -> Bool {
        if let parser = theParser {
            return parser.parse()
        } else {
            return false
        }
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
    }
    
    fileprivate(set) var GPXPois = [GPXPoi]()

    // Data extracted from XML to create POI
    fileprivate var wptAttributes:[String : String]? = nil
    fileprivate var poiAttributes:[String : String]? = nil
    fileprivate var groupAttributes:[String : String]? = nil
    fileprivate var regionMonitoringAttributes:[String : String]? = nil
    fileprivate var poiDescription = ""
    fileprivate var poiLink = ""
    fileprivate var poiName = ""
    fileprivate var poiSym = ""

    // Data extracted from XML to create Route
    fileprivate(set) var GPXRoutes = [GPXRoute]()

    fileprivate var routeName = ""
    fileprivate var wayPointName = ""
    fileprivate var routeAttributes:[String : String]? = nil


    fileprivate var currentRouteWayPointAttribute:GPXRouteWayPointAtttributes? = nil
    fileprivate var routeWayPoints:[GPXRouteWayPointAtttributes]? = nil


    fileprivate enum ParsingElement {
        case WPT, WPT_Name, WPT_Link, WPT_Desc, WPT_SYM, WPT_POI, WPT_GROUP, WPT_REGION_MONITORING,
        RTE, RTE_NAME, RTE_ROUTE, RTE_WPT, RTE_WPT_Name, RTE_WPT_WAYPOINT,
        OTHERS
    }
    
    fileprivate var isParsing = ParsingElement.OTHERS
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        if elementHierarchy.isEmpty {
            elementHierarchy = elementName
        } else {
            elementHierarchy += ".\(elementName)"
        }

        isParsing = ParsingElement.OTHERS

        if elementHierarchy.hasPrefix(GPXParser.POI_PREFIX) {
            switch elementName {
            case XSD.GPX.Elements.WPT.name:
                isParsing = .WPT
                wptAttributes = attributeDict
            case XSD.GPX.Elements.WPT.Elements.desc.name:
                isParsing = .WPT_Desc
            case XSD.GPX.Elements.WPT.Elements.link.name:
                isParsing = .WPT_Link
            case XSD.GPX.Elements.WPT.Elements.name.name:
                isParsing = .WPT_Name
            case XSD.GPX.Elements.WPT.Elements.sym.name:
                isParsing = .WPT_SYM
            case XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.name:
                isParsing = .WPT_POI
                poiAttributes = attributeDict
            case XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.name:
                isParsing = .WPT_GROUP
                groupAttributes = attributeDict
            case XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.name:
                isParsing = .WPT_REGION_MONITORING
                regionMonitoringAttributes = attributeDict
            case XSD.GPX.name:
                if let theCreator = attributeDict[XSD.GPX.Attributes.creator] {
                    creator = theCreator
                }
                break
            default:
                break
            }
        } else if elementHierarchy.hasPrefix(GPXParser.ROUTE_PREFIX) {
            if elementHierarchy.hasPrefix(GPXParser.ROUTE_WPT_PREFIX) {
                switch elementName {
                case XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.name:
                    isParsing = .RTE_WPT
                    currentRouteWayPointAttribute = GPXRouteWayPointAtttributes()
                    currentRouteWayPointAttribute!.routeWptAttributes = attributeDict
                case XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.name.name:
                    isParsing = .RTE_WPT_Name
                case XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.name:
                    isParsing = .RTE_WPT_WAYPOINT
                    guard (currentRouteWayPointAttribute != nil) else {
                        print("Warning, found WayPoint element without WPT!")
                        return
                    }
                    currentRouteWayPointAttribute!.wayPointAttributes = attributeDict
                    routeWayPoints?.append(currentRouteWayPointAttribute!)
                default:
                    break
                }
            } else {
                switch elementName {
                case XSD.GPX.Elements.RTE.name:
                    isParsing = .RTE
                    routeWayPoints = [GPXRouteWayPointAtttributes]()
                case XSD.GPX.Elements.RTE.Elements.name.name:
                    isParsing = .RTE_NAME
                case XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.name:
                    isParsing = .RTE_ROUTE
                    routeAttributes = attributeDict
                default:
                    break
                }
            }
        }
    }

    fileprivate static let POI_PREFIX = "gpx.wpt"
    fileprivate static let ROUTE_PREFIX = "gpx.rte"
    fileprivate static let ROUTE_WPT_PREFIX = "gpx.rte.rtept"
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        // Mandatory to check the hierarchy because WPT Element can be both outside route & inside route
        if elementName == XSD.GPX.Elements.WPT.name, elementHierarchy.hasPrefix(GPXParser.POI_PREFIX) {
            
            let newGPXPoi = GPXPoi()
            newGPXPoi.wptAttributes = wptAttributes
            newGPXPoi.poiAttributes = poiAttributes
            newGPXPoi.groupAttributes = groupAttributes
            newGPXPoi.regionMonitoringAttributes = regionMonitoringAttributes
            newGPXPoi.poiDescription = poiDescription.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
            newGPXPoi.poiLink = poiLink.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
            newGPXPoi.poiName = poiName.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
            newGPXPoi.poiSym = poiSym.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
            
            importedPOICounter += 1
            
            GPXPois.append(newGPXPoi)

            wptAttributes = nil
            poiAttributes = nil
            groupAttributes = nil
            regionMonitoringAttributes = nil
            poiDescription = ""
            poiLink = ""
            poiName = ""
            poiSym = ""
 
        } else if elementHierarchy.hasPrefix(GPXParser.ROUTE_PREFIX) {
            if elementHierarchy.hasPrefix(GPXParser.ROUTE_WPT_PREFIX) {
                if elementName == XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.name.name {
                    if currentRouteWayPointAttribute != nil {
                        currentRouteWayPointAttribute?.poiName = wayPointName.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
                        wayPointName = ""
                    } else {
                        print("\(#function) cannot find wayPoint to initialize its name!")
                    }
                }
            } else if elementName == XSD.GPX.Elements.RTE.name {
                let newGPXRoute = GPXRoute()
                newGPXRoute.routeAttributes = routeAttributes
                newGPXRoute.routeWayPoints = routeWayPoints
                newGPXRoute.routeName = routeName.trimmingCharacters(in: CharacterSet(charactersIn: "\n "))
                
                importedRouteCounter += 1
                
                GPXRoutes.append(newGPXRoute)
                
                routeAttributes = nil
                routeWayPoints = nil
                routeName = ""
            }
            
        }
        
        if let range = elementHierarchy.range(of: ".", options: .backwards) {
            elementHierarchy = elementHierarchy.substring(to: range.lowerBound)
        } else {
            elementHierarchy = ""
        }

    }
    
    
    // Warning: foundCharacters can be called several times for the same element
    // As a consequence we need to concat the values with += and not a single assignment
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch isParsing {
        case .WPT_Desc:
            poiDescription += string
        case .WPT_Link:
            poiLink += string
        case .WPT_Name:
            poiName += string
        case .WPT_SYM:
            poiSym += string
        case .RTE_NAME:
            routeName += string
        case .RTE_WPT_Name:
            wayPointName += string
        default:
            break
        }
    }
    
}
