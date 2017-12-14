//
//  XMLElement.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

// String extension to remove special characters when used in XML
extension String {
    func toXML() -> String {
        return replacingOccurrences(of: "&", with: "&amp;")
    }
    
    func fromXML() -> String {
        return replacingOccurrences(of: "&amp;", with: "&")
    }
}

struct XMLRoot {
    let attributes:[String:String]
    let xmlContent:XMLElement
    
    var toString:String {
        var xml = "<?xml"
        for (key, value) in attributes {
            xml += " \(key)=\"\(value)\""
        }
        xml += "?>"
        xml += xmlContent.toString()
        return xml
    }
}

struct XMLElement {
    let elementName:String
    let attributes:[String:String]
    
    var subElements = [XMLElement]()
    var value = ""
    
    init(elementName: String, attributes:[String:String]) {
        self.elementName = elementName
        
        // Make sure all values are initialized with a valid XML string
        self.attributes = attributes.mapValues() { $0.toXML() }
    }
    
    init(elementName: String) {
        self.elementName = elementName
        self.attributes = [String:String]()
    }
    
    init(elementName: String, withValue:String) {
        self.elementName = elementName
        self.attributes = [String:String]()
        self.value = withValue.toXML()
    }
    
    mutating func addSub(element:XMLElement) {
        subElements.append(element)
    }
    
    func toString(indentLevel:Int = 0) -> String {
        var xml = "\n"
        xml += String(repeating: " ", count: indentLevel)
        xml += "<\(elementName)"
        for (key, value) in attributes {
            xml += " \(key)=\"\(value)\""
        }
        xml += ">"
        
        if !value.isEmpty {
            xml += value
        }
        
        for currentSubElement in subElements {
            xml += currentSubElement.toString(indentLevel: indentLevel + 1)
        }
        xml += "\n"
        xml += String(repeating: " ", count: indentLevel)
        xml += "</\(elementName)>"
        return xml
 
    }
    
}
