//
//  WayPointMailActivityItemSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit

class RouteMailActivityItemSource: NSObject, UIActivityItemSource {
    
    struct ExternalActivities {
        static let spark = "com.readdle.smartemail.share"
    }
    
    let routeDatasource:RouteDataSource
    
    init(datasource:RouteDataSource) {
        routeDatasource = datasource
    }
    
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return ""
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if routeDatasource.isFullRouteMode {
            if activityType == UIActivityType.mail  {
                return HTMLAnyPoi.appendCSSAndSignature(html: routeToHTML())
            } else if activityType.rawValue == HTMLAnyPoi.readdleSparkActivity  {
                return HTMLAnyPoi.appendCSSAndSignatureForReaddleSpark(html:routeToHTML())
            } else {
                return nil
            }
        } else {
            if let sourceWayPoint = routeDatasource.fromWayPoint, let targetWayPoint = routeDatasource.toWayPoint {
                if activityType == UIActivityType.mail  {
                    return HTMLAnyPoi.appendCSSAndSignature(html:routeStepToHTML(sourceWayPoint: sourceWayPoint, targetWayPoint: targetWayPoint))
                } else if activityType.rawValue == HTMLAnyPoi.readdleSparkActivity  {
                    return HTMLAnyPoi.appendCSSAndSignatureForReaddleSpark(html:routeStepToHTML(sourceWayPoint: sourceWayPoint, targetWayPoint: targetWayPoint))
                } else {
                    return nil
                }
            } else {
                return NSLocalizedString("Error", comment: "")
            }
        }
    }
    
    fileprivate func routeStepToHTML(sourceWayPoint:WayPoint, targetWayPoint:WayPoint) -> String {
        var HTMLString = "<b>\(sourceWayPoint.wayPointPoi!.poiDisplayName!) ➔ \(targetWayPoint.wayPointPoi!.poiDisplayName!)</b><br>"
        HTMLString += RouteMailActivityItemSource.tableHeaderForRoute
        HTMLString += getRowFor(fromWP: sourceWayPoint, toWP: targetWayPoint)
        HTMLString += "</table>"
        
        return HTMLString
    }
    
    fileprivate static let tableHeaderForRoute =
            "<table style=\"width:100%\">" +
            "<tr>" +
            "<th>\(NSLocalizedString("RouteTableHeaderFrom", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderTo", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderTransportType", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderDistance", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderDuration", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderFromDetails", comment: ""))</th>" +
            "<th>\(NSLocalizedString("RouteTableHeaderToDetails", comment: ""))</th>" +
            "</tr>"
    
    fileprivate func getRowFor(fromWP:WayPoint, toWP:WayPoint) -> String {
        var HTMLString = "<tr>"
        HTMLString += "<td>\(fromWP.wayPointPoi!.poiDisplayName!)</td>"
        HTMLString += "<td>\(toWP.wayPointPoi!.poiDisplayName!)</td>"
        HTMLString += "<td>\(fromWP.transportTypeFormattedEmoji)</td>"
        if let routeInfos = fromWP.routeInfos {
            HTMLString += "<td>\(routeInfos.distanceFormatted)</td>"
            HTMLString += "<td>\(routeInfos.expectedTravelTimeFormatted)</td>"
        } else {
            HTMLString += "<td>\(NSLocalizedString("Unknown", comment: ""))</td>"
            HTMLString += "<td>\(NSLocalizedString("Unknown", comment: ""))</td>"
            
        }
        HTMLString += "<td>\(fromWP.wayPointPoi!.toHTML())"
        HTMLString += "<td>\(toWP.wayPointPoi!.toHTML())"
        HTMLString += "</tr>"
        
        return HTMLString
    }
    
    fileprivate func routeToHTML() -> String {
        var HTMLString = ""
        if routeDatasource.wayPoints.count > 1 {
            let routeTitle = String(format:"\(NSLocalizedString("RouteFullNameWithDistanceAndTime %@ with %@", comment: ""))", routeDatasource.allRouteName, routeDatasource.theRoute.localizedDistanceAndTime)
            HTMLString += "<b>\(routeTitle)</b><br>"
            
            HTMLString += RouteMailActivityItemSource.tableHeaderForRoute
            
            for i in (0...routeDatasource.wayPoints.count - 2) {
                HTMLString += getRowFor(fromWP: routeDatasource.wayPoints[i], toWP: routeDatasource.wayPoints[i+1])
            }
            
            HTMLString += "</table>"
        } else {
            if routeDatasource.wayPoints.count == 1 {
                let noDestination = String(format:"RouteName %@ has not destination",routeDatasource.allRouteName)
                HTMLString += "<b>\(noDestination)</b><br>"
                if let fromWP = routeDatasource.fromWayPoint {
                    HTMLString += "\(fromWP.wayPointPoi!.toHTML())"
                }
            } else {
                let emptyRoute = String(format:"RouteName %@ is empty", routeDatasource.allRouteName)
                HTMLString += "<b>\(emptyRoute)</b>"
            }
        }
        return HTMLString
    }
    
}
