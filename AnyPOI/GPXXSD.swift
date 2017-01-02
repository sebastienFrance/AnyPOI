//
//  GPXXSD.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 02/01/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation

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
    
    // WPT Attributes
    static let wptLatitudeAttr = XSD.GPX.Elements.WPT.Attributes.latitude
    static let wptLongitudeAttr = XSD.GPX.Elements.WPT.Attributes.longitude
    
    // POI Attributes
    static let poiCityAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.city
    static let poiISOCountryCodeAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.ISOCountryCode
    static let poiPhoneNumberAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.phoneNumber
    static let poiWikipediaIdAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.wikipediaId
    static let poiCategoryIdAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.categoryId
    static let poiGroupIdAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.groupId
    static let poiIsContactAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.isContact
    static let poiContactIdAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.contactId
    static let poiAddressAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.address
    static let poiInternalUrlAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.internalUrl
    
    // RegionMonitoring Attributes
    static let regionMonitoringNotifyEnterAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyEnter
    static let regionMonitoringNotifyExitAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyExit
    static let regionMonitoringRadiusAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.regionRadius
    
    // Group Attributes
    static let groupInternalUrlAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.internalUrlAttr
    static let groupGroupIdAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupId
    static let groupNameAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.name
    static let groupDescriptionAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupDescription
    static let groupIsDisplayedAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.isDisplayed
    static let groupColorAttr = XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupColor
    
    // Route Attributes
    static let routeTotalDistanceAttr = XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDistance
    static let routeTotalDurationAttr = XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.latestTotalDuration
    static let routeInternalUrlAttr = XSD.GPX.Elements.RTE.Elements.customExtension.Elements.route.Attributes.internalUrlAttr
    
    // WayPoint Attributes
    static let wayPointTransportTypeAttr = XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.transportType
    static let wayPointPoiInternalUrlAttr = XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.poiInternalUrl
    static let wayPointInternalUrlAttr = XSD.GPX.Elements.RTE.Elements.rtept.Elements.WPT.Elements.customExtension.Elements.wayPoint.Attributes.internalUrl

}

