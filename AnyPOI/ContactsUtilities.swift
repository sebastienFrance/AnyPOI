//
//  ContactsUtilities.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 15/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import CoreLocation
import PKHUD

class ContactsUtilities {
    
    static func getContactsWithAddress() -> [CNContact] {
        
        let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactPostalAddressesKey, CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName)]
        let store = CNContactStore()
        var contactsWithAddress = [CNContact]()
        do {
            try store.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: keysToFetch)) {
                (contact, cursor) -> Void in
                if contact.areKeysAvailable([CNContactPostalAddressesKey]) {
                    if contact.postalAddresses.count != 0 {
                        contactsWithAddress.append(contact)
                    }
                }
            }
        }
        catch{
            print("\(#function) Error when retrieving the contacts.")
        }
        return contactsWithAddress
    }
    
    static func getThumbailImageDataFor(contactIdentifier:String) -> NSData? {
        let keysToFectch = [CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
        let store = CNContactStore()
        do {
            let contact =  try store.unifiedContactWithIdentifier(contactIdentifier, keysToFetch: keysToFectch)
            if contact.imageDataAvailable {
                return contact.thumbnailImageData
            }
        }
        catch{
            print("\(#function) Error when retrieving thumbail image for the contacts: \(contactIdentifier).")
        }
        
        return nil
    }
    
    static func getContactForDetailedDescription(contactIdentifier:String) -> CNContact? {
        let keysToFectch = [CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey, CNContactPhoneNumbersKey, CNContactUrlAddressesKey, CNContactEmailAddressesKey]
        let store = CNContactStore()
        do {
            return try store.unifiedContactWithIdentifier(contactIdentifier, keysToFetch: keysToFectch)
        }
        catch{
            print("\(#function) Error when retrieving data for the contacts: \(contactIdentifier).")
        }
        
        return nil
    }
    
    static func getContactForCNContactViewController(contactIdentifier:String) -> CNContact? {
        let contactStore = CNContactStore()
        
        do {
            return try contactStore.unifiedContactWithIdentifier(contactIdentifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        }
        catch{
            print("\(#function) Error when retrieving data for the contacts: \(contactIdentifier).")
        }
        
        return nil

    }
    
    static func extractPhoneNumber(contact:CNContact) -> CNPhoneNumber? {
        if contact.phoneNumbers.count > 0 {
            var otherNumber:CNPhoneNumber?
            for currentLabeledValue in contact.phoneNumbers {
                
                switch currentLabeledValue.label {
                case CNLabelPhoneNumberMain:
                    return currentLabeledValue.value as? CNPhoneNumber
                case CNLabelPhoneNumberiPhone, CNLabelPhoneNumberMobile, CNLabelWork, CNLabelHome:
                    otherNumber = currentLabeledValue.value as? CNPhoneNumber
                default:
                    break
                }
            }
            
            if otherNumber == nil && contact.phoneNumbers.count > 0 {
                otherNumber = contact.phoneNumbers[0].value as? CNPhoneNumber
            }
            
            return otherNumber
        } else {
            return nil
        }
    }
    
    static func extractURL(contact:CNContact) -> String? {
        if contact.urlAddresses.count > 0 {
            return contact.urlAddresses[0].value as? String
        } else {
            return nil
        }
    }
}
