//
//  HTMLAnyPoi.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 18/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

class HTMLAnyPoi {
    struct ExternalActivities {
        static let spark = "com.readdle.smartemail.share"
    }

    static let readdleSparkActivity = "com.readdle.smartemail.share"
    
   private static let CSSstyle =
        "<head>" +
            "<style> " +
            "table, th, td" +
            "   {border: 1px solid black; border-collapse: collapse;}" +
            "th, td " +
            "   {padding: 5px;}" +
            "th " +
            "   {text-align: left;}" +
            "</style>" +
    "</head>"
    
    //FIXEDME: 😡⚡️😡 To be completed with AppStore URL
    private static let Signature = "<b>\(NSLocalizedString("MailGeneratedBy", comment: "")) <a href=\"http://http://sebbrugalieres.fr/ios/iMonitoring/Presentation.html\">AnyPoi</a></b>"

    static func appendCSSAndSignature(html:String) -> String {
        return "<html> \(HTMLAnyPoi.CSSstyle) \(html) \(HTMLAnyPoi.Signature)</html>"
    }
    // Spark\n\n
    static func appendCSSAndSignatureForReaddleSpark(html:String) -> String { 
        return "<html> \(HTMLAnyPoi.CSSstyle) \(html) \(HTMLAnyPoi.Signature)</html>"
    }
}
