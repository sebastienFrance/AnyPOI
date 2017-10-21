//
//  WatchSessionMgr.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 21/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import WatchConnectivity

//class WatchSessionMgr {
//
//    static let sharedInstance = new WatchSessionMgr()
//
//    init() {
//        if WCSession.isSupported() {
//            let session = WCSession.default
//            session.delegate = self
//            session.activate()
//        }
//
//    }
//}
//
//extension WatchSessionMgr : WCSessionDelegate {
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        NSLog("\(#function)")
//        if let theError = error {
//            NSLog("\(#function) an error has oocured: \(theError.localizedDescription)")
//        } else {
//            NSLog("\(#function) activation is completed with : \(activationState)")
//        }
//    }
//
//    func sessionDidBecomeInactive(_ session: WCSession) {
//        NSLog("\(#function)")
//    }
//
//    func sessionDidDeactivate(_ session: WCSession) {
//        NSLog("\(#function)")
//    }
//
//    //var pendingReply:([String : Any]) -> Void
//
//
//    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
//        NSLog("\(#function) get a message")
//
//
//        if //let latitude = message[CommonProps.userLocation.latitude] as? CLLocationDegrees,
//            // let longitude = message[CommonProps.userLocation.longitude] as? CLLocationDegrees,
//            let maxRadius = message[CommonProps.maxRadius] as? Double,
//            let maxPOIResults = message[CommonProps.maxResults] as? Int {
//
//            if !LocationManager.sharedInstance.isLocationAuthorized() {
//                NSLog("\(#function) Cannot get user location")
//                replyHandler(["response" : "cannot get user location"])
//                return
//            }
//
//            if let centerLocation = LocationManager.sharedInstance.locationManager?.location {
//
//                //let centerLocation = CLLocation(latitude: latitude, longitude: longitude)
//
//                let pois = PoiBoundingBox.getPoiAroundCurrentLocation(centerLocation, radius: maxRadius, maxResult: maxPOIResults)
//
//                var poiArray = [[String:String]]()
//                for currentPoi in pois {
//                    var poiProps = currentPoi.props
//                    if poiProps != nil {
//                        let targetLocation = CLLocation(latitude: currentPoi.poiLatitude , longitude: currentPoi.poiLongitude)
//                        let distance = centerLocation.distance(from: targetLocation)
//
//                        poiProps![CommonProps.POI.distance] = String(distance)
//
//                        poiArray.append(poiProps!)
//
//
//                    }
//                }
//                var result = [String:Any]()
//                result[CommonProps.listOfPOIs] = poiArray
//                replyHandler(result)
//            } else {
//                NSLog("\(#function) Cannot get CLLocation")
//                replyHandler(["response" : "cannot get user location"])
//                return
//
//            }
//        } else {
//            replyHandler(["response" : "cannot extract coordinate"])
//        }
//
//    }
//
//    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
//        NSLog("\(#function) get a message")
//
//        if messageData.count == MemoryLayout<CLLocationCoordinate2D>.size {
//            let ptr = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity:1)
//            let buffer = UnsafeMutableBufferPointer<CLLocationCoordinate2D>.init(start: ptr, count: 1)
//            let _ = messageData.copyBytes(to: buffer)
//            if let coordinates = buffer.first {
//                NSLog("\(#function) message content is \(coordinates.latitude) \(coordinates.longitude)")
//            } else {
//                NSLog("\(#function) cannot extract coordinates from messageData ! ")
//            }
//            replyHandler(messageData)
//        } else {
//            NSLog("\(#function) message is not readable ! ")
//        }
//
//    }
//
//    //func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void)
//
//}
//
