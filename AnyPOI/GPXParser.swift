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
        print("\(#function) line: \(parser.lineNumber) column: \(parser.columnNumber)")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("\(#function) creator: \(creator) has created : \(importedPOICounter)")
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        print("\(#function) foundCDATA")
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
    fileprivate var routeAttributes:[String : String]? = nil

    struct RouteWayPointAtttributes {
        fileprivate var routeWptAttributes:[String : String]? = nil
        fileprivate var wayPointAttributes:[String : String]? = nil
    }

    fileprivate var currentRouteWayPointAttribute:RouteWayPointAtttributes? = nil
    fileprivate var routeWayPoints:[RouteWayPointAtttributes]? = nil


    fileprivate enum ParsingElement {
        case WPT, WPT_Name, WPT_Link, WPT_Desc, WPT_SYM, WPT_POI, WPT_GROUP, WPT_REGION_MONITORING,
        RTE, RTE_NAME, RTE_ROUTE, RTE_WPT, RTE_WPT_WAYPOINT,
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
            switch elementName {
            case XSD.GPX.Elements.RTE.name:
                isParsing = .RTE
                routeWayPoints = [RouteWayPointAtttributes]()
            case XSD.GPX.Elements.RTE.Elements.name.name:
                isParsing = .RTE_NAME
            case XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.name:
                isParsing = .RTE_WPT
                currentRouteWayPointAttribute = RouteWayPointAtttributes()
                currentRouteWayPointAttribute!.routeWptAttributes = attributeDict
            case XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.name:
                isParsing = .RTE_WPT_WAYPOINT
                guard (currentRouteWayPointAttribute != nil) else {
                    print("Warning, found WayPoint element without WPT!")
                    return
                }
                currentRouteWayPointAttribute!.wayPointAttributes = attributeDict
                routeWayPoints?.append(currentRouteWayPointAttribute!)
           case XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.name:
                isParsing = .RTE_ROUTE
                routeAttributes = attributeDict
            default:
                break
            }
        }
        
    }
    
    fileprivate static let POI_PREFIX = "gpx.wpt"
    fileprivate static let ROUTE_PREFIX = "gpx.rte"
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        // Mandatory to check the hierarchy because WPT Element can be both outside route & inside route
        if elementName == XSD.GPX.Elements.WPT.name, elementHierarchy.hasPrefix(GPXParser.POI_PREFIX) {
            
            let newGPXPoi = GPXPoi()
            newGPXPoi.wptAttributes = wptAttributes
            newGPXPoi.poiAttributes = poiAttributes
            newGPXPoi.groupAttributes = groupAttributes
            newGPXPoi.regionMonitoringAttributes = regionMonitoringAttributes
            newGPXPoi.poiDescription = poiDescription
            newGPXPoi.poiLink = poiLink
            newGPXPoi.poiName = poiName
            newGPXPoi.poiSym = poiSym
            
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
 
        } else if elementName == XSD.GPX.Elements.RTE.name, elementHierarchy.hasPrefix(GPXParser.ROUTE_PREFIX) {
            let newGPXRoute = GPXRoute()
            newGPXRoute.routeAttributes = routeAttributes
            newGPXRoute.routeWayPoints = routeWayPoints
            newGPXRoute.routeName = routeName

            importedRouteCounter += 1

            GPXRoutes.append(newGPXRoute)

            routeAttributes = nil
            routeWayPoints = nil
            routeName = ""
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
        default:
            break
        }
    }
    
}
