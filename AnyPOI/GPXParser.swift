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
    
    fileprivate var currentPoi:PointOfInterest?
    fileprivate var isParsingWPT = false
    fileprivate var importedPOICounter = 0
    
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
                                                static let groupId = "groupId"
                                                static let isDisplayed = "isDisplayed"
                                                static let groupDescription = "description"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
               
            }
        }
    }
    
    
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
    
    fileprivate var wptAttributes:[String : String]? = nil
    fileprivate var poiAttributes:[String : String]? = nil
    fileprivate var groupAttributes:[String : String]? = nil
    fileprivate var regionMonitoringAttributes:[String : String]? = nil
    fileprivate var poiDescription = ""
    fileprivate var poiLink = ""
    fileprivate var poiName = ""
    fileprivate var poiSym = ""
    
    fileprivate enum ParsingElement {
        case WPT, WPT_Name, WPT_Link, WPT_Desc, WPT_SYM, WPT_POI, WPT_GROUP, WPT_REGION_MONITORING, OTHERS
    }
    
    fileprivate var isParsing = ParsingElement.OTHERS
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        isParsing = ParsingElement.OTHERS
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
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == XSD.GPX.Elements.WPT.name {
            
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
        default:
            break
        }
    }
    
}
